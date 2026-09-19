unit scaledevice;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, LazSerial, scaleconfig, serialtransport, toledoprotocol;

type
  TScaleSnapshot = record
    Connected: Boolean;
    LastWeight: string;
    LastFrame: string;
    LastError: string;
    LastRead: TDateTime;
    DiscardedFrames: QWord;
    IgnoredBytes: QWord;
  end;

  { TScaleDevice }
  TScaleDevice = class
  private
    FConfig: TScaleConfig;
    FTransport: TSerialTransport;
    FLock: TCriticalSection;
    FConnected: Boolean;
    FProtocol: TToledoProtocol;
    FLastWeight: string;
    FLastFrame: string;
    FLastError: string;
    FLastRead: TDateTime;
    FOnWeight: TWeightEvent;
    procedure ProtocolWeight(Sender: TObject; const AWeight: string);
    function GetDiscardedFrames: QWord;
    function GetIgnoredBytes: QWord;
  public
    constructor Create(ASerial: TLazSerial);
    destructor Destroy; override;

    function Connect: Boolean;
    procedure Disconnect;
    procedure ProcessIncoming;
    procedure RequestWeight;
    function IsConnected: Boolean;
    function GetSnapshot: TScaleSnapshot;

    property Config: TScaleConfig read FConfig;
    property LastWeight: string read FLastWeight;
    property LastFrame: string read FLastFrame;
    property LastError: string read FLastError;
    property LastRead: TDateTime read FLastRead;
    property DiscardedFrames: QWord read GetDiscardedFrames;
    property IgnoredBytes: QWord read GetIgnoredBytes;
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
  FProtocol := TToledoProtocol.Create;
  FProtocol.OnWeight := @ProtocolWeight;
  FLastWeight := '';
  FLastFrame := '';
  FLastError := '';
  FLastRead := 0;
end;

destructor TScaleDevice.Destroy;
begin
  Disconnect;
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

procedure TScaleDevice.RequestWeight;
begin
  FTransport.WriteData(TOLEDO_ENQ);
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
    Result.DiscardedFrames := FProtocol.DiscardedFrames;
    Result.IgnoredBytes := FProtocol.IgnoredBytes;
  finally
    FLock.Release;
  end;
end;

procedure TScaleDevice.ProtocolWeight(Sender: TObject; const AWeight: string);
begin
  FLock.Acquire;
  try
    FLastWeight := AWeight;
    FLastFrame := FProtocol.LastFrame;
    FLastRead := Now;
  finally
    FLock.Release;
  end;

  if Assigned(FOnWeight) then
    FOnWeight(Self, AWeight);
end;

function TScaleDevice.GetDiscardedFrames: QWord;
begin
  Result := FProtocol.DiscardedFrames;
end;

function TScaleDevice.GetIgnoredBytes: QWord;
begin
  Result := FProtocol.IgnoredBytes;
end;

end.
