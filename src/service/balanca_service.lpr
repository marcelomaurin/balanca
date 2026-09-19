program balanca_service;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, setmain, headlesshost;

function ParamValue(const AName: string): string;
var
  I: Integer;
  Prefix: string;
begin
  Result := '';
  Prefix := AName + '=';

  for I := 1 to ParamCount do
    if Pos(Prefix, ParamStr(I)) = 1 then
      Exit(Copy(ParamStr(I), Length(Prefix) + 1, MaxInt));
end;

procedure ShowHelp;
begin
  WriteLn('balanca_service');
  WriteLn;
  WriteLn('Uso:');
  WriteLn('  balanca_service [--config-dir=<diretorio>]');
  WriteLn;
  WriteLn('Serviços:');
  WriteLn('  HTTP:      8097');
  WriteLn('  WebSocket: 8098 /weight');
end;

var
  Settings: TSetMain;
  Host: THeadlessScaleHost;
  ConfigDir: string;
begin
  if (ParamCount > 0) and
     ((ParamStr(1) = '--help') or (ParamStr(1) = '-h')) then
  begin
    ShowHelp;
    Halt(0);
  end;

  ConfigDir := ParamValue('--config-dir');

  if ConfigDir <> '' then
    Settings := TSetMain.Create(ConfigDir)
  else
    Settings := TSetMain.Create;

  Host := THeadlessScaleHost.Create(Settings, True);
  try
    try
      WriteLn('Balanca headless iniciando...');
      WriteLn('config: ', Settings.Path);
      Host.Start;

      while True do
      begin
        Host.Pump;
        Sleep(10);
      end;
    except
      on E: Exception do
      begin
        WriteLn(StdErr, 'erro fatal: ', E.Message);
        HaltCode := 1;
      end;
    end;
  finally
    Host.Free;
  end;
end.
