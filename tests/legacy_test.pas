program legacy_test;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, legacyconfig, legacyapi, legacysettings, testassert;

var
  L: TStringList;
  S: TLegacySettings;
  TempFile, Html, Json: string;
begin
  L := TStringList.Create;
  S := TLegacySettings.Create;
  try
    L.Add('DEVICE:1');
    L.Add('POSX:abc');
    L.Add('EMPRESA:Teste');
    L.Add('HIDE:sim');

    AssertEquals('Teste', LegacyValue(L, 'EMPRESA', ''), 'legacy value');
    AssertEquals(7, LegacyInteger(L, 'POSX', 7), 'legacy integer fallback');
    AssertTrue(LegacyBoolean(L, 'HIDE', False), 'legacy boolean');

    S.ResetDefaults;
    AssertEquals('maurinsoft', S.Empresa, 'legacy default empresa');
    AssertEquals('Normal', S.Tipo1, 'legacy default tipo1');

    Json := BuildLegacyWeightJson('+001.250');
    AssertEquals('{"rs":{"peso":"+001.250"}}', Json, 'legacy JSON');

    Html := BuildLegacyHtmlResponse('+001.250');
    AssertContains('<html>', Html, 'legacy html');
    AssertContains('{"rs":{"peso":"+001.250"}}', Html, 'legacy html payload');

    TempFile := IncludeTrailingPathDelimiter(GetTempDir(False)) +
      'balanca_legacy_test.cfg';
    L.SaveToFile(TempFile);
    AssertTrue(IsLegacyConfigFile(TempFile), 'detecção de config legada');

    L.Clear;
    L.Add('[serial]');
    L.Add('comport=COM1');
    L.SaveToFile(TempFile);
    AssertTrue(not IsLegacyConfigFile(TempFile), 'INI não deve ser legado');

    DeleteFile(TempFile);
  finally
    S.Free;
    L.Free;
  end;

  WriteLn('OK - legacy_test');
end.
