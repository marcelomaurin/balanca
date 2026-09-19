// Configuração principal da aplicação
// Refatorado para TIniFile mantendo migração do formato legado main.cfg

unit setmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles;

const
  filename = 'main.cfg';

type
  { TSetMain }
  TSetMain = class(TObject)
  private
    ckdevice: Boolean;
    FPATH: string;
    FPosX: Integer;
    FPosY: Integer;
    FHide: Boolean;
    FEXEC: Boolean;
    FCOM: string;
    FBAUD: Integer;
    FDTBIT: Integer;
    FPARI: Integer;
    FSTBIT: Integer;
    FEmpresa: string;
    FLocalizacao: string;
    FTipo1: string;
    FTipo2: string;
    FTipo3: string;
    FContagem1: Integer;
    FContagem2: Integer;
    FContagem3: Integer;
    FPainel: string;
    FSplash: Boolean;
    FTipoImp: Integer;
    FModeloImp: Integer;
    FReconnectEnabled: Boolean;
    FResponseTimeoutMs: Integer;
    FReconnectInitialMs: Integer;
    FReconnectMaxMs: Integer;
    FHttpBind: string;
    FWebSocketBind: string;
    FApiKey: string;
    FAllowRemoteWithoutApiKey: Boolean;
    FCommandsEnabled: Boolean;

    procedure Default;
    function ConfigFileName: string;
    function IsIniFile(const AFileName: string): Boolean;
    procedure LoadLegacyFile(const AFileName: string);
    function LegacyValue(AList: TStrings; const AKey, ADefault: string): string;
    function LegacyInteger(AList: TStrings; const AKey: string; ADefault: Integer): Integer;
    function LegacyBoolean(AList: TStrings; const AKey: string; ADefault: Boolean): Boolean;

    procedure SetPOSX(Value: Integer);
    procedure SetPOSY(Value: Integer);
    procedure SetDevice(const Value: Boolean);
    procedure SetHide(Value: Boolean);
    procedure SetEXEC(Value: Boolean);
    procedure SetCOM(Value: string);
    procedure SetBAUD(Value: Integer);
    procedure SetDTBIT(Value: Integer);
    procedure SetPARI(Value: Integer);
    procedure SetSTBIT(Value: Integer);
    procedure SetEmpresa(Value: string);
    procedure SetLocalizacao(Value: string);
    procedure SetTipo1(Value: string);
    procedure SetTipo2(Value: string);
    procedure SetTipo3(Value: string);
    procedure SetContagem1(Value: Integer);
    procedure SetContagem2(Value: Integer);
    procedure SetContagem3(Value: Integer);
    procedure SetPainel(Value: string);
    procedure SetSplash(Value: Boolean);
    procedure SetTipoImp(Value: Integer);
    procedure SetModeloImp(Value: Integer);
  public
    constructor Create; overload;
    constructor Create(const AConfigDir: string); overload;
    destructor Destroy; override;

    procedure SalvaContexto;
    procedure CarregaContexto;

    property device: Boolean read ckdevice write SetDevice;
    property posx: Integer read FPosX write SetPOSX;
    property posy: Integer read FPosY write SetPOSY;
    property Hide: Boolean read FHide write SetHide;
    property EXEC: Boolean read FEXEC write SetEXEC;
    property COMPORT: string read FCOM write SetCOM;
    property BAUDRATE: Integer read FBAUD write SetBAUD;
    property DATABIT: Integer read FDTBIT write SetDTBIT;
    property PARIDADE: Integer read FPARI write SetPARI;
    property STOPBIT: Integer read FSTBIT write SetSTBIT;
    property Empresa: string read FEmpresa write SetEmpresa;
    property Localizacao: string read FLocalizacao write SetLocalizacao;
    property Tipo1: string read FTipo1 write SetTipo1;
    property Tipo2: string read FTipo2 write SetTipo2;
    property Tipo3: string read FTipo3 write SetTipo3;
    property Contagem1: Integer read FContagem1 write SetContagem1;
    property Contagem2: Integer read FContagem2 write SetContagem2;
    property Contagem3: Integer read FContagem3 write SetContagem3;
    property Painel: string read FPainel write SetPainel;
    property Splash: Boolean read FSplash write SetSplash;
    property TipoImp: Integer read FTipoImp write SetTipoImp;
    property ModeloImp: Integer read FModeloImp write SetModeloImp;
    property ReconnectEnabled: Boolean read FReconnectEnabled write FReconnectEnabled;
    property ResponseTimeoutMs: Integer read FResponseTimeoutMs write FResponseTimeoutMs;
    property ReconnectInitialMs: Integer read FReconnectInitialMs write FReconnectInitialMs;
    property ReconnectMaxMs: Integer read FReconnectMaxMs write FReconnectMaxMs;
    property HttpBind: string read FHttpBind write FHttpBind;
    property WebSocketBind: string read FWebSocketBind write FWebSocketBind;
    property ApiKey: string read FApiKey write FApiKey;
    property AllowRemoteWithoutApiKey: Boolean read FAllowRemoteWithoutApiKey
      write FAllowRemoteWithoutApiKey;
    property CommandsEnabled: Boolean read FCommandsEnabled write FCommandsEnabled;
    property Path: string read FPATH;
  end;

