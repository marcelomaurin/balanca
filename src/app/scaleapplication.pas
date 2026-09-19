unit scaleapplication;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazSerial, lNet, setmain, scaledevice, scaleapi,
  scalejson, websocketserver, scalecommands;

type
  TScaleConnectionState = (
    scsStopped,
    scsConnecting,
    scsConnected,
    scsWaitingReconnect
  );

  TScaleAppWeightEvent = procedure(Sender: TObject; const AWeight: string) of object;
  TScaleConnectionEvent = procedure(Sender: TObject;
    AState: TScaleConnectionState; const AMessage: string) of object;

  { TScaleApplication }
  TScaleApplication = class
  private
    FSettings: TSetMain;
    FDevice: TScaleDevice;
    FApi: TScaleApi;
    FWebSocket: TWeightWebSocketServer;
    FOnWeight: TScaleAppWeightEvent;
    FOnConnectionState: TScaleConnectionEvent;

    FDesiredActive: Boolean;
    FAutoReconnect: Boolean;
    FConnectionState: TScaleConnectionState;
    FConnectionMessage: string;
    FLastResponseTick: QWord;
    FConnectedSinceTick: QWord;
    FNextReconnectTick: QWord;
    FReconnectAttempts: Integer;
    FResponseTimeoutMs: Cardinal;
    FReconnectInitialMs: Cardinal;
    FReconnectMaxMs: Cardinal;

    procedure DeviceWeight(Sender: TObject; const AWeight: string);
    procedure SetConnectionState(AState: TScaleConnectionState;
      const AMessage: string);
    procedure ScheduleReconnect(const AReason: string);
    function RetryDelayMs: Cardinal;
    function TryConnectInternal: Boolean;
  public
    constructor Create(ASerial: TLazSerial; ASettings: TSetMain);
    destructor Destroy; override;

    procedure ApplySettings;
    function Connect: Boolean;
    procedure Disconnect;
    procedure ProcessSerial;
    procedure Tick;
    procedure ForceReconnect;

    function SupportsCommand(ACommand: TScaleCommand): Boolean;
    function QueueCommand(ACommand: TScaleCommand): Boolean;
    function Snapshot: TScaleSnapshot;
    function StatusJson: string;
    function ConnectionStateName: string;

    procedure WebSocketClientConnected(ASocket: TLSocket);
    procedure WebSocketClientDisconnected(ASocket: TLSocket);
    procedure WebSocketClientData(ASocket: TLSocket);

    property Api: TScaleApi read FApi;
    property Device: TScaleDevice read FDevice;
    property Settings: TSetMain read FSettings;
    property WebSocket: TWeightWebSocketServer read FWebSocket;
    property DesiredActive: Boolean read FDesiredActive;
    property AutoReconnect: Boolean read FAutoReconnect write FAutoReconnect;
    property ConnectionState: TScaleConnectionState read FConnectionState;
    property ReconnectAttempts: Integer read FReconnectAttempts;
    property ResponseTimeoutMs: Cardinal read FResponseTimeoutMs write FResponseTimeoutMs;
    property ReconnectInitialMs: Cardinal read FReconnectInitialMs write FReconnectInitialMs;
    property ReconnectMaxMs: Cardinal read FReconnectMaxMs write FReconnectMaxMs;
    property OnWeight: TScaleAppWeightEvent read FOnWeight write FOnWeight;
    property OnConnectionState: TScaleConnectionEvent
      read FOnConnectionState write FOnConnectionState;
  end;

implementation

