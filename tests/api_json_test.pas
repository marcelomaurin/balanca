program api_json_test;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils, scalejson, testassert;

var
  S: TScaleJsonSnapshot;
  J: string;
begin
  S.Connected := True;
  S.Weight := '+001.250';
  S.LastRead := EncodeDateTime(2026, 9, 19, 11, 30, 0, 0);
  S.LastError := 'erro "serial"';
  S.DiscardedFrames := 2;
  S.IgnoredBytes := 5;

  J := BuildWeightJson(S);
  AssertContains('"weight":"+001.250"', J, 'weight JSON');
  AssertContains('"connected":true', J, 'connected JSON');
  AssertContains('"last_read":"2026-09-19T11:30:00"', J, 'last_read JSON');

  J := BuildStatusJson(S);
  AssertContains('"discarded_frames":2', J, 'discarded_frames JSON');
  AssertContains('"ignored_bytes":5', J, 'ignored_bytes JSON');
  AssertContains('erro \"serial\"', J, 'escape de aspas JSON');

  J := BuildConfigJson('COM13', 3, 0, 0, 0, 8097, 8098, '/weight');
  AssertContains('"port":"COM13"', J, 'config porta');
  AssertContains('"websocket_port":8098', J, 'config WebSocket');

  J := BuildNotFoundJson('/x"y');
  AssertContains('/x\"y', J, 'escape em not_found');

  J := BuildCommandResultJson('read', True, 'queued');
  AssertEquals('{"command":"read","accepted":true,"message":"queued"}',
    J, 'command result');

  J := BuildLegacyJson('+001.250');
  AssertEquals('{"rs":{"peso":"+001.250"}}', J, 'legacy JSON');

  WriteLn('OK - api_json_test');
end.
