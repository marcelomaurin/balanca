unit scalecommands;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TScaleCommand = (
    scReadWeight,
    scTare,
    scZero,
    scPrint,
    scContinuousStart,
    scContinuousStop
  );

function ScaleCommandName(ACommand: TScaleCommand): string;
function TryParseScaleCommand(const AValue: string; out ACommand: TScaleCommand): Boolean;

implementation

function ScaleCommandName(ACommand: TScaleCommand): string;
begin
  case ACommand of
    scReadWeight: Result := 'read';
    scTare: Result := 'tare';
    scZero: Result := 'zero';
    scPrint: Result := 'print';
    scContinuousStart: Result := 'continuous_start';
    scContinuousStop: Result := 'continuous_stop';
  else
    Result := 'unknown';
  end;
end;

function TryParseScaleCommand(const AValue: string; out ACommand: TScaleCommand): Boolean;
var
  V: string;
begin
  V := LowerCase(Trim(AValue));

  Result := True;
  if (V = 'read') or (V = 'weight') then
    ACommand := scReadWeight
  else if V = 'tare' then
    ACommand := scTare
  else if V = 'zero' then
    ACommand := scZero
  else if V = 'print' then
    ACommand := scPrint
  else if (V = 'continuous_start') or (V = 'continuous-start') then
    ACommand := scContinuousStart
  else if (V = 'continuous_stop') or (V = 'continuous-stop') then
    ACommand := scContinuousStop
  else
    Result := False;
end;

end.
