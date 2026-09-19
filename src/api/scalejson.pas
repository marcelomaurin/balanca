unit scalejson;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TScaleJsonSnapshot = record
    Connected: Boolean;
    Weight: string;
    LastRead: TDateTime;
    LastError: string;
    DiscardedFrames: QWord;
    IgnoredBytes: QWord;
  end;

function JsonEscape(const AValue: string): string;
function JsonString(const AValue: string): string;
function JsonBoolean(AValue: Boolean): string;
function IsoDateTime(AValue: TDateTime): string;
function BuildWeightJson(const ASnapshot: TScaleJsonSnapshot): string;
function BuildStatusJson(const ASnapshot: TScaleJsonSnapshot): string;
function BuildConfigJson(const APort: string; ABaudRate, ADataBit, AParity,
  AStopBit, AHttpPort, AWebSocketPort: Integer; const AWebSocketPath: string): string;
function BuildNotFoundJson(const APath: string): string;
function BuildCommandResultJson(const ACommand: string; AAccepted: Boolean;
  const AMessage: string): string;

implementation

function JsonEscape(const AValue: string): string;
var
  I: SizeInt;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(AValue) do
  begin
    C := AValue[I];
    case C of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      if Ord(C) < 32 then
        Result := Result + '\u' + IntToHex(Ord(C), 4)
      else
        Result := Result + C;
    end;
  end;
end;

function JsonString(const AValue: string): string;
begin
  Result := '"' + JsonEscape(AValue) + '"';
end;

function JsonBoolean(AValue: Boolean): string;
begin
  if AValue then Result := 'true' else Result := 'false';
end;

function IsoDateTime(AValue: TDateTime): string;
begin
  if AValue <= 0 then Exit('');
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', AValue);
end;

function BuildWeightJson(const ASnapshot: TScaleJsonSnapshot): string;
begin
  Result :=
    '{' +
      '"weight":' + JsonString(ASnapshot.Weight) + ',' +
      '"connected":' + JsonBoolean(ASnapshot.Connected) + ',' +
      '"last_read":' + JsonString(IsoDateTime(ASnapshot.LastRead)) +
    '}';
end;

function BuildStatusJson(const ASnapshot: TScaleJsonSnapshot): string;
begin
  Result :=
    '{' +
      '"connected":' + JsonBoolean(ASnapshot.Connected) + ',' +
      '"weight":' + JsonString(ASnapshot.Weight) + ',' +
      '"last_read":' + JsonString(IsoDateTime(ASnapshot.LastRead)) + ',' +
      '"last_error":' + JsonString(ASnapshot.LastError) + ',' +
      '"discarded_frames":' + IntToStr(Int64(ASnapshot.DiscardedFrames)) + ',' +
      '"ignored_bytes":' + IntToStr(Int64(ASnapshot.IgnoredBytes)) +
    '}';
end;

function BuildConfigJson(const APort: string; ABaudRate, ADataBit, AParity,
  AStopBit, AHttpPort, AWebSocketPort: Integer; const AWebSocketPath: string): string;
begin
  Result :=
    '{' +
      '"serial":{' +
        '"port":' + JsonString(APort) + ',' +
        '"baudrate_index":' + IntToStr(ABaudRate) + ',' +
        '"databit_index":' + IntToStr(ADataBit) + ',' +
        '"parity_index":' + IntToStr(AParity) + ',' +
        '"stopbit_index":' + IntToStr(AStopBit) +
      '},' +
      '"server":{' +
        '"port":' + IntToStr(AHttpPort) + ',' +
        '"websocket_port":' + IntToStr(AWebSocketPort) + ',' +
        '"websocket_path":' + JsonString(AWebSocketPath) +
      '}' +
    '}';
end;

function BuildNotFoundJson(const APath: string): string;
begin
  Result := '{"error":"not_found","path":' + JsonString(APath) + '}';
end;

function BuildCommandResultJson(const ACommand: string; AAccepted: Boolean;
  const AMessage: string): string;
begin
  Result :=
    '{' +
      '"command":' + JsonString(ACommand) + ',' +
      '"accepted":' + JsonBoolean(AAccepted) + ',' +
      '"message":' + JsonString(AMessage) +
    '}';
end;

end.
