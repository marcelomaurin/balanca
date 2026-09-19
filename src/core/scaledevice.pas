unit scaledevice;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, LazSerial, scaleconfig, serialtransport,
  scaleprotocol, protocolfactory, toledoprotocol, scalecommands;

type
  TScaleSnapshot = record
    Connected: Boolean;
    LastWeight: string;
    LastFrame: string;
    LastError: string;
    LastRead: TDateTime;
    DiscardedFrames: QWord;
    IgnoredBytes: QWord;
    ProtocolId: string;
    ProtocolName: string;
  end;

  { TScaleDevice }
  TScaleDevice = class
  private
    FConfig: TScaleConfig;
    FTransport: TSerialTransport;
    FLock: TCriticalSection;
    FConnected: Boolean;
    FProtocol: TScaleProtocol;
    FPendingCommands: TStringList;
    FLastWeight: string;
    FLastFrame: string;
    FLastError: string;
    FLastRead: TDateTime;
    FDiscardedFrames: QWord;
    FIgnoredBytes: QWord;
    FOnWeight: TWeightEvent;
    procedure ProtocolWeight(Sender: TObject; const AWeight: string);
    function GetDiscardedFrames: QWord;
    function GetIgnoredBytes: QWord;
    function ExecuteCommand(ACommand: TScaleCommand): Boolean;
    function GetProtocolId: string;
    function GetProtocolName: string;
  public
    constructor Create(ASerial: TLazSerial);
    destructor Destroy; override;

    function Connect: Boolean;
    procedure Disconnect;
    procedure ProcessIncoming;
    procedure SetProtocol(const AProtocolId: string);
    procedure RequestWeight;
    function SupportsCommand(ACommand: TScaleCommand): Boolean;
    function QueueCommand(ACommand: TScaleCommand): Boolean;
    procedure ProcessPendingCommands;
    function IsConnected: Boolean;
    function GetSnapshot: TScaleSnapshot;

    property Config: TScaleConfig read FConfig;
    property LastWeight: string read FLastWeight;
    property LastFrame: string read FLastFrame;
    property LastError: string read FLastError;
    property LastRead: TDateTime read FLastRead;
    property DiscardedFrames: QWord read GetDiscardedFrames;
    property IgnoredBytes: QWord read GetIgnoredBytes;
    property ProtocolId: string read GetProtocolId;
    property ProtocolName: string read GetProtocolName;
    property OnWeight: TWeightEvent read FOnWeight write FOnWeight;
  end;

implementation

constructor TScaleDevice.Create(ASerial: TLazSerial);
begin
  inherited Create;
  FConfig := TScaleConfig.Create;
  FTransport := TSerialTransport.Create(ASerial);
  FLock := TCriticalSection.Create;
  FConnected := False;
  FProtocol := TScaleProtocolFactory.CreateProtocol('toledo');
  FProtocol.OnWeight := @ProtocolWeight;
  FPendingCommands := TStringList.Create;
  FLastWeight := '';
  FLastFrame := '';
  FLastError := '';
  FLastRead := 0;
  FDiscardedFrames := 0;
  FIgnoredBytes := 0;
end;

destructor TScaleDevice.Destroy;
begin
  Disconnect;
  FPendingCommands.Free;
  FProtocol.Free;
  FTransport.Free;
  FConfig.Free;
  FLock.Free;
  inherited Destroy;
end;

function TScaleDevice.Connect: Boolean;
begin
  FLock.Acquire;
  try
    FLastError := '';
  finally
    FLock.Release;
  end;

  try
    FTransport.ApplyConfig(FConfig);
    Result := FTransport.Connect;

    FLock.Acquire;
    try
      FConnected := Result;
    finally
      FLock.Release;
    end;
  except
    on E: Exception do
    begin
      FLock.Acquire;
      try
        FConnected := False;
        FLastError := E.Message;
      finally
        FLock.Release;
      end;
      raise;
    end;
  end;
end;

procedure TScaleDevice.Disconnect;
begin
  FTransport.Disconnect;
  FProtocol.Reset;

  FLock.Acquire;
  try
    FConnected := False;
  finally
    FLock.Release;
  end;
end;

procedure TScaleDevice.ProcessIncoming;
var
  LData: string;
  Discarded, Ignored: QWord;
