program logger_test;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, applogger, testassert;

var
  L: TAppLogger;
  FileName: string;
  Lines: TStringList;
begin
  FileName := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'balanca_logger_test.log';
  if FileExists(FileName) then
    DeleteFile(FileName);

  L := TAppLogger.Create;
  Lines := TStringList.Create;
  try
    L.FileName := FileName;
    L.ConsoleEnabled := False;
    L.MinLevel := llInfo;

    L.Debug('test', 'não deve aparecer');
    L.Info('test', 'mensagem info');
    L.Warn('test', 'mensagem warn');
    L.Error('test', 'mensagem error');

    AssertTrue(FileExists(FileName), 'arquivo de log não criado');
    Lines.LoadFromFile(FileName);
    AssertEquals(3, Lines.Count, 'quantidade de linhas');
    AssertContains('[INFO] [test] mensagem info', Lines[0], 'linha info');
    AssertContains('[WARN] [test] mensagem warn', Lines[1], 'linha warn');
    AssertContains('[ERROR] [test] mensagem error', Lines[2], 'linha error');
  finally
    Lines.Free;
    L.Free;
    if FileExists(FileName) then
      DeleteFile(FileName);
  end;

  WriteLn('OK - logger_test');
end.
