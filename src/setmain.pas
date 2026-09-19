// Configuração principal da aplicação
// Refatorado para TIniFile mantendo migração do formato legado main.cfg

unit setmain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, legacyconfig, legacysettings;

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
    FProtocolId: string;
    FSplash: Boolean;
    FReconnectEnabled: Boolean;
    FResponseTimeoutMs: Integer;
    FReconnectInitialMs: Integer;
    FReconnectMaxMs: Integer;
    FHttpBind: string;
    FWebSocketBind: string;
    FApiKey: string;
    FAllowRemoteWithoutApiKey: Boolean;
    FCommandsEnabled: Boolean;
    FLogLevel: string;
    FLogFile: string;
    FLogConsole: Boolean;
    FLegacyHttpEnabled: Boolean;
    FLegacyConfigMigration: Boolean;
    FLegacy: TLegacySettings;

    procedure Default;
    function ConfigFileName: string;
    procedure LoadLegacyFile(const AFileName: string);

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
    function GetEmpresa: string;
    function GetLocalizacao: string;
    function GetTipo1: string;
    function GetTipo2: string;
    function GetTipo3: string;
    function GetContagem1: Integer;
    function GetContagem2: Integer;
    function GetContagem3: Integer;
    function GetPainel: string;
    function GetTipoImp: Integer;
    function GetModeloImp: Integer;
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
    property ProtocolId: string read FProtocolId write FProtocolId;
    property Empresa: string read GetEmpresa write SetEmpresa;
    property Localizacao: string read GetLocalizacao write SetLocalizacao;
    property Tipo1: string read GetTipo1 write SetTipo1;
    property Tipo2: string read GetTipo2 write SetTipo2;
    property Tipo3: string read GetTipo3 write SetTipo3;
    property Contagem1: Integer read GetContagem1 write SetContagem1;
    property Contagem2: Integer read GetContagem2 write SetContagem2;
    property Contagem3: Integer read GetContagem3 write SetContagem3;
    property Painel: string read GetPainel write SetPainel;
    property Splash: Boolean read FSplash write SetSplash;
    property TipoImp: Integer read GetTipoImp write SetTipoImp;
    property ModeloImp: Integer read GetModeloImp write SetModeloImp;
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
    property LogLevel: string read FLogLevel write FLogLevel;
    property LogFile: string read FLogFile write FLogFile;
    property LogConsole: Boolean read FLogConsole write FLogConsole;
    property LegacyHttpEnabled: Boolean read FLegacyHttpEnabled write FLegacyHttpEnabled;
    property LegacyConfigMigration: Boolean read FLegacyConfigMigration
      write FLegacyConfigMigration;
    property Legacy: TLegacySettings read FLegacy;
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
procedure TSetMain.SetEmpresa(Value: string); begin FLegacy.Empresa := Value; end;
procedure TSetMain.SetLocalizacao(Value: string); begin FLegacy.Localizacao := Value; end;
procedure TSetMain.SetTipo1(Value: string); begin FLegacy.Tipo1 := Value; end;
procedure TSetMain.SetTipo2(Value: string); begin FLegacy.Tipo2 := Value; end;
procedure TSetMain.SetTipo3(Value: string); begin FLegacy.Tipo3 := Value; end;
procedure TSetMain.SetContagem1(Value: Integer); begin FLegacy.Contagem1 := Value; end;
procedure TSetMain.SetContagem2(Value: Integer); begin FLegacy.Contagem2 := Value; end;
procedure TSetMain.SetContagem3(Value: Integer); begin FLegacy.Contagem3 := Value; end;
procedure TSetMain.SetPainel(Value: string); begin FLegacy.Painel := Value; end;
procedure TSetMain.SetSplash(Value: Boolean); begin FSplash := Value; end;
procedure TSetMain.SetTipoImp(Value: Integer); begin FLegacy.TipoImp := Value; end;
procedure TSetMain.SetModeloImp(Value: Integer); begin FLegacy.ModeloImp := Value; end;

