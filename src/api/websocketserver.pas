unit websocketserver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, lNet, IdHashSHA, IdCoderMIME, IdGlobal;

type
  { TWebSocketClient }
  TWebSocketClient = class
  public
    HandshakeDone: Boolean;
    Buffer: AnsiString;
    constructor Create;
  end;

  { TWeightWebSocketServer }
  TWeightWebSocketServer = class
  private
    FClients: TList;

    function HeaderValue(const ARequest, AHeader: string): string;
    function RequestPath(const ARequest: string): string;
    function WebSocketAccept(const AKey: string): string;
    function TextFrame(const APayload: UTF8String): AnsiString;
    procedure RejectClient(ASocket: TLSocket; ACode: Integer; const AText: string);
    function CompleteHandshake(ASocket: TLSocket; AClient: TWebSocketClient): Boolean;
    procedure ProcessFrames(ASocket: TLSocket; AClient: TWebSocketClient);
    procedure RemoveSocket(ASocket: TLSocket);
  public
    constructor Create;
    destructor Destroy; override;

    procedure ClientConnected(ASocket: TLSocket);
    procedure ClientDisconnected(ASocket: TLSocket);
    procedure ClientData(ASocket: TLSocket);
    procedure Broadcast(const APayload: UTF8String);
    function ClientCount: Integer;
  end;

implementation

const
  WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

constructor TWebSocketClient.Create;
begin
  inherited Create;
  HandshakeDone := False;
  Buffer := '';
end;

constructor TWeightWebSocketServer.Create;
begin
  inherited Create;
  FClients := TList.Create;
end;

destructor TWeightWebSocketServer.Destroy;
begin
  FClients.Free;
  inherited Destroy;
end;

