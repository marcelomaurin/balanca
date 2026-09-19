unit scalemetrics;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, SyncObjs, scalejson;

type
  TScaleMetricsSnapshot = record
    StartedAt: TDateTime;
    WeightReadings: QWord;
    CommandsQueued: QWord;
    ConnectionAttempts: QWord;
    SuccessfulConnections: QWord;
    Reconnections: QWord;
    Timeouts: QWord;
    SerialErrors: QWord;
    HttpRequests: QWord;
    HttpUnauthorized: QWord;
    WebSocketConnections: QWord;
  end;

  { TScaleMetrics }
  TScaleMetrics = class
  private
    FLock: TCriticalSection;
    FData: TScaleMetricsSnapshot;
  public
    constructor Create;
    destructor Destroy; override;

    procedure IncWeightReadings;
    procedure IncCommandsQueued;
    procedure IncConnectionAttempts;
    procedure IncSuccessfulConnections;
    procedure IncReconnections;
    procedure IncTimeouts;
    procedure IncSerialErrors;
    procedure IncHttpRequests;
    procedure IncHttpUnauthorized;
    procedure IncWebSocketConnections;

    function Snapshot: TScaleMetricsSnapshot;
    function ToJson: string;
  end;

implementation

constructor TScaleMetrics.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FillChar(FData, SizeOf(FData), 0);
  FData.StartedAt := Now;
end;

destructor TScaleMetrics.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TScaleMetrics.IncWeightReadings; begin FLock.Acquire; try Inc(FData.WeightReadings); finally FLock.Release; end; end;
procedure TScaleMetrics.IncCommandsQueued; begin FLock.Acquire; try Inc(FData.CommandsQueued); finally FLock.Release; end; end;
procedure TScaleMetrics.IncConnectionAttempts; begin FLock.Acquire; try Inc(FData.ConnectionAttempts); finally FLock.Release; end; end;
procedure TScaleMetrics.IncSuccessfulConnections; begin FLock.Acquire; try Inc(FData.SuccessfulConnections); finally FLock.Release; end; end;
procedure TScaleMetrics.IncReconnections; begin FLock.Acquire; try Inc(FData.Reconnections); finally FLock.Release; end; end;
procedure TScaleMetrics.IncTimeouts; begin FLock.Acquire; try Inc(FData.Timeouts); finally FLock.Release; end; end;
procedure TScaleMetrics.IncSerialErrors; begin FLock.Acquire; try Inc(FData.SerialErrors); finally FLock.Release; end; end;
procedure TScaleMetrics.IncHttpRequests; begin FLock.Acquire; try Inc(FData.HttpRequests); finally FLock.Release; end; end;
procedure TScaleMetrics.IncHttpUnauthorized; begin FLock.Acquire; try Inc(FData.HttpUnauthorized); finally FLock.Release; end; end;
procedure TScaleMetrics.IncWebSocketConnections; begin FLock.Acquire; try Inc(FData.WebSocketConnections); finally FLock.Release; end; end;

function TScaleMetrics.Snapshot: TScaleMetricsSnapshot;
begin
  FLock.Acquire;
  try
    Result := FData;
  finally
    FLock.Release;
  end;
end;

function TScaleMetrics.ToJson: string;
var
  S: TScaleMetricsSnapshot;
  UptimeSec: QWord;
begin
  S := Snapshot;
  UptimeSec := Trunc((Now - S.StartedAt) * 86400);

  Result :=
    '{' +
      '"started_at":' + JsonString(IsoDateTime(S.StartedAt)) + ',' +
      '"uptime_seconds":' + IntToStr(Int64(UptimeSec)) + ',' +
      '"weight_readings":' + IntToStr(Int64(S.WeightReadings)) + ',' +
      '"commands_queued":' + IntToStr(Int64(S.CommandsQueued)) + ',' +
      '"connection_attempts":' + IntToStr(Int64(S.ConnectionAttempts)) + ',' +
      '"successful_connections":' + IntToStr(Int64(S.SuccessfulConnections)) + ',' +
      '"reconnections":' + IntToStr(Int64(S.Reconnections)) + ',' +
      '"timeouts":' + IntToStr(Int64(S.Timeouts)) + ',' +
      '"serial_errors":' + IntToStr(Int64(S.SerialErrors)) + ',' +
      '"http_requests":' + IntToStr(Int64(S.HttpRequests)) + ',' +
      '"http_unauthorized":' + IntToStr(Int64(S.HttpUnauthorized)) + ',' +
      '"websocket_connections":' + IntToStr(Int64(S.WebSocketConnections)) +
    '}';
end;

end.
