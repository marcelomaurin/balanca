unit headlesshost;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazSerial, lNet, lNetComponents, IdHTTPServer,
  IdCustomHTTPServer, IdContext, setmain, scaleapplication, httprouter;

type
  { THeadlessScaleHost }
  THeadlessScaleHost = class
  private
    FSettings: TSetMain;
    FOwnsSettings: Boolean;
    FSerial: TLazSerial;
    FHttpServer: TIdHTTPServer;
    FTcpServer: TLTCPComponent;
    FScaleApp: TScaleApplication;
    FRouter: TScaleHttpRouter;
    FLastTick: QWord;
    FTickIntervalMs: Cardinal;
    FStarted: Boolean;

    procedure SerialRxData(Sender: TObject);
    procedure HttpCommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure HttpCommandOther(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure TcpConnect(ASocket: TLSocket);
    procedure TcpDisconnect(ASocket: TLSocket);
    procedure TcpReceive(ASocket: TLSocket);
    procedure WeightReceived(Sender: TObject; const AWeight: string);
    procedure ConnectionStateChanged(Sender: TObject;
      AState: TScaleConnectionState; const AMessage: string);
  public
    constructor Create(ASettings: TSetMain; AOwnsSettings: Boolean = False);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
    procedure Pump;

    property Started: Boolean read FStarted;
    property TickIntervalMs: Cardinal read FTickIntervalMs write FTickIntervalMs;
  end;

implementation

const
  HTTP_PORT = 8097;
  WEBSOCKET_PORT = 8098;

constructor THeadlessScaleHost.Create(ASettings: TSetMain; AOwnsSettings: Boolean);
begin
  inherited Create;

  if not Assigned(ASettings) then
    raise Exception.Create('Configuração não informada ao host headless');

  FSettings := ASettings;
  FOwnsSettings := AOwnsSettings;
  FTickIntervalMs := 500;
  FStarted := False;
  FLastTick := 0;

  FSerial := TLazSerial.Create(nil);
  FSerial.OnRxData := @SerialRxData;

  FScaleApp := TScaleApplication.Create(FSerial, FSettings);
  FScaleApp.Logger.ConsoleEnabled := True;
  FScaleApp.OnWeight := @WeightReceived;
  FScaleApp.OnConnectionState := @ConnectionStateChanged;

  FRouter := TScaleHttpRouter.Create(FScaleApp);

  FHttpServer := TIdHTTPServer.Create(nil);
  FHttpServer.DefaultPort := HTTP_PORT;
  FHttpServer.Bindings.Clear;
  with FHttpServer.Bindings.Add do
  begin
    IP := FSettings.HttpBind;
    Port := HTTP_PORT;
  end;
  FHttpServer.OnCommandGet := @HttpCommandGet;
  FHttpServer.OnCommandOther := @HttpCommandOther;

  FTcpServer := TLTCPComponent.Create(nil);
  FTcpServer.Port := WEBSOCKET_PORT;
  FTcpServer.ReuseAddress := True;
  FTcpServer.OnConnect := @TcpConnect;
  FTcpServer.OnDisconnect := @TcpDisconnect;
  FTcpServer.OnReceive := @TcpReceive;
end;

destructor THeadlessScaleHost.Destroy;
begin
  Stop;
  FTcpServer.Free;
  FHttpServer.Free;
  FRouter.Free;
  FScaleApp.Free;
  FSerial.Free;

  if FOwnsSettings then
    FSettings.Free;

  inherited Destroy;
end;

procedure THeadlessScaleHost.Start;
begin
  if FStarted then
    Exit;

  FHttpServer.Active := True;
  FTcpServer.Listen(WEBSOCKET_PORT);

  if not FScaleApp.Connect then
    FScaleApp.Logger.Warn('serial',
      'Conexão inicial falhou; reconexão automática ativa');

  FLastTick := GetTickCount64;
  FStarted := True;

  FScaleApp.Logger.Info('http',
    FSettings.HttpBind + ':' + IntToStr(HTTP_PORT));
  FScaleApp.Logger.Info('websocket',
    'bind=' + FSettings.WebSocketBind + ' port=' + IntToStr(WEBSOCKET_PORT) +
    ' path=/weight');
  if Trim(FSettings.ApiKey) <> '' then
    FScaleApp.Logger.Info('security', 'API key habilitada')
  else
    FScaleApp.Logger.Warn('security', 'API key não configurada');
end;

procedure THeadlessScaleHost.Stop;
begin
  if not FStarted then
    Exit;

  try
    FScaleApp.Disconnect;
  except
    on E: Exception do
      FScaleApp.Logger.Error('serial', 'Erro ao desconectar: ' + E.Message);
  end;

  FHttpServer.Active := False;
  FStarted := False;
end;

procedure THeadlessScaleHost.Pump;
var
  NowTick: QWord;
begin
  if not FStarted then
    Exit;

  FTcpServer.CallAction;

  NowTick := GetTickCount64;
  if (NowTick - FLastTick) >= FTickIntervalMs then
  begin
    FLastTick := NowTick;

    try
      FScaleApp.Tick;
    except
      on E: Exception do
        FScaleApp.Logger.Error('service', 'Tick: ' + E.Message);
    end;
  end;
end;

procedure THeadlessScaleHost.SerialRxData(Sender: TObject);
begin
  try
    FScaleApp.ProcessSerial;
  except
    on E: Exception do
      FScaleApp.Logger.Error('serial', 'RX: ' + E.Message);
  end;
end;

procedure THeadlessScaleHost.HttpCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  FRouter.HandleGet(ARequestInfo, AResponseInfo);
end;

procedure THeadlessScaleHost.HttpCommandOther(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  FRouter.HandleOther(ARequestInfo, AResponseInfo);
end;

procedure THeadlessScaleHost.TcpConnect(ASocket: TLSocket);
begin
  FScaleApp.WebSocketClientConnected(ASocket);
end;

procedure THeadlessScaleHost.TcpDisconnect(ASocket: TLSocket);
begin
  FScaleApp.WebSocketClientDisconnected(ASocket);
end;

procedure THeadlessScaleHost.TcpReceive(ASocket: TLSocket);
begin
  FScaleApp.WebSocketClientData(ASocket);
end;

procedure THeadlessScaleHost.WeightReceived(Sender: TObject; const AWeight: string);
begin
  FScaleApp.Logger.Debug('weight', 'Peso: ' + AWeight);
end;

procedure THeadlessScaleHost.ConnectionStateChanged(Sender: TObject;
  AState: TScaleConnectionState; const AMessage: string);
const
  STATE_NAMES: array[TScaleConnectionState] of string = (
    'stopped',
    'connecting',
    'connected',
    'waiting_reconnect'
  );
begin
  FScaleApp.Logger.Info('connection',
    STATE_NAMES[AState] + ' - ' + AMessage);
end;

end.
