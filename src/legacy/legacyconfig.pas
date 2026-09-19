unit legacyconfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function LegacyValue(AList: TStrings; const AKey, ADefault: string): string;
function LegacyInteger(AList: TStrings; const AKey: string;
  ADefault: Integer): Integer;
function LegacyBoolean(AList: TStrings; const AKey: string;
  ADefault: Boolean): Boolean;
function IsLegacyConfigFile(const AFileName: string): Boolean;

implementation

function LegacyValue(AList: TStrings; const AKey, ADefault: string): string;
var
  I, P: Integer;
  S, K: string;
begin
  Result := ADefault;
  K := UpperCase(AKey);

  for I := 0 to AList.Count - 1 do
  begin
    S := AList[I];
    P := Pos(':', S);
    if P <= 0 then
      Continue;

    if UpperCase(Trim(Copy(S, 1, P - 1))) = K then
    begin
      Result := Trim(Copy(S, P + 1, MaxInt));
      Exit;
    end;
  end;
end;

function LegacyInteger(AList: TStrings; const AKey: string;
  ADefault: Integer): Integer;
var
  S: string;
begin
  S := LegacyValue(AList, AKey, IntToStr(ADefault));
  if not TryStrToInt(S, Result) then
    Result := ADefault;
end;

function LegacyBoolean(AList: TStrings; const AKey: string;
  ADefault: Boolean): Boolean;
var
  S: string;
begin
  S := LowerCase(Trim(LegacyValue(AList, AKey, BoolToStr(ADefault, True))));
  if (S = '1') or (S = 'true') or (S = 'yes') or (S = 'sim') then
    Exit(True);
  if (S = '0') or (S = 'false') or (S = 'no') or
     (S = 'nao') or (S = 'não') then
    Exit(False);
  Result := ADefault;
end;

function IsLegacyConfigFile(const AFileName: string): Boolean;
var
  L: TStringList;
  S: string;
  I: Integer;
begin
  Result := False;
  if not FileExists(AFileName) then
    Exit;

  L := TStringList.Create;
  try
    L.LoadFromFile(AFileName);

    for I := 0 to L.Count - 1 do
    begin
      S := Trim(L[I]);
      if S = '' then
        Continue;

      // Se o primeiro conteúdo útil já é uma seção INI, não é legado.
      if (Length(S) >= 2) and (S[1] = '[') and
         (S[Length(S)] = ']') then
        Exit(False);

      // O formato histórico era CHAVE:valor.
      if Pos(':', S) > 1 then
        Exit(True);

      Exit(False);
    end;
  finally
    L.Free;
  end;
end;

end.
