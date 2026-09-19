unit serialtransport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazSerial, scaleconfig;

type
  { TSerialTransport }
  TSerialTransport = class
  private
    FSerial: TLazSerial;
  public
    constructor Create(ASerial: TLazSerial);

    procedure ApplyConfig(AConfig: TScaleConfig);
    function Connect: Boolean;
    procedure Disconnect;
    procedure WriteData(const AData: string);
    function ReadAvailable: string;
    function IsConnected: Boolean;
  end;

implementation

constructor TSerialTransport.Create(ASerial: TLazSerial);
begin
  inherited Create;
  if not Assigned(ASerial) then
    raise Exception.Create('Componente serial não informado');
  FSerial := ASerial;
end;

procedure TSerialTransport.ApplyConfig(AConfig: TScaleConfig);
begin
  if not Assigned(AConfig) then
    raise Exception.Create('Configuração da balança não informada');

  FSerial.Device := AConfig.Port;
  FSerial.BaudRate := TBaudRate(AConfig.BaudRate);
  FSerial.DataBits := TDataBits(AConfig.DataBits);
  FSerial.Parity := TParity(AConfig.Parity);
  FSerial.StopBits := TStopBits(AConfig.StopBits);
end;

function TSerialTransport.Connect: Boolean;
begin
  if FSerial.Active then
    FSerial.Close;

  FSerial.Open;
  Result := FSerial.Active;
end;

procedure TSerialTransport.Disconnect;
begin
  if FSerial.Active then
    FSerial.Close;
end;

procedure TSerialTransport.WriteData(const AData: string);
begin
  if FSerial.Active then
    FSerial.WriteData(AData);
end;

function TSerialTransport.ReadAvailable: string;
begin
  Result := '';
  if FSerial.DataAvailable then
    Result := FSerial.ReadData;
end;

function TSerialTransport.IsConnected: Boolean;
begin
  Result := FSerial.Active;
end;

end.