begin
  try
    LData := FTransport.ReadAvailable;
    if LData <> '' then
    begin
      FLock.Acquire;
      try
        FLastError := '';
      finally
        FLock.Release;
      end;
      FProtocol.Feed(LData);
      Discarded := FProtocol.DiscardedFrames();
      Ignored := FProtocol.IgnoredBytes();

      FLock.Acquire;
      try
        FDiscardedFrames := Discarded;
        FIgnoredBytes := Ignored;
      finally
        FLock.Release;
      end;
    end;
  except
    on E: Exception do
    begin
      FLock.Acquire;
      try
        FLastError := E.Message;
      finally
        FLock.Release;
      end;
      raise;
    end;
  end;
end;

procedure TScaleDevice.SetProtocol(const AProtocolId: string);
var
  NewProtocol: TScaleProtocol;
begin
  if IsConnected then
    raise Exception.Create('Não é possível trocar protocolo com a balança conectada');

  if SameText(FProtocol.ProtocolId(), Trim(AProtocolId)) then
    Exit;

  NewProtocol := TScaleProtocolFactory.CreateProtocol(AProtocolId);
  try
    NewProtocol.OnWeight := @ProtocolWeight;
    FProtocol.Free;
    FProtocol := NewProtocol;
  except
    NewProtocol.Free;
    raise;
  end;

  FLock.Acquire;
  try
    FLastWeight := '';
    FLastFrame := '';
    FLastRead := 0;
    FLastError := '';
    FDiscardedFrames := 0;
    FIgnoredBytes := 0;
  finally
    FLock.Release;
  end;
end;

procedure TScaleDevice.RequestWeight;
begin
  ExecuteCommand(scReadWeight);
end;

function TScaleDevice.SupportsCommand(ACommand: TScaleCommand): Boolean;
begin
  Result := FProtocol.SupportsCommand(ACommand);
end;

function TScaleDevice.QueueCommand(ACommand: TScaleCommand): Boolean;
begin
  Result := SupportsCommand(ACommand) and IsConnected;
  if not Result then
    Exit;

  FLock.Acquire;
  try
    FPendingCommands.Add(ScaleCommandName(ACommand));
  finally
    FLock.Release;
  end;
end;

procedure TScaleDevice.ProcessPendingCommands;
var
  CommandName: string;
  Command: TScaleCommand;
begin
  while True do
  begin
    CommandName := '';

    FLock.Acquire;
    try
      if FPendingCommands.Count > 0 then
      begin
        CommandName := FPendingCommands[0];
        FPendingCommands.Delete(0);
      end;
    finally
      FLock.Release;
    end;

    if CommandName = '' then
      Break;

    if TryParseScaleCommand(CommandName, Command) then
      ExecuteCommand(Command);
  end;
end;

function TScaleDevice.ExecuteCommand(ACommand: TScaleCommand): Boolean;
var
  Data: string;
begin
  Result := False;

  if not FProtocol.TryEncodeCommand(ACommand, Data) then
    Exit;

  if not IsConnected then
    Exit;

  FTransport.WriteData(Data);
  Result := True;
end;

function TScaleDevice.IsConnected: Boolean;
begin
  FLock.Acquire;
  try
    Result := FConnected;
  finally
    FLock.Release;
  end;
end;

function TScaleDevice.GetSnapshot: TScaleSnapshot;
begin
  FLock.Acquire;
  try
    Result.Connected := FConnected;
    Result.LastWeight := FLastWeight;
    Result.LastFrame := FLastFrame;
    Result.LastError := FLastError;
    Result.LastRead := FLastRead;
    Result.DiscardedFrames := FDiscardedFrames;
    Result.IgnoredBytes := FIgnoredBytes;
    Result.ProtocolId := FProtocol.ProtocolId();
    Result.ProtocolName := FProtocol.DisplayName();
  finally
    FLock.Release;
  end;
end;

procedure TScaleDevice.ProtocolWeight(Sender: TObject; const AWeight: string);
begin
  FLock.Acquire;
  try
    FLastWeight := AWeight;
    FLastFrame := FProtocol.LastFrame();
    FLastRead := Now;
  finally
    FLock.Release;
  end;

  if Assigned(FOnWeight) then
    FOnWeight(Self, AWeight);
end;

function TScaleDevice.GetDiscardedFrames: QWord;
begin
  FLock.Acquire;
  try
    Result := FDiscardedFrames;
  finally
    FLock.Release;
  end;
end;

function TScaleDevice.GetIgnoredBytes: QWord;
begin
  FLock.Acquire;
  try
    Result := FIgnoredBytes;
  finally
    FLock.Release;
  end;
end;

function TScaleDevice.GetProtocolId: string;
begin
  Result := FProtocol.ProtocolId();
end;

function TScaleDevice.GetProtocolName: string;
begin
  Result := FProtocol.DisplayName();
end;

end.
