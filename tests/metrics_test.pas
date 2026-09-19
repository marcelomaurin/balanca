program metrics_test;

{$mode objfpc}{$H+}

uses
  SysUtils, scalemetrics, testassert;

var
  M: TScaleMetrics;
  J: string;
begin
  M := TScaleMetrics.Create;
  try
    M.IncWeightReadings;
    M.IncWeightReadings;
    M.IncCommandsQueued;
    M.IncConnectionAttempts;
    M.IncSuccessfulConnections;
    M.IncReconnections;
    M.IncTimeouts;
    M.IncSerialErrors;
    M.IncHttpRequests;
    M.IncHttpUnauthorized;
    M.IncWebSocketConnections;

    J := M.ToJson;
    AssertContains('"weight_readings":2', J, 'weight_readings');
    AssertContains('"commands_queued":1', J, 'commands_queued');
    AssertContains('"connection_attempts":1', J, 'connection_attempts');
    AssertContains('"successful_connections":1', J, 'successful_connections');
    AssertContains('"reconnections":1', J, 'reconnections');
    AssertContains('"timeouts":1', J, 'timeouts');
    AssertContains('"serial_errors":1', J, 'serial_errors');
    AssertContains('"http_requests":1', J, 'http_requests');
    AssertContains('"http_unauthorized":1', J, 'http_unauthorized');
    AssertContains('"websocket_connections":1', J, 'websocket_connections');
    AssertContains('"uptime_seconds":', J, 'uptime_seconds');
  finally
    M.Free;
  end;

  WriteLn('OK - metrics_test');
end.
