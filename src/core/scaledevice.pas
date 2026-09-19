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
    FOnWeight: TWeightEvent;
    procedure ProtocolWeight(Sender: TObject; const AWeight: string);
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
  FTransport.ApplyConfig(FConfig);
  Result := FTransport.Connect;
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
  LData := FTransport.ReadAvailable;
  if LData <> '' then
    FProtocol.Feed(LData);
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
  if Assigned(FOnWeight) then
    FOnWeight(Self, AWeight);
end;

end.