var
  FSETMAIN: TSetMain;

implementation

procedure TSetMain.SetPOSX(Value: Integer); begin FPosX := Value; end;
procedure TSetMain.SetPOSY(Value: Integer); begin FPosY := Value; end;
procedure TSetMain.SetDevice(const Value: Boolean); begin ckdevice := Value; end;
procedure TSetMain.SetHide(Value: Boolean); begin FHide := Value; end;
procedure TSetMain.SetEXEC(Value: Boolean); begin FEXEC := Value; end;
procedure TSetMain.SetCOM(Value: string); begin FCOM := Value; end;
procedure TSetMain.SetBAUD(Value: Integer); begin FBAUD := Value; end;
procedure TSetMain.SetDTBIT(Value: Integer); begin FDTBIT := Value; end;
procedure TSetMain.SetPARI(Value: Integer); begin FPARI := Value; end;
procedure TSetMain.SetSTBIT(Value: Integer); begin FSTBIT := Value; end;
procedure TSetMain.SetEmpresa(Value: string); begin FEmpresa := Value; end;
procedure TSetMain.SetLocalizacao(Value: string); begin FLocalizacao := Value; end;
procedure TSetMain.SetTipo1(Value: string); begin FTipo1 := Value; end;
procedure TSetMain.SetTipo2(Value: string); begin FTipo2 := Value; end;
procedure TSetMain.SetTipo3(Value: string); begin FTipo3 := Value; end;
procedure TSetMain.SetContagem1(Value: Integer); begin FContagem1 := Value; end;
procedure TSetMain.SetContagem2(Value: Integer); begin FContagem2 := Value; end;
procedure TSetMain.SetContagem3(Value: Integer); begin FContagem3 := Value; end;
procedure TSetMain.SetPainel(Value: string); begin FPainel := Value; end;
procedure TSetMain.SetSplash(Value: Boolean); begin FSplash := Value; end;
procedure TSetMain.SetTipoImp(Value: Integer); begin FTipoImp := Value; end;
procedure TSetMain.SetModeloImp(Value: Integer); begin FModeloImp := Value; end;

