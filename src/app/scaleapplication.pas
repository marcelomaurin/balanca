unit scaleapplication;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazSerial, lNet, setmain, scaledevice, scaleapi,
  websocketserver, scalecommands;

type
  TScaleAppWeightEvent = procedure(Sender: TObject; const AWeight: string) of object;

  { TScaleApplication }
  TScaleApplication = class
  private
    FSettings: TSetMain;
    FDevice: TScaleDevice;
    FApi: TScaleApi;
    FWebSocket: TWeightWebSocketServer;
    FOnWeight: TScaleAppWeightEvent;

    procedure DeviceWeight(Sender: TObject; const AWeight: string);
  public
    constructor Create(ASerial: TLazSerial; ASettings: TSetMain);
    destructor Destroy; override;

    procedure ApplySettings;
    function Connect: Boolean;
    procedure Disconnect;
    procedure ProcessSerial;
    procedure Tick;

    function SupportsCommand(ACommand: TScaleCommand): Boolean;
    function QueueCommand(ACommand: TScaleCommand): Boolean;
    function Snapshot: TScaleSnapshot;

    procedure WebSocketClientConnected(ASocket: TLSocket);
    procedure WebSocketClientDisconnected(ASocket: TLSocket);
    procedure WebSocketClientData(ASocket: TLSocket);

    property Api: TScaleApi read FApi;
    property Device: TScaleDevice read FDevice;
    property Settings: TSetMain read FSettings;
    property WebSocket: TWeightWebSocketServer read FWebSocket;
    property OnWeight: TScaleAppWeightEvent read FOnWeight write FOnWeight;
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

function TScaleApplication.Connect: Boolean;
begin
  ApplySettings;
  Result := FDevice.Connect;
end;

procedure TScaleApplication.Disconnect;
begin
  FDevice.Disconnect;
end;

procedure TScaleApplication.ProcessSerial;
begin
  FDevice.ProcessIncoming;
end;

procedure TScaleApplication.Tick;
begin
  FDevice.ProcessPendingCommands;
  FDevice.RequestWeight;
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

procedure TScaleApplication.DeviceWeight(Sender: TObject; const AWeight: string);
begin
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
