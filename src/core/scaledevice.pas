unit scaledevice;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazSerial, scaleconfig, serialtransport, toledoprotocol;

type
  { TScaleDevice }
  TScaleDevice = class
  private
    FConfig: TScaleConfig;
    FTransport: TSerialTransport;
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
  inherited Destroy;
end;

function TScaleDevice.Connect: Boolean;
begin
  FLastError := '';
  try
    FTransport.ApplyConfig(FConfig);
    Result := FTransport.Connect;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      raise;
    end;
  end;
end;

procedure TScaleDevice.Disconnect;
begin
  FTransport.Disconnect;
  FProtocol.Reset;
end;

procedure TScaleDevice.ProcessIncoming;
var
  LData: string;
begin
  try
    LData := FTransport.ReadAvailable;
    if LData <> '' then
    begin
      FLastError := '';
      FProtocol.Feed(LData);
    end;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
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
  Result := FTransport.IsConnected;
end;

procedure TScaleDevice.ProtocolWeight(Sender: TObject; const AWeight: string);
begin
  FLastWeight := AWeight;
  FLastFrame := FProtocol.LastFrame;
  FLastRead := Now;

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
