program commands_test;

{$mode objfpc}{$H+}

uses
  SysUtils, scalecommands, testassert;

procedure TestRoundTrip(ACommand: TScaleCommand);
var
  Parsed: TScaleCommand;
  Name: string;
begin
  Name := ScaleCommandName(ACommand);
  AssertTrue(TryParseScaleCommand(Name, Parsed), 'não parseou ' + Name);
  AssertEquals(Ord(ACommand), Ord(Parsed), 'round-trip de ' + Name);
end;

var
  C: TScaleCommand;
begin
  TestRoundTrip(scReadWeight);
  TestRoundTrip(scTare);
  TestRoundTrip(scZero);
  TestRoundTrip(scPrint);
  TestRoundTrip(scContinuousStart);
  TestRoundTrip(scContinuousStop);

  AssertTrue(TryParseScaleCommand(' weight ', C), 'alias weight');
  AssertEquals(Ord(scReadWeight), Ord(C), 'alias weight incorreto');

  AssertTrue(TryParseScaleCommand('continuous-start', C), 'alias continuous-start');
  AssertEquals(Ord(scContinuousStart), Ord(C), 'continuous-start incorreto');

  AssertTrue(not TryParseScaleCommand('explode', C), 'comando inválido foi aceito');

  WriteLn('OK - commands_test');
end.