constructor TScaleApplication.Create(ASerial: TLazSerial; ASettings: TSetMain);
begin
  inherited Create;

  if not Assigned(ASerial) then
    raise Exception.Create('Componente serial não informado');

  if not Assigned(ASettings) then
    raise Exception.Create('Configuração não informada');

  FSettings := ASettings;
  FDevice := TScaleDevice.Create(ASerial);
  FDevice.OnWeight := @DeviceWeight;
  FApi := TScaleApi.Create(FDevice, FSettings);
  FWebSocket := TWeightWebSocketServer.Create;

  FDesiredActive := False;
  FAutoReconnect := FSettings.ReconnectEnabled;
  FConnectionState := scsStopped;
  FConnectionMessage := 'Parado';
  FLastResponseTick := 0;
  FConnectedSinceTick := 0;
  FNextReconnectTick := 0;
  FReconnectAttempts := 0;
  FResponseTimeoutMs := Cardinal(FSettings.ResponseTimeoutMs);
  FReconnectInitialMs := Cardinal(FSettings.ReconnectInitialMs);
  FReconnectMaxMs := Cardinal(FSettings.ReconnectMaxMs);

  ApplySettings;
end;

destructor TScaleApplication.Destroy;
begin
  FWebSocket.Free;
  FApi.Free;
  FDevice.Free;
  inherited Destroy;
end;

procedure TScaleApplication.ApplySettings;
begin
  FDevice.Config.Port := FSettings.COMPORT;
  FDevice.Config.BaudRate := FSettings.BAUDRATE;
  FDevice.Config.DataBits := FSettings.DATABIT;
  FDevice.Config.Parity := FSettings.PARIDADE;
  FDevice.Config.StopBits := FSettings.STOPBIT;
end;

procedure TScaleApplication.SetConnectionState(AState: TScaleConnectionState;
  const AMessage: string);
begin
  FConnectionState := AState;
  FConnectionMessage := AMessage;
  if Assigned(FOnConnectionState) then
    FOnConnectionState(Self, AState, AMessage);
end;

function TScaleApplication.RetryDelayMs: Cardinal;
var
  Delay: QWord;
  I: Integer;
begin
  Delay := FReconnectInitialMs;

  for I := 2 to FReconnectAttempts do
  begin
    Delay := Delay * 2;
    if Delay >= FReconnectMaxMs then
    begin
      Delay := FReconnectMaxMs;
      Break;
    end;
  end;

  Result := Cardinal(Delay);
end;

procedure TScaleApplication.ScheduleReconnect(const AReason: string);
var
  Delay: Cardinal;
begin
  if not FDesiredActive then
  begin
    SetConnectionState(scsStopped, AReason);
    Exit;
  end;

  if not FAutoReconnect then
  begin
    SetConnectionState(scsStopped, AReason);
    Exit;
  end;

  Delay := RetryDelayMs;
  FNextReconnectTick := GetTickCount64 + Delay;
  SetConnectionState(scsWaitingReconnect,
    AReason + ' - nova tentativa em ' + IntToStr(Delay) + ' ms');
end;

function TScaleApplication.TryConnectInternal: Boolean;
begin
  Result := False;
  SetConnectionState(scsConnecting, 'Conectando em ' + FSettings.COMPORT);

  try
    ApplySettings;
    Result := FDevice.Connect;

    if Result then
    begin
      FReconnectAttempts := 0;
      FConnectedSinceTick := GetTickCount64;
      FLastResponseTick := FConnectedSinceTick;
      FNextReconnectTick := 0;
      SetConnectionState(scsConnected, 'Conectado em ' + FSettings.COMPORT);
    end
    else
    begin
      Inc(FReconnectAttempts);
      ScheduleReconnect('Conexão serial não estabelecida');
    end;
  except
    on E: Exception do
    begin
      Inc(FReconnectAttempts);
      ScheduleReconnect(E.Message);
      Result := False;
    end;
  end;
end;

function TScaleApplication.Connect: Boolean;
begin
  FDesiredActive := True;
  Result := TryConnectInternal;
end;

procedure TScaleApplication.Disconnect;
begin
  FDesiredActive := False;
  FNextReconnectTick := 0;
  FReconnectAttempts := 0;
  FDevice.Disconnect;
  SetConnectionState(scsStopped, 'Desconectado');
end;

procedure TScaleApplication.ForceReconnect;
begin
  FDesiredActive := True;

  try
    FDevice.Disconnect;
  except
  end;

  FNextReconnectTick := GetTickCount64;
  SetConnectionState(scsWaitingReconnect, 'Reconexão solicitada');
