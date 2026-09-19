unit scaleconfig;

{$mode objfpc}{$H+}

interface

type
  { TScaleConfig }
  TScaleConfig = class
  private
    FPort: string;
    FBaudRate: Integer;
    FDataBits: Integer;
    FParity: Integer;
    FStopBits: Integer;
  public
    constructor Create;
    procedure Assign(AConfig: TScaleConfig);

    property Port: string read FPort write FPort;
    property BaudRate: Integer read FBaudRate write FBaudRate;
    property DataBits: Integer read FDataBits write FDataBits;
    property Parity: Integer read FParity write FParity;
    property StopBits: Integer read FStopBits write FStopBits;
  end;

implementation

constructor TScaleConfig.Create;
begin
  inherited Create;
  FPort := '';
  FBaudRate := 3; // 2400 bps no TLazSerial
  FDataBits := 0; // 8 bits
  FParity := 0;   // none
  FStopBits := 0; // 1 stop bit
end;

procedure TScaleConfig.Assign(AConfig: TScaleConfig);
begin
  if not Assigned(AConfig) then
    Exit;

  FPort := AConfig.Port;
  FBaudRate := AConfig.BaudRate;
  FDataBits := AConfig.DataBits;
  FParity := AConfig.Parity;
  FStopBits := AConfig.StopBits;
end;

end.
