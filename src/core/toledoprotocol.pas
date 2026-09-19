unit toledoprotocol;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  TOLEDO_ENQ = #$05;
  TOLEDO_STX = #$02;
  TOLEDO_ETX = #$03;

type
  TWeightEvent = procedure(Sender: TObject; const AWeight: string) of object;

  { TToledoProtocol }
  TToledoProtocol = class
  private
    FBuffer: string;
    FOnWeight: TWeightEvent;
    procedure EmitWeight;
  public
    constructor Create;
    procedure Reset;
    procedure Feed(const AData: string);

    property OnWeight: TWeightEvent read FOnWeight write FOnWeight;
  end;

implementation

constructor TToledoProtocol.Create;
begin
  inherited Create;
  Reset;
end;

procedure TToledoProtocol.Reset;
begin
  FBuffer := '';
end;

procedure TToledoProtocol.EmitWeight;
var
  LWeight: string;
  P: SizeInt;
begin
  LWeight := FBuffer;

  P := Pos(TOLEDO_STX, LWeight);
  if P > 0 then
    LWeight := Copy(LWeight, P + 1, Length(LWeight));

  if Assigned(FOnWeight) then
    FOnWeight(Self, LWeight);

  FBuffer := '';
end;

procedure TToledoProtocol.Feed(const AData: string);
begin
  if AData = '' then
    Exit;

  // Mantém nesta etapa o comportamento do parser legado:
  // acumula dados até receber ETX isolado.
  // A máquina de estados para frames fragmentados/múltiplos será tratada
  // na atividade específica de robustez do parser.
  if AData = TOLEDO_ETX then
    EmitWeight
  else
    FBuffer := FBuffer + AData;
end;

end.