function TWeightWebSocketServer.HeaderValue(const ARequest, AHeader: string): string;
var
  Lines: TStringList;
  I, P: Integer;
  Line, Name: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := StringReplace(ARequest, #13#10, LineEnding, [rfReplaceAll]);
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      P := Pos(':', Line);
      if P <= 0 then
        Continue;

      Name := Trim(Copy(Line, 1, P - 1));
      if SameText(Name, AHeader) then
      begin
        Result := Trim(Copy(Line, P + 1, MaxInt));
        Exit;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function TWeightWebSocketServer.RequestPath(const ARequest: string): string;
var
  P1, P2: Integer;
  FirstLine: string;
begin
  Result := '';

  P1 := Pos(#13#10, ARequest);
  if P1 > 0 then
    FirstLine := Copy(ARequest, 1, P1 - 1)
  else
    FirstLine := ARequest;

  if Pos('GET ', UpperCase(FirstLine)) <> 1 then
    Exit;

  P1 := 5;
  P2 := Pos(' HTTP/', UpperCase(FirstLine));
  if P2 <= P1 then
    Exit;

  Result := Copy(FirstLine, P1, P2 - P1);
end;

function TWeightWebSocketServer.WebSocketAccept(const AKey: string): string;
var
  Hash: TIdHashSHA1;
begin
  Hash := TIdHashSHA1.Create;
  try
    Result := TIdEncoderMIME.EncodeBytes(
      Hash.HashString(AKey + WS_GUID, IndyTextEncoding_UTF8)
    );
  finally
    Hash.Free;
  end;
end;

function TWeightWebSocketServer.TextFrame(const APayload: UTF8String): AnsiString;
var
  L: Integer;
begin
  L := Length(APayload);
  Result := #$81;

  if L <= 125 then
    Result := Result + AnsiChar(L)
  else if L <= 65535 then
    Result := Result + #126 + AnsiChar((L shr 8) and $FF) + AnsiChar(L and $FF)
  else
    raise Exception.Create('Payload WebSocket excede 65535 bytes');

  Result := Result + AnsiString(APayload);
end;

procedure TWeightWebSocketServer.RejectClient(ASocket: TLSocket; ACode: Integer;
  const AText: string);
var
  Response: string;
begin
  Response :=
    'HTTP/1.1 ' + IntToStr(ACode) + ' ' + AText + #13#10 +
    'Connection: close' + #13#10 +
    'Content-Length: 0' + #13#10#13#10;
  ASocket.SendMessage(Response);
  ASocket.Disconnect(True);
end;

function TWeightWebSocketServer.CompleteHandshake(ASocket: TLSocket;
  AClient: TWebSocketClient): Boolean;
var
  HeaderEnd: Integer;
  Request, Path, Key, UpgradeValue, ConnectionValue, Response: string;
begin
  Result := False;

  HeaderEnd := Pos(#13#10#13#10, AClient.Buffer);
  if HeaderEnd <= 0 then
    Exit;

  Request := Copy(AClient.Buffer, 1, HeaderEnd + 3);
  Delete(AClient.Buffer, 1, HeaderEnd + 3);

  Path := RequestPath(Request);
  if not (SameText(Path, '/weight') or SameText(Path, '/api/v1/weight')) then
  begin
    RejectClient(ASocket, 404, 'Not Found');
    Exit;
  end;

  Key := HeaderValue(Request, 'Sec-WebSocket-Key');
  UpgradeValue := HeaderValue(Request, 'Upgrade');
  ConnectionValue := HeaderValue(Request, 'Connection');

  if (Key = '') or (not SameText(UpgradeValue, 'websocket')) or
     (Pos('UPGRADE', UpperCase(ConnectionValue)) = 0) then
  begin
    RejectClient(ASocket, 400, 'Bad Request');
    Exit;
  end;

  Response :=
    'HTTP/1.1 101 Switching Protocols' + #13#10 +
    'Upgrade: websocket' + #13#10 +
    'Connection: Upgrade' + #13#10 +
    'Sec-WebSocket-Accept: ' + WebSocketAccept(Key) + #13#10#13#10;

  ASocket.SendMessage(Response);
  AClient.HandshakeDone := True;

  if FClients.IndexOf(ASocket) < 0 then
    FClients.Add(ASocket);

  Result := True;
end;

procedure TWeightWebSocketServer.ProcessFrames(ASocket: TLSocket;
  AClient: TWebSocketClient);
var
  B1, B2, Opcode: Byte;
  Masked: Boolean;
  PayloadLen, HeaderLen, I: Integer;
  Mask: array[0..3] of Byte;
  Payload, PongFrame: AnsiString;
begin
  while Length(AClient.Buffer) >= 2 do
  begin
    B1 := Ord(AClient.Buffer[1]);
    B2 := Ord(AClient.Buffer[2]);
    Opcode := B1 and $0F;
    Masked := (B2 and $80) <> 0;
    PayloadLen := B2 and $7F;
    HeaderLen := 2;

    if PayloadLen = 126 then
    begin
      if Length(AClient.Buffer) < 4 then Exit;
      PayloadLen := (Ord(AClient.Buffer[3]) shl 8) or Ord(AClient.Buffer[4]);
      HeaderLen := 4;
    end
    else if PayloadLen = 127 then
    begin
      // Mensagens gigantes não são necessárias neste endpoint de telemetria.
      ASocket.Disconnect(True);
      Exit;
    end;

    if Masked then
      Inc(HeaderLen, 4);

    if Length(AClient.Buffer) < HeaderLen + PayloadLen then
      Exit;

    if Masked then
    begin
      Mask[0] := Ord(AClient.Buffer[HeaderLen - 3]);
      Mask[1] := Ord(AClient.Buffer[HeaderLen - 2]);
      Mask[2] := Ord(AClient.Buffer[HeaderLen - 1]);
      Mask[3] := Ord(AClient.Buffer[HeaderLen]);
    end;

    Payload := Copy(AClient.Buffer, HeaderLen + 1, PayloadLen);

    if Masked then
      for I := 1 to Length(Payload) do
        Payload[I] := AnsiChar(Ord(Payload[I]) xor Mask[(I - 1) mod 4]);

    Delete(AClient.Buffer, 1, HeaderLen + PayloadLen);

    case Opcode of
      $8:
        begin
          ASocket.Disconnect(True);
          Exit;
        end;
      $9:
        begin
          // Pong com o mesmo payload recebido no ping.
          PongFrame := #$8A + AnsiChar(Length(Payload)) + Payload;
          ASocket.SendMessage(PongFrame);
        end;
    end;
  end;
end;

procedure TWeightWebSocketServer.RemoveSocket(ASocket: TLSocket);
var
  Index: Integer;
begin
  Index := FClients.IndexOf(ASocket);
  if Index >= 0 then
    FClients.Delete(Index);
end;

procedure TWeightWebSocketServer.ClientConnected(ASocket: TLSocket);
begin
  ASocket.UserData := TWebSocketClient.Create;
end;

procedure TWeightWebSocketServer.ClientDisconnected(ASocket: TLSocket);
begin
  RemoveSocket(ASocket);

  if Assigned(ASocket.UserData) then
  begin
    TObject(ASocket.UserData).Free;
    ASocket.UserData := nil;
  end;
end;

procedure TWeightWebSocketServer.ClientData(ASocket: TLSocket);
var
  Data: AnsiString;
  Client: TWebSocketClient;
begin
  if not Assigned(ASocket.UserData) then
    ASocket.UserData := TWebSocketClient.Create;

  Client := TWebSocketClient(ASocket.UserData);

  if ASocket.GetMessage(Data) <= 0 then
    Exit;

  Client.Buffer := Client.Buffer + Data;

  if not Client.HandshakeDone then
  begin
    if not CompleteHandshake(ASocket, Client) then
      Exit;
  end;

  if Client.HandshakeDone and (Client.Buffer <> '') then
    ProcessFrames(ASocket, Client);
end;

procedure TWeightWebSocketServer.Broadcast(const APayload: UTF8String);
var
  I: Integer;
  Socket: TLSocket;
  Frame: AnsiString;
begin
  Frame := TextFrame(APayload);

  for I := FClients.Count - 1 downto 0 do
  begin
    Socket := TLSocket(FClients[I]);
    try
      Socket.SendMessage(Frame);
    except
      RemoveSocket(Socket);
    end;
  end;
end;

function TWeightWebSocketServer.ClientCount: Integer;
begin
  Result := FClients.Count;
end;

end.
