program config_test;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, setmain, testassert;

procedure RemoveTree(const ADir: string);
var
  SR: TSearchRec;
  P: string;
begin
  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name = '.') or (SR.Name = '..') then
        Continue;
      P := IncludeTrailingPathDelimiter(ADir) + SR.Name;
      if (SR.Attr and faDirectory) <> 0 then
        RemoveTree(P)
      else
        DeleteFile(P);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  RemoveDir(ADir);
end;

var
  Dir, FileName: string;
  Legacy, Saved: TStringList;
  Settings, Reloaded: TSetMain;
begin
  Dir := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'balanca_cfg_test';

  if DirectoryExists(Dir) then
    RemoveTree(Dir);
  ForceDirectories(Dir);

  FileName := IncludeTrailingPathDelimiter(Dir) + 'main.cfg';
  Legacy := TStringList.Create;
  Saved := TStringList.Create;
  try
    Legacy.Add('DEVICE:1');
    Legacy.Add('POSX:123');
    Legacy.Add('POSY:456');
    Legacy.Add('HIDE:true');
    Legacy.Add('EXEC:false');
    Legacy.Add('COMPORT:COM77');
    Legacy.Add('BAUDRATE:3');
    Legacy.Add('DATABIT:0');
    Legacy.Add('PARIDADE:0');
    Legacy.Add('STOPBIT:0');
    Legacy.Add('SPLASH:1');
    Legacy.SaveToFile(FileName);

    Settings := TSetMain.Create(Dir);
    try
      AssertTrue(Settings.device, 'DEVICE legado');
      AssertEquals(123, Settings.posx, 'POSX legado');
      AssertEquals(456, Settings.posy, 'POSY legado');
      AssertEquals('COM77', Settings.COMPORT, 'COMPORT legado');
      AssertTrue(Settings.Splash, 'SPLASH legado');
    finally
      Settings.Free;
    end;

    Saved.LoadFromFile(FileName);
    AssertTrue(Saved.Count > 0, 'arquivo INI não foi salvo');
    AssertEquals('[geral]', Trim(Saved[0]), 'migração não gerou INI');

    Reloaded := TSetMain.Create(Dir);
    try
      AssertEquals('COM77', Reloaded.COMPORT, 'releitura do INI');
      AssertEquals(123, Reloaded.posx, 'releitura POSX');
      AssertEquals(456, Reloaded.posy, 'releitura POSY');
    finally
      Reloaded.Free;
    end;

    // Valor numérico inválido deve cair no default sem exceção.
    Legacy.Clear;
    Legacy.Add('POSX:abc');
    Legacy.Add('COMPORT:COM88');
    Legacy.SaveToFile(FileName);

    Settings := TSetMain.Create(Dir);
    try
      AssertEquals(0, Settings.posx, 'fallback de inteiro inválido');
      AssertEquals('COM88', Settings.COMPORT, 'campo válido em arquivo parcial');
    finally
      Settings.Free;
    end;

    WriteLn('OK - config_test');
  finally
    Legacy.Free;
    Saved.Free;
    if DirectoryExists(Dir) then
      RemoveTree(Dir);
  end;
end.
