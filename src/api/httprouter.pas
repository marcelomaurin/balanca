unit httprouter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, IdCustomHTTPServer, scaleapplication, scalecommands, scaledevice,
  scalejson, legacyapi;

type
  { TScaleHttpRouter }
  TScaleHttpRouter = class
  private
    FApp: TScaleApplication;
    function IsLoopbackBind(const ABind: string): Boolean;
    function ConstantTimeEquals(const A, B: string): Boolean;
    function RequestApiKey(ARequestInfo: TIdHTTPRequestInfo): string;
    function Authorize(ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo): Boolean;
    function ErrorJson(const ACode, AMessage: string): string;
  public
    constructor Create(AApp: TScaleApplication);

    procedure HandleGet(ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);

    procedure HandleOther(ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
  end;

implementation

constructor TScaleHttpRouter.Create(AApp: TScaleApplication);
begin
  inherited Create;

  if not Assigned(AApp) then
    raise Exception.Create('Aplicação da balança não informada');

  FApp := AApp;
end;

function TScaleHttpRouter.IsLoopbackBind(const ABind: string): Boolean;
var
  V: string;
begin
  V := LowerCase(Trim(ABind));
  Result :=
    (V = '127.0.0.1') or
    (V = 'localhost') or
    (V = '::1');
end;

function TScaleHttpRouter.ConstantTimeEquals(const A, B: string): Boolean;
var
  I, Diff: Integer;
begin
  if Length(A) <> Length(B) then
    Exit(False);

  Diff := 0;
  for I := 1 to Length(A) do
    Diff := Diff or (Ord(A[I]) xor Ord(B[I]));

  Result := Diff = 0;
end;

function TScaleHttpRouter.RequestApiKey(
  ARequestInfo: TIdHTTPRequestInfo): string;
var
  Auth: string;
begin
  Result := Trim(ARequestInfo.RawHeaders.Values['X-API-Key']);
  if Result <> '' then
    Exit;

  Auth := Trim(ARequestInfo.RawHeaders.Values['Authorization']);
  if Pos('BEARER ', UpperCase(Auth)) = 1 then
  begin
    Result := Trim(Copy(Auth, 8, MaxInt));
    if Result <> '' then
      Exit;
  end;

  Result := Trim(ARequestInfo.Params.Values['api_key']);
end;

function TScaleHttpRouter.ErrorJson(const ACode, AMessage: string): string;
begin
  Result :=
    '{' +
      '"error":' + JsonString(ACode) + ',' +
      '"message":' + JsonString(AMessage) +
    '}';
end;

function TScaleHttpRouter.Authorize(ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo): Boolean;
var
  Expected, Provided: string;
begin
  Result := False;
  Expected := Trim(FApp.Settings.ApiKey);

  if (not IsLoopbackBind(FApp.Settings.HttpBind)) and
     (Expected = '') and
     (not FApp.Settings.AllowRemoteWithoutApiKey) then
  begin
    AResponseInfo.ResponseNo := 503;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    FApp.Metrics.IncHttpUnauthorized;
    FApp.Logger.Warn('http', 'Acesso remoto bloqueado por configuração insegura');
    AResponseInfo.ContentText := ErrorJson(
      'security_configuration_required',
      'Acesso remoto exige api_key ou liberação explícita'
    );
    Exit;
  end;

  if Expected = '' then
    Exit(True);

  Provided := RequestApiKey(ARequestInfo);
  if ConstantTimeEquals(Expected, Provided) then
    Exit(True);

  FApp.Metrics.IncHttpUnauthorized;
  FApp.Logger.Warn('http', 'API key inválida ou ausente');
  AResponseInfo.ResponseNo := 401;
  AResponseInfo.ContentType := 'application/json; charset=utf-8';
  AResponseInfo.CustomHeaders.Values['WWW-Authenticate'] := 'ApiKey';
  AResponseInfo.ContentText := ErrorJson('unauthorized', 'API key inválida ou ausente');
end;

procedure TScaleHttpRouter.HandleGet(ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  Path: string;
begin
  FApp.Metrics.IncHttpRequests;
  FApp.Logger.Debug('http', ARequestInfo.Command + ' ' + ARequestInfo.Document);

  if not Authorize(ARequestInfo, AResponseInfo) then
    Exit;

  Path := ARequestInfo.Document;

  if SameText(Path, '/api/v1/weight') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.Api.WeightJson;
  end
  else if SameText(Path, '/api/v1/status') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.StatusJson;
  end
  else if SameText(Path, '/api/v1/config') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.Api.ConfigJson;
  end
  else if SameText(Path, '/api/v1/metrics') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.Metrics.ToJson;
  end
  else if SameText(Path, '/') or SameText(Path, '/legacy') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'text/html; charset=utf-8';
    AResponseInfo.ContentText :=
      BuildLegacyHtmlResponse(FApp.Snapshot.LastWeight);
  end
  else
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.Api.NotFoundJson(Path);
  end;
end;

procedure TScaleHttpRouter.HandleOther(ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  Path: string;
  CommandName: string;
  Command: TScaleCommand;
  Snapshot: TScaleSnapshot;
begin
  FApp.Metrics.IncHttpRequests;
  FApp.Logger.Debug('http', ARequestInfo.Command + ' ' + ARequestInfo.Document);

  if not Authorize(ARequestInfo, AResponseInfo) then
    Exit;

  Path := ARequestInfo.Document;

  if Pos('/api/v1/commands/', LowerCase(Path)) <> 1 then
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.Api.NotFoundJson(Path);
    Exit;
  end;

  if not FApp.Settings.CommandsEnabled then
  begin
    FApp.Logger.Warn('http', 'Comandos remotos desabilitados');
    AResponseInfo.ResponseNo := 403;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := ErrorJson('commands_disabled',
      'Comandos remotos estão desabilitados');
    Exit;
  end;

  if not SameText(ARequestInfo.Command, 'POST') then
  begin
    AResponseInfo.ResponseNo := 405;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText :=
      FApp.Api.CommandResultJson('', False, 'method_not_allowed');
    Exit;
  end;

  CommandName := Copy(Path, Length('/api/v1/commands/') + 1, MaxInt);

  if not TryParseScaleCommand(CommandName, Command) then
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText :=
      FApp.Api.CommandResultJson(CommandName, False, 'unknown_command');
    Exit;
  end;

  if not FApp.SupportsCommand(Command) then
  begin
    AResponseInfo.ResponseNo := 501;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText :=
      FApp.Api.CommandResultJson(CommandName, False,
        'command_not_supported_by_current_protocol');
    Exit;
  end;

  Snapshot := FApp.Snapshot;
  if not Snapshot.Connected then
  begin
    AResponseInfo.ResponseNo := 409;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText :=
      FApp.Api.CommandResultJson(CommandName, False, 'scale_not_connected');
    Exit;
  end;

  if FApp.QueueCommand(Command) then
  begin
    FApp.Logger.Info('http', 'Comando aceito: ' + CommandName);
    AResponseInfo.ResponseNo := 202;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText :=
      FApp.Api.CommandResultJson(CommandName, True, 'queued');
  end
  else
  begin
    AResponseInfo.ResponseNo := 409;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText :=
      FApp.Api.CommandResultJson(CommandName, False, 'command_not_queued');
  end;
end;

end.