procedure TSetMain.Default;
begin
  ckdevice := False;
  FPosX := 0;
  FPosY := 0;
  FEXEC := False;
  FHide := False;
  FSplash := False;

  {$IFDEF LINUX}
  FCOM := '/dev/ttyS0';
  {$ELSE}
  FCOM := 'COM13';
  {$ENDIF}

  FBAUD := 3;  // 2400
  FDTBIT := 0; // 8 bits
  FPARI := 0;  // sem paridade
  FSTBIT := 0; // 1 stop bit

  FEmpresa := 'maurinsoft';
  FLocalizacao := 'nothing';
  FTipo1 := 'Normal';
  FTipo2 := 'Idoso';
  FTipo3 := 'Especial';
  FContagem1 := 0;
  FContagem2 := 0;
  FContagem3 := 0;
  FPainel := '192.168.0.108';
  FTipoImp := 0;
  FModeloImp := 0;

  FReconnectEnabled := True;
  FResponseTimeoutMs := 3000;
  FReconnectInitialMs := 1000;
  FReconnectMaxMs := 30000;

  FHttpBind := '127.0.0.1';
  FWebSocketBind := '127.0.0.1';
  FApiKey := '';
  FAllowRemoteWithoutApiKey := False;
  FCommandsEnabled := True;
end;

function TSetMain.ConfigFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(FPATH) + filename;
end;

function TSetMain.IsIniFile(const AFileName: string): Boolean;
var
  L: TStringList;
  S: string;
  I: Integer;
begin
  Result := False;
  if not FileExists(AFileName) then
    Exit;

  L := TStringList.Create;
  try
    L.LoadFromFile(AFileName);
    for I := 0 to L.Count - 1 do
    begin
      S := Trim(L[I]);
      if S = '' then
        Continue;
      Result := (Length(S) >= 2) and (S[1] = '[') and (S[Length(S)] = ']');
      Exit;
    end;
  finally
    L.Free;
  end;
end;

function TSetMain.LegacyValue(AList: TStrings; const AKey, ADefault: string): string;
var
  I, P: Integer;
  S, K: string;
begin
  Result := ADefault;
  K := UpperCase(AKey);

  for I := 0 to AList.Count - 1 do
  begin
    S := AList[I];
    P := Pos(':', S);
    if P <= 0 then
      Continue;

    if UpperCase(Trim(Copy(S, 1, P - 1))) = K then
    begin
      Result := Trim(Copy(S, P + 1, MaxInt));
      Exit;
    end;
  end;
end;

function TSetMain.LegacyInteger(AList: TStrings; const AKey: string;
  ADefault: Integer): Integer;
var
  S: string;
begin
  S := LegacyValue(AList, AKey, IntToStr(ADefault));
  if not TryStrToInt(S, Result) then
    Result := ADefault;
end;

function TSetMain.LegacyBoolean(AList: TStrings; const AKey: string;
  ADefault: Boolean): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(LegacyValue(AList, AKey, BoolToStr(ADefault, True))));
  if (S = '1') or (S = 'true') or (S = 'yes') or (S = 'sim') then
    Exit(True);
  if (S = '0') or (S = 'false') or (S = 'no') or (S = 'nao') or (S = 'não') then
    Exit(False);
  Result := ADefault;
end;

procedure TSetMain.LoadLegacyFile(const AFileName: string);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.LoadFromFile(AFileName);

    ckdevice := LegacyBoolean(L, 'DEVICE', ckdevice);
    FPosX := LegacyInteger(L, 'POSX', FPosX);
    FPosY := LegacyInteger(L, 'POSY', FPosY);
    FHide := LegacyBoolean(L, 'HIDE', FHide);
    FEXEC := LegacyBoolean(L, 'EXEC', FEXEC);

    FCOM := LegacyValue(L, 'COMPORT', FCOM);
    FBAUD := LegacyInteger(L, 'BAUDRATE', FBAUD);
    FDTBIT := LegacyInteger(L, 'DATABIT', FDTBIT);
    FPARI := LegacyInteger(L, 'PARIDADE', FPARI);
    FSTBIT := LegacyInteger(L, 'STOPBIT', FSTBIT);

    FEmpresa := LegacyValue(L, 'EMPRESA', FEmpresa);
    FLocalizacao := LegacyValue(L, 'LOCALIZACAO', FLocalizacao);
    FTipo1 := LegacyValue(L, 'TIPO1', FTipo1);
    FTipo2 := LegacyValue(L, 'TIPO2', FTipo2);
    FTipo3 := LegacyValue(L, 'TIPO3', FTipo3);
    FContagem1 := LegacyInteger(L, 'CONTAGEM1', FContagem1);
    FContagem2 := LegacyInteger(L, 'CONTAGEM2', FContagem2);
    FContagem3 := LegacyInteger(L, 'CONTAGEM3', FContagem3);
    FPainel := LegacyValue(L, 'PAINEL', FPainel);
    FSplash := LegacyBoolean(L, 'SPLASH', FSplash);
    FTipoImp := LegacyInteger(L, 'TIPOIMP', FTipoImp);
    FModeloImp := LegacyInteger(L, 'MODELOIMP', FModeloImp);
  finally
    L.Free;
  end;
