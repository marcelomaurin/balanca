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
      AssertTrue(Settings.ReconnectEnabled, 'reconexão default');
      AssertEquals(3000, Settings.ResponseTimeoutMs, 'timeout default');
      AssertEquals(1000, Settings.ReconnectInitialMs, 'backoff inicial default');
      AssertEquals(30000, Settings.ReconnectMaxMs, 'backoff máximo default');
      AssertEquals('toledo', Settings.ProtocolId, 'protocolo default');
      AssertEquals('127.0.0.1', Settings.HttpBind, 'HTTP bind seguro default');
      AssertEquals('127.0.0.1', Settings.WebSocketBind, 'WS bind seguro default');
      AssertEquals('', Settings.ApiKey, 'API key default vazia');
      AssertTrue(not Settings.AllowRemoteWithoutApiKey,
        'acesso remoto sem chave deve ser bloqueado por default');
      AssertTrue(Settings.CommandsEnabled, 'comandos habilitados por default');
      AssertEquals('info', Settings.LogLevel, 'nível de log default');
      AssertTrue(Pos('balanca.log', Settings.LogFile) > 0,
        'arquivo de log default');
      AssertTrue(not Settings.LogConsole, 'console de log default');

      Settings.ReconnectEnabled := True;
      Settings.ResponseTimeoutMs := 4500;
      Settings.ReconnectInitialMs := 1500;
      Settings.ReconnectMaxMs := 20000;
      Settings.ProtocolId := 'prix3';
      Settings.HttpBind := '0.0.0.0';
      Settings.WebSocketBind := '0.0.0.0';
      Settings.ApiKey := 'teste-chave-123';
      Settings.AllowRemoteWithoutApiKey := False;
      Settings.CommandsEnabled := False;
      Settings.LogLevel := 'debug';
      Settings.LogFile := IncludeTrailingPathDelimiter(Dir) + 'teste.log';
      Settings.LogConsole := True;
      Settings.SalvaContexto;
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
      AssertTrue(Reloaded.ReconnectEnabled, 'releitura reconnect enabled');
      AssertEquals(4500, Reloaded.ResponseTimeoutMs, 'releitura timeout');
      AssertEquals(1500, Reloaded.ReconnectInitialMs, 'releitura backoff inicial');
      AssertEquals(20000, Reloaded.ReconnectMaxMs, 'releitura backoff máximo');
      AssertEquals('prix3', Reloaded.ProtocolId, 'releitura protocolo');
      AssertEquals('0.0.0.0', Reloaded.HttpBind, 'releitura HTTP bind');
      AssertEquals('0.0.0.0', Reloaded.WebSocketBind, 'releitura WS bind');
      AssertEquals('teste-chave-123', Reloaded.ApiKey, 'releitura API key');
      AssertTrue(not Reloaded.AllowRemoteWithoutApiKey,
        'releitura allow remote');
      AssertTrue(not Reloaded.CommandsEnabled, 'releitura commands enabled');
      AssertEquals('debug', Reloaded.LogLevel, 'releitura log level');
      AssertEquals(IncludeTrailingPathDelimiter(Dir) + 'teste.log',
        Reloaded.LogFile, 'releitura log file');
      AssertTrue(Reloaded.LogConsole, 'releitura log console');
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
