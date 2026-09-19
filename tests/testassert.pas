unit testassert;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

procedure AssertTrue(ACondition: Boolean; const AMessage: string);
procedure AssertEquals(const AExpected, AActual, AMessage: string); overload;
procedure AssertEquals(AExpected, AActual: Int64; const AMessage: string); overload;
procedure AssertContains(const ANeedle, AHaystack, AMessage: string);

implementation

procedure Fail(const AMessage: string);
begin
  raise Exception.Create('FALHA: ' + AMessage);
end;

procedure AssertTrue(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    Fail(AMessage);
end;

procedure AssertEquals(const AExpected, AActual, AMessage: string);
begin
  if AExpected <> AActual then
    Fail(AMessage + ' esperado="' + AExpected + '" atual="' + AActual + '"');
end;

procedure AssertEquals(AExpected, AActual: Int64; const AMessage: string);
begin
  if AExpected <> AActual then
    Fail(AMessage + ' esperado=' + IntToStr(AExpected) +
      ' atual=' + IntToStr(AActual));
end;

procedure AssertContains(const ANeedle, AHaystack, AMessage: string);
begin
  if Pos(ANeedle, AHaystack) = 0 then
    Fail(AMessage + ' trecho ausente="' + ANeedle + '"');
end;

end.