end;

procedure TSetMain.CarregaContexto;
var
  Ini: TIniFile;
  ConfigName: string;
begin
  Default;
  ConfigName := ConfigFileName;

  if not FileExists(ConfigName) then
    Exit;

  if not IsIniFile(ConfigName) then
  begin
    LoadLegacyFile(ConfigName);
    // Migra automaticamente para INI após carregar com sucesso.
    SalvaContexto;
    Exit;
  end;

  Ini := TIniFile.Create(ConfigName);
  try
    ckdevice := Ini.ReadBool('geral', 'device', ckdevice);
    FPosX := Ini.ReadInteger('janela', 'posx', FPosX);
    FPosY := Ini.ReadInteger('janela', 'posy', FPosY);
    FHide := Ini.ReadBool('geral', 'hide', FHide);
    FEXEC := Ini.ReadBool('geral', 'exec', FEXEC);
    FSplash := Ini.ReadBool('geral', 'splash', FSplash);

    FCOM := Ini.ReadString('serial', 'comport', FCOM);
    FBAUD := Ini.ReadInteger('serial', 'baudrate', FBAUD);
    FDTBIT := Ini.ReadInteger('serial', 'databit', FDTBIT);
    FPARI := Ini.ReadInteger('serial', 'paridade', FPARI);
    FSTBIT := Ini.ReadInteger('serial', 'stopbit', FSTBIT);

    FReconnectEnabled := Ini.ReadBool('reconnect', 'enabled', FReconnectEnabled);
    FResponseTimeoutMs := Ini.ReadInteger('reconnect', 'response_timeout_ms', FResponseTimeoutMs);
    FReconnectInitialMs := Ini.ReadInteger('reconnect', 'initial_delay_ms', FReconnectInitialMs);
    FReconnectMaxMs := Ini.ReadInteger('reconnect', 'max_delay_ms', FReconnectMaxMs);

    if FResponseTimeoutMs < 500 then
      FResponseTimeoutMs := 500;
    if FReconnectInitialMs < 100 then
      FReconnectInitialMs := 100;
    if FReconnectMaxMs < FReconnectInitialMs then
      FReconnectMaxMs := FReconnectInitialMs;

    FHttpBind := Trim(Ini.ReadString('security', 'http_bind', FHttpBind));
    FWebSocketBind := Trim(Ini.ReadString('security', 'websocket_bind', FWebSocketBind));
    FApiKey := Trim(Ini.ReadString('security', 'api_key', FApiKey));
    FAllowRemoteWithoutApiKey := Ini.ReadBool('security',
      'allow_remote_without_api_key', FAllowRemoteWithoutApiKey);
    FCommandsEnabled := Ini.ReadBool('security', 'commands_enabled', FCommandsEnabled);

    if FHttpBind = '' then
      FHttpBind := '127.0.0.1';
    if FWebSocketBind = '' then
      FWebSocketBind := '127.0.0.1';

    FEmpresa := Ini.ReadString('legado', 'empresa', FEmpresa);
    FLocalizacao := Ini.ReadString('legado', 'localizacao', FLocalizacao);
    FTipo1 := Ini.ReadString('legado', 'tipo1', FTipo1);
    FTipo2 := Ini.ReadString('legado', 'tipo2', FTipo2);
    FTipo3 := Ini.ReadString('legado', 'tipo3', FTipo3);
    FContagem1 := Ini.ReadInteger('legado', 'contagem1', FContagem1);
    FContagem2 := Ini.ReadInteger('legado', 'contagem2', FContagem2);
    FContagem3 := Ini.ReadInteger('legado', 'contagem3', FContagem3);
    FPainel := Ini.ReadString('legado', 'painel', FPainel);
    FTipoImp := Ini.ReadInteger('legado', 'tipoimp', FTipoImp);
    FModeloImp := Ini.ReadInteger('legado', 'modeloimp', FModeloImp);
  finally
    Ini.Free;
  end;