end;

procedure TScaleApplication.ProcessSerial;
begin
  try
    FDevice.ProcessIncoming;
  except
    on E: Exception do
    begin
      try
        FDevice.Disconnect;
      except
      end;
      Inc(FReconnectAttempts);
      ScheduleReconnect('Erro de leitura serial: ' + E.Message);
    end;
  end;
end;

procedure TScaleApplication.Tick;
var
  NowTick: QWord;
  SnapshotValue: TScaleSnapshot;
begin
  if not FDesiredActive then
    Exit;

  NowTick := GetTickCount64;
  SnapshotValue := FDevice.GetSnapshot;

  if not SnapshotValue.Connected then
  begin
    if FAutoReconnect and
       ((FNextReconnectTick = 0) or (NowTick >= FNextReconnectTick)) then
      TryConnectInternal;
    Exit;
  end;

  if (FResponseTimeoutMs > 0) and
     ((NowTick - FLastResponseTick) >= FResponseTimeoutMs) then
  begin
    try
      FDevice.Disconnect;
    except
    end;

    Inc(FReconnectAttempts);
    ScheduleReconnect('Timeout sem resposta da balança');
    Exit;
  end;

  try
    FDevice.ProcessPendingCommands;
    FDevice.RequestWeight;
  except
    on E: Exception do
    begin
      try
        FDevice.Disconnect;
      except
      end;
      Inc(FReconnectAttempts);
      ScheduleReconnect('Erro ao enviar comando: ' + E.Message);
    end;
  end;
end;

function TScaleApplication.SupportsCommand(ACommand: TScaleCommand): Boolean;
begin
  Result := FDevice.SupportsCommand(ACommand);
end;

function TScaleApplication.QueueCommand(ACommand: TScaleCommand): Boolean;
begin
  Result := FDevice.QueueCommand(ACommand);
end;

function TScaleApplication.Snapshot: TScaleSnapshot;
begin
  Result := FDevice.GetSnapshot;
end;

function TScaleApplication.ConnectionStateName: string;
begin
  case FConnectionState of
    scsStopped: Result := 'stopped';
    scsConnecting: Result := 'connecting';
    scsConnected: Result := 'connected';
    scsWaitingReconnect: Result := 'waiting_reconnect';
  else
    Result := 'unknown';
  end;
end;

function TScaleApplication.StatusJson: string;
var
  Base: string;
begin
  Base := FApi.StatusJson;

  if (Length(Base) > 0) and (Base[Length(Base)] = '}') then
    Delete(Base, Length(Base), 1);

  Result :=
    Base + ',' +
    '"supervisor":{' +
      '"desired_active":' + JsonBoolean(FDesiredActive) + ',' +
      '"auto_reconnect":' + JsonBoolean(FAutoReconnect) + ',' +
      '"state":' + JsonString(ConnectionStateName) + ',' +
      '"message":' + JsonString(FConnectionMessage) + ',' +
      '"reconnect_attempts":' + IntToStr(FReconnectAttempts) + ',' +
      '"response_timeout_ms":' + IntToStr(FResponseTimeoutMs) +
    '}' +
    '}';
end;

procedure TScaleApplication.DeviceWeight(Sender: TObject; const AWeight: string);
begin
  FLastResponseTick := GetTickCount64;

  if FConnectionState <> scsConnected then
    SetConnectionState(scsConnected, 'Comunicação restabelecida');

  FWebSocket.Broadcast(FApi.WeightJson);

  if Assigned(FOnWeight) then
    FOnWeight(Self, AWeight);
end;

procedure TScaleApplication.WebSocketClientConnected(ASocket: TLSocket);
begin
  FWebSocket.ClientConnected(ASocket);
end;

procedure TScaleApplication.WebSocketClientDisconnected(ASocket: TLSocket);
begin
  FWebSocket.ClientDisconnected(ASocket);
end;

procedure TScaleApplication.WebSocketClientData(ASocket: TLSocket);
begin
  FWebSocket.ClientData(ASocket);
end;

end.
