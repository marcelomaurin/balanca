program protocol_factory_test;

{$mode objfpc}{$H+}

uses
  SysUtils, scaleprotocol, protocolfactory, toledoprotocol, scalecommands,
  testassert;

var
  P: TScaleProtocol;
  Data: string;
begin
  AssertTrue(TScaleProtocolFactory.IsRegistered('toledo'),
    'toledo não registrado');
  AssertTrue(TScaleProtocolFactory.IsRegistered('prix3'),
    'alias prix3 não registrado');
  AssertTrue(TScaleProtocolFactory.IsRegistered('toledo-prix3'),
    'alias toledo-prix3 não registrado');

  P := TScaleProtocolFactory.CreateProtocol('toledo');
  try
    AssertEquals('toledo', P.ProtocolId, 'id do protocolo');
    AssertContains('Toledo', P.DisplayName, 'nome amigável');
    AssertTrue(P.SupportsCommand(scReadWeight), 'read deveria ser suportado');
    AssertTrue(P.TryEncodeCommand(scReadWeight, Data),
      'codificação de read falhou');
    AssertEquals(1, Length(Data), 'ENQ deve ter 1 byte');
    AssertEquals(5, Ord(Data[1]), 'byte ENQ incorreto');
  finally
    P.Free;
  end;

  P := TScaleProtocolFactory.CreateProtocol('prix3');
  try
    AssertEquals('toledo', P.ProtocolId, 'alias deve criar driver Toledo');
  finally
    P.Free;
  end;

  try
    P := TScaleProtocolFactory.CreateProtocol('fabricante-inexistente');
    P.Free;
    raise Exception.Create('FALHA: protocolo inexistente foi aceito');
  except
    on E: Exception do
      if Pos('Protocolo não registrado', E.Message) = 0 then
        raise;
  end;

  WriteLn('OK - protocol_factory_test');
end.