function TSetMain.GetEmpresa: string; begin Result := FLegacy.Empresa; end;
function TSetMain.GetLocalizacao: string; begin Result := FLegacy.Localizacao; end;
function TSetMain.GetTipo1: string; begin Result := FLegacy.Tipo1; end;
function TSetMain.GetTipo2: string; begin Result := FLegacy.Tipo2; end;
function TSetMain.GetTipo3: string; begin Result := FLegacy.Tipo3; end;
function TSetMain.GetContagem1: Integer; begin Result := FLegacy.Contagem1; end;
function TSetMain.GetContagem2: Integer; begin Result := FLegacy.Contagem2; end;
function TSetMain.GetContagem3: Integer; begin Result := FLegacy.Contagem3; end;
function TSetMain.GetPainel: string; begin Result := FLegacy.Painel; end;
function TSetMain.GetTipoImp: Integer; begin Result := FLegacy.TipoImp; end;
function TSetMain.GetModeloImp: Integer; begin Result := FLegacy.ModeloImp; end;

procedure TSetMain.Default;
begin
  FLegacy.ResetDefaults;
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
  FProtocolId := 'toledo';


  FReconnectEnabled := True;
  FResponseTimeoutMs := 3000;
  FReconnectInitialMs := 1000;
  FReconnectMaxMs := 30000;

  FHttpBind := '127.0.0.1';
  FWebSocketBind := '127.0.0.1';
  FApiKey := '';
  FAllowRemoteWithoutApiKey := False;
  FCommandsEnabled := True;

  FLogLevel := 'info';
  FLogFile := IncludeTrailingPathDelimiter(FPATH) + 'balanca.log';
  FLogConsole := False;

  FLegacyHttpEnabled := True;
  FLegacyConfigMigration := True;
end;

function TSetMain.ConfigFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(FPATH) + filename;
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

    FLegacy.Empresa := LegacyValue(L, 'EMPRESA', FLegacy.Empresa);
    FLegacy.Localizacao := LegacyValue(L, 'LOCALIZACAO', FLegacy.Localizacao);
    FLegacy.Tipo1 := LegacyValue(L, 'TIPO1', FLegacy.Tipo1);
    FLegacy.Tipo2 := LegacyValue(L, 'TIPO2', FLegacy.Tipo2);
    FLegacy.Tipo3 := LegacyValue(L, 'TIPO3', FLegacy.Tipo3);
    FLegacy.Contagem1 := LegacyInteger(L, 'CONTAGEM1', FLegacy.Contagem1);
    FLegacy.Contagem2 := LegacyInteger(L, 'CONTAGEM2', FLegacy.Contagem2);
    FLegacy.Contagem3 := LegacyInteger(L, 'CONTAGEM3', FLegacy.Contagem3);
    FLegacy.Painel := LegacyValue(L, 'PAINEL', FLegacy.Painel);
    FSplash := LegacyBoolean(L, 'SPLASH', FSplash);
    FLegacy.TipoImp := LegacyInteger(L, 'TIPOIMP', FLegacy.TipoImp);
    FLegacy.ModeloImp := LegacyInteger(L, 'MODELOIMP', FLegacy.ModeloImp);
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

  if IsLegacyConfigFile(ConfigName) then
  begin
    LoadLegacyFile(ConfigName);
    if FLegacyConfigMigration then
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
    FProtocolId := LowerCase(Trim(Ini.ReadString('scale', 'protocol', FProtocolId)));
    if FProtocolId = '' then
      FProtocolId := 'toledo';

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

    FLogLevel := LowerCase(Trim(Ini.ReadString('logging', 'level', FLogLevel)));
    FLogFile := Trim(Ini.ReadString('logging', 'file', FLogFile));
    FLogConsole := Ini.ReadBool('logging', 'console', FLogConsole);
    if FLogLevel = '' then
      FLogLevel := 'info';
    if FLogFile = '' then
      FLogFile := IncludeTrailingPathDelimiter(FPATH) + 'balanca.log';

    FLegacyHttpEnabled := Ini.ReadBool('compatibility',
      'legacy_http_enabled', FLegacyHttpEnabled);
    FLegacyConfigMigration := Ini.ReadBool('compatibility',
      'legacy_config_migration', FLegacyConfigMigration);

    if FHttpBind = '' then
      FHttpBind := '127.0.0.1';
    if FWebSocketBind = '' then
      FWebSocketBind := '127.0.0.1';

    FLegacy.Empresa := Ini.ReadString('legado', 'empresa', FLegacy.Empresa);
    FLegacy.Localizacao := Ini.ReadString('legado', 'localizacao', FLegacy.Localizacao);
    FLegacy.Tipo1 := Ini.ReadString('legado', 'tipo1', FLegacy.Tipo1);
    FLegacy.Tipo2 := Ini.ReadString('legado', 'tipo2', FLegacy.Tipo2);
    FLegacy.Tipo3 := Ini.ReadString('legado', 'tipo3', FLegacy.Tipo3);
    FLegacy.Contagem1 := Ini.ReadInteger('legado', 'contagem1', FLegacy.Contagem1);
    FLegacy.Contagem2 := Ini.ReadInteger('legado', 'contagem2', FLegacy.Contagem2);
    FLegacy.Contagem3 := Ini.ReadInteger('legado', 'contagem3', FLegacy.Contagem3);
    FLegacy.Painel := Ini.ReadString('legado', 'painel', FLegacy.Painel);
    FLegacy.TipoImp := Ini.ReadInteger('legado', 'tipoimp', FLegacy.TipoImp);
    FLegacy.ModeloImp := Ini.ReadInteger('legado', 'modeloimp', FLegacy.ModeloImp);
  finally
    Ini.Free;
  end;
