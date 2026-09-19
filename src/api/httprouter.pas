unit httprouter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, IdCustomHTTPServer, scaleapplication, scalecommands, scaledevice;

type
  { TScaleHttpRouter }
  TScaleHttpRouter = class
  private
    FApp: TScaleApplication;
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

procedure TScaleHttpRouter.HandleGet(ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  Path: string;
  LegacyHtml: string;
begin
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
    AResponseInfo.ContentText := FApp.Api.StatusJson;
  end
  else if SameText(Path, '/api/v1/config') then
  begin
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.Api.ConfigJson;
  end
  else if SameText(Path, '/') or SameText(Path, '/legacy') then
  begin
    LegacyHtml :=
      '<html>' + LineEnding +
      '<head>' + LineEnding +
      '<title>Meu SRV</title>' + LineEnding +
      '</head>' + LineEnding +
      '<body>' + LineEnding +
      FApp.Api.LegacyJson + LineEnding +
      '</body>' + LineEnding +
      '</html>' + LineEnding;

    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentType := 'text/html; charset=utf-8';
    AResponseInfo.ContentText := LegacyHtml;
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
  Path := ARequestInfo.Document;

  if Pos('/api/v1/commands/', LowerCase(Path)) <> 1 then
  begin
    AResponseInfo.ResponseNo := 404;
    AResponseInfo.ContentType := 'application/json; charset=utf-8';
    AResponseInfo.ContentText := FApp.Api.NotFoundJson(Path);
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
