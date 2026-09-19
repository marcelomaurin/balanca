program toledo_protocol_test;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, toledoprotocol;

type
  TCapture = class
  private
    FValues: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Weight(Sender: TObject; const AWeight: string);
    property Values: TStringList read FValues;
  end;

constructor TCapture.Create;
begin
  inherited Create;
  FValues := TStringList.Create;
end;

destructor TCapture.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

procedure TCapture.Weight(Sender: TObject; const AWeight: string);
begin
  FValues.Add(AWeight);
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('FALHA: ' + AMessage);
end;

var
  Protocol: TToledoProtocol;
  Capture: TCapture;
  BeforeCount: Integer;
  BeforeDiscarded: QWord;
begin
  Protocol := TToledoProtocol.Create;
  Capture := TCapture.Create;
  try
    Protocol.OnWeight := @Capture.Weight;

    { 1. Frame completo com ruído antes/depois }
    Protocol.Feed('ruido' + TOLEDO_STX + '+001.250' + TOLEDO_ETX + #13#10);
    Check(Capture.Values.Count = 1, 'frame completo não foi emitido');
    Check(Capture.Values[0] = '+001.250', 'payload do frame completo incorreto');

    { 2. Frame fragmentado em várias leituras }
    Protocol.Feed(TOLEDO_STX + '+00');
    Protocol.Feed('2.500');
    Protocol.Feed(TOLEDO_ETX);
    Check(Capture.Values.Count = 2, 'frame fragmentado não foi remontado');
    Check(Capture.Values[1] = '+002.500', 'payload fragmentado incorreto');

    { 3. Dois frames na mesma leitura serial }
    Protocol.Feed(
      TOLEDO_STX + '+003.000' + TOLEDO_ETX +
      TOLEDO_STX + '+004.000' + TOLEDO_ETX
    );
    Check(Capture.Values.Count = 4, 'múltiplos frames não foram processados');
    Check(Capture.Values[2] = '+003.000', 'primeiro frame múltiplo incorreto');
    Check(Capture.Values[3] = '+004.000', 'segundo frame múltiplo incorreto');

    { 4. Novo STX durante frame parcial deve resincronizar }
    BeforeDiscarded := Protocol.DiscardedFrames;
    Protocol.Feed(
      TOLEDO_STX + 'FRAME_INCOMPLETO' +
      TOLEDO_STX + '+005.000' + TOLEDO_ETX
    );
    Check(Capture.Values.Count = 5, 'resincronização por STX falhou');
    Check(Capture.Values[4] = '+005.000', 'frame após resincronização incorreto');
    Check(Protocol.DiscardedFrames > BeforeDiscarded,
      'frame parcial não foi contabilizado como descartado');

    { 5. STX/ETX sem payload deve ser descartado }
    BeforeCount := Capture.Values.Count;
    BeforeDiscarded := Protocol.DiscardedFrames;
    Protocol.Feed(TOLEDO_STX + TOLEDO_ETX);
    Check(Capture.Values.Count = BeforeCount, 'frame vazio foi emitido');
    Check(Protocol.DiscardedFrames > BeforeDiscarded,
      'frame vazio não foi contabilizado');

    { 6. Proteção contra frame sem ETX / payload excessivo }
    BeforeCount := Capture.Values.Count;
    BeforeDiscarded := Protocol.DiscardedFrames;
    Protocol.Feed(
      TOLEDO_STX + StringOfChar('9', TOLEDO_MAX_PAYLOAD + 1) + TOLEDO_ETX
    );
    Check(Capture.Values.Count = BeforeCount, 'frame excessivo foi emitido');
    Check(Protocol.DiscardedFrames > BeforeDiscarded,
      'frame excessivo não foi descartado');

    WriteLn('OK - todos os testes do parser Toledo passaram.');
  finally
    Capture.Free;
    Protocol.Free;
  end;
end.