end;

constructor TSetMain.Create;
begin
  inherited Create;
  FLegacy := TLegacySettings.Create;

  FPATH := IncludeTrailingPathDelimiter(GetAppConfigDir(False));
  if not DirectoryExists(FPATH) then
    ForceDirectories(FPATH);

  CarregaContexto;
end;

constructor TSetMain.Create(const AConfigDir: string);
begin
  inherited Create;
  FLegacy := TLegacySettings.Create;

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

    Ini.WriteString('scale', 'protocol', FProtocolId);

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

    Ini.WriteString('logging', 'level', FLogLevel);
    Ini.WriteString('logging', 'file', FLogFile);
    Ini.WriteBool('logging', 'console', FLogConsole);

    Ini.WriteBool('compatibility', 'legacy_http_enabled', FLegacyHttpEnabled);
    Ini.WriteBool('compatibility', 'legacy_config_migration',
      FLegacyConfigMigration);

    // Campos mantidos por compatibilidade enquanto não forem removidos
    // definitivamente da aplicação.
    Ini.WriteString('legado', 'empresa', FLegacy.Empresa);
    Ini.WriteString('legado', 'localizacao', FLegacy.Localizacao);
    Ini.WriteString('legado', 'tipo1', FLegacy.Tipo1);
    Ini.WriteString('legado', 'tipo2', FLegacy.Tipo2);
    Ini.WriteString('legado', 'tipo3', FLegacy.Tipo3);
    Ini.WriteInteger('legado', 'contagem1', FLegacy.Contagem1);
    Ini.WriteInteger('legado', 'contagem2', FLegacy.Contagem2);
    Ini.WriteInteger('legado', 'contagem3', FLegacy.Contagem3);
    Ini.WriteString('legado', 'painel', FLegacy.Painel);
    Ini.WriteInteger('legado', 'tipoimp', FLegacy.TipoImp);
    Ini.WriteInteger('legado', 'modeloimp', FLegacy.ModeloImp);

    Ini.UpdateFile;
  finally
    Ini.Free;
  end;
end;

destructor TSetMain.Destroy;
begin
  // A aplicação salva explicitamente ao encerrar; não grava novamente aqui.
  FLegacy.Free;
  inherited Destroy;
end;

end.
