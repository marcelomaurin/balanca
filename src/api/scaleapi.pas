unit scaleapi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, scaledevice, setmain;

type
  { TScaleApi }
  TScaleApi = class
  private
    FDevice: TScaleDevice;
    FSettings: TSetMain;

    function JsonEscape(const AValue: string): string;
    function JsonString(const AValue: string): string;
    function JsonBoolean(AValue: Boolean): string;
    function IsoDateTime(AValue: TDateTime): string;
  public
    constructor Create(ADevice: TScaleDevice; ASettings: TSetMain);

    function WeightJson: string;
    function StatusJson: string;
    function ConfigJson: string;
    function NotFoundJson(const APath: string): string;
    function LegacyJson: string;
  end;

implementation

constructor TScaleApi.Create(ADevice: TScaleDevice; ASettings: TSetMain);
begin
  inherited Create;

  if not Assigned(ADevice) then
    raise Exception.Create('Dispositivo da balança não informado à API');

  if not Assigned(ASettings) then
    raise Exception.Create('Configuração não informada à API');

  FDevice := ADevice;
  FSettings := ASettings;
end;

function TScaleApi.JsonEscape(const AValue: string): string;
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

function TScaleApi.JsonString(const AValue: string): string;
begin
  Result := '"' + JsonEscape(AValue) + '"';
end;

function TScaleApi.JsonBoolean(AValue: Boolean): string;
begin
  if AValue then
    Result := 'true'
  else
    Result := 'false';
end;

function TScaleApi.IsoDateTime(AValue: TDateTime): string;
begin
  if AValue <= 0 then
    Exit('');

  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', AValue);
end;

function TScaleApi.WeightJson: string;
begin
  Result :=
    '{' +
      '"weight":' + JsonString(FDevice.LastWeight) + ',' +
      '"connected":' + JsonBoolean(FDevice.IsConnected) + ',' +
      '"last_read":' + JsonString(IsoDateTime(FDevice.LastRead)) +
    '}';
end;

function TScaleApi.StatusJson: string;
begin
  Result :=
    '{' +
      '"connected":' + JsonBoolean(FDevice.IsConnected) + ',' +
      '"weight":' + JsonString(FDevice.LastWeight) + ',' +
      '"last_read":' + JsonString(IsoDateTime(FDevice.LastRead)) + ',' +
      '"last_error":' + JsonString(FDevice.LastError) + ',' +
      '"discarded_frames":' + UIntToStr(FDevice.DiscardedFrames) + ',' +
      '"ignored_bytes":' + UIntToStr(FDevice.IgnoredBytes) +
    '}';
end;

function TScaleApi.ConfigJson: string;
begin
  Result :=
    '{' +
      '"serial":{' +
        '"port":' + JsonString(FSettings.COMPORT) + ',' +
        '"baudrate_index":' + IntToStr(FSettings.BAUDRATE) + ',' +
        '"databit_index":' + IntToStr(FSettings.DATABIT) + ',' +
        '"parity_index":' + IntToStr(FSettings.PARIDADE) + ',' +
        '"stopbit_index":' + IntToStr(FSettings.STOPBIT) +
      '},' +
      '"server":{' +
        '"port":8097' +
      '}' +
    '}';
end;

function TScaleApi.NotFoundJson(const APath: string): string;
begin
  Result :=
    '{' +
      '"error":"not_found",' +
      '"path":' + JsonString(APath) +
    '}';
end;

function TScaleApi.LegacyJson: string;
begin
  Result :=
    '{' +
      '"rs":{' +
        '"peso":' + JsonString(FDevice.LastWeight) +
      '}' +
    '}';
end;

end.
