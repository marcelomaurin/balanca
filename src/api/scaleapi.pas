unit scaleapi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, scaledevice, setmain, scalejson;

type
  { TScaleApi }
  TScaleApi = class
  private
    FDevice: TScaleDevice;
    FSettings: TSetMain;

  public
    constructor Create(ADevice: TScaleDevice; ASettings: TSetMain);

    function WeightJson: string;
    function StatusJson: string;
    function ConfigJson: string;
    function NotFoundJson(const APath: string): string;
    function CommandResultJson(const ACommand: string; AAccepted: Boolean;
      const AMessage: string): string;
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

function TScaleApi.WeightJson: string;
var
  Snapshot: TScaleSnapshot;
  JsonSnapshot: TScaleJsonSnapshot;
begin
  Snapshot := FDevice.GetSnapshot;
  JsonSnapshot.Connected := Snapshot.Connected;
  JsonSnapshot.Weight := Snapshot.LastWeight;
  JsonSnapshot.LastRead := Snapshot.LastRead;
  JsonSnapshot.LastError := Snapshot.LastError;
  JsonSnapshot.DiscardedFrames := Snapshot.DiscardedFrames;
  JsonSnapshot.IgnoredBytes := Snapshot.IgnoredBytes;
  Result := BuildWeightJson(JsonSnapshot);
end;

function TScaleApi.StatusJson: string;
var
  Snapshot: TScaleSnapshot;
  JsonSnapshot: TScaleJsonSnapshot;
begin
  Snapshot := FDevice.GetSnapshot;
  JsonSnapshot.Connected := Snapshot.Connected;
  JsonSnapshot.Weight := Snapshot.LastWeight;
  JsonSnapshot.LastRead := Snapshot.LastRead;
  JsonSnapshot.LastError := Snapshot.LastError;
  JsonSnapshot.DiscardedFrames := Snapshot.DiscardedFrames;
  JsonSnapshot.IgnoredBytes := Snapshot.IgnoredBytes;
  Result := BuildStatusJson(JsonSnapshot);
end;

function TScaleApi.ConfigJson: string;
begin
  Result := BuildConfigJson(
    FSettings.COMPORT,
    FSettings.BAUDRATE,
    FSettings.DATABIT,
    FSettings.PARIDADE,
    FSettings.STOPBIT,
    8097,
    8098,
    '/weight'
  );
end;

function TScaleApi.NotFoundJson(const APath: string): string;
begin
  Result := BuildNotFoundJson(APath);
end;

function TScaleApi.CommandResultJson(const ACommand: string; AAccepted: Boolean;
  const AMessage: string): string;
begin
  Result := BuildCommandResultJson(ACommand, AAccepted, AMessage);
end;

function TScaleApi.LegacyJson: string;
var
  Snapshot: TScaleSnapshot;
begin
  Snapshot := FDevice.GetSnapshot;
  Result := BuildLegacyJson(Snapshot.LastWeight);
end;

end.