end;

constructor TSetMain.Create;
begin
  inherited Create;

  FPATH := IncludeTrailingPathDelimiter(GetAppConfigDir(False));
  if not DirectoryExists(FPATH) then
    ForceDirectories(FPATH);

  CarregaContexto;
end;

constructor TSetMain.Create(const AConfigDir: string);
begin
  inherited Create;

  FPATH := IncludeTrailingPathDelimiter(AConfigDir);
  if not DirectoryExists(FPATH) then
    ForceDirectories(FPATH);

  CarregaContexto;
end;

procedure TSetMain.SalvaContexto;
var
  Ini: TIniFile;
begin
  if not DirectoryExists(FPATH) then
    ForceDirectories(FPATH);

  Ini := TIniFile.Create(ConfigFileName);
  try
    Ini.WriteBool('geral', 'device', ckdevice);
    Ini.WriteBool('geral', 'hide', FHide);
    Ini.WriteBool('geral', 'exec', FEXEC);
    Ini.WriteBool('geral', 'splash', FSplash);

    Ini.WriteInteger('janela', 'posx', FPosX);
    Ini.WriteInteger('janela', 'posy', FPosY);

    Ini.WriteString('serial', 'comport', FCOM);
    Ini.WriteInteger('serial', 'baudrate', FBAUD);
    Ini.WriteInteger('serial', 'databit', FDTBIT);
    Ini.WriteInteger('serial', 'paridade', FPARI);
    Ini.WriteInteger('serial', 'stopbit', FSTBIT);

    Ini.WriteBool('reconnect', 'enabled', FReconnectEnabled);
    Ini.WriteInteger('reconnect', 'response_timeout_ms', FResponseTimeoutMs);
    Ini.WriteInteger('reconnect', 'initial_delay_ms', FReconnectInitialMs);
    Ini.WriteInteger('reconnect', 'max_delay_ms', FReconnectMaxMs);

    Ini.WriteString('security', 'http_bind', FHttpBind);
    Ini.WriteString('security', 'websocket_bind', FWebSocketBind);
    Ini.WriteString('security', 'api_key', FApiKey);
    Ini.WriteBool('security', 'allow_remote_without_api_key',
      FAllowRemoteWithoutApiKey);
    Ini.WriteBool('security', 'commands_enabled', FCommandsEnabled);

    // Campos mantidos por compatibilidade enquanto não forem removidos
    // definitivamente da aplicação.
    Ini.WriteString('legado', 'empresa', FEmpresa);
    Ini.WriteString('legado', 'localizacao', FLocalizacao);
    Ini.WriteString('legado', 'tipo1', FTipo1);
    Ini.WriteString('legado', 'tipo2', FTipo2);
    Ini.WriteString('legado', 'tipo3', FTipo3);
    Ini.WriteInteger('legado', 'contagem1', FContagem1);
    Ini.WriteInteger('legado', 'contagem2', FContagem2);
    Ini.WriteInteger('legado', 'contagem3', FContagem3);
    Ini.WriteString('legado', 'painel', FPainel);
    Ini.WriteInteger('legado', 'tipoimp', FTipoImp);
    Ini.WriteInteger('legado', 'modeloimp', FModeloImp);

    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

destructor TSetMain.Destroy;
begin
  // A aplicação salva explicitamente ao encerrar; não grava novamente aqui.
  inherited Destroy;
end;

end.
