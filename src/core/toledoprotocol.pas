unit toledoprotocol;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, scalecommands;

const
  TOLEDO_ENQ = #$05;
  TOLEDO_STX = #$02;
  TOLEDO_ETX = #$03;
  TOLEDO_MAX_PAYLOAD = 64;

type
  TWeightEvent = procedure(Sender: TObject; const AWeight: string) of object;

  TToledoParserState = (
    tpsWaitingSTX,
    tpsReadingPayload
  );

  { TToledoProtocol }
  TToledoProtocol = class
  private
    FBuffer: string;
    FState: TToledoParserState;
    FLastFrame: string;
    FLastPayload: string;
    FDiscardedFrames: QWord;
    FIgnoredBytes: QWord;
    FOnWeight: TWeightEvent;

    procedure StartFrame;
    procedure DiscardFrame;
    procedure EmitFrame;
    procedure ProcessByte(const AByte: Char);
  public
    constructor Create;

    procedure Reset;
    procedure Feed(const AData: string);
    function SupportsCommand(ACommand: TScaleCommand): Boolean;
    function TryEncodeCommand(ACommand: TScaleCommand; out AData: string): Boolean;

    property State: TToledoParserState read FState;
    property LastFrame: string read FLastFrame;
    property LastPayload: string read FLastPayload;
    property DiscardedFrames: QWord read FDiscardedFrames;
    property IgnoredBytes: QWord read FIgnoredBytes;
    property OnWeight: TWeightEvent read FOnWeight write FOnWeight;
  end;

implementation

constructor TToledoProtocol.Create;
begin
  inherited Create;
  FDiscardedFrames := 0;
  FIgnoredBytes := 0;
  Reset;
end;

procedure TToledoProtocol.Reset;
begin
  FBuffer := '';
  FState := tpsWaitingSTX;
end;

procedure TToledoProtocol.StartFrame;
begin
  FBuffer := '';
  FState := tpsReadingPayload;
end;

procedure TToledoProtocol.DiscardFrame;
begin
  Inc(FDiscardedFrames);
  FBuffer := '';
  FState := tpsWaitingSTX;
end;

procedure TToledoProtocol.EmitFrame;
begin
  FLastPayload := FBuffer;
  FLastFrame := TOLEDO_STX + FBuffer + TOLEDO_ETX;

  if Assigned(FOnWeight) then
    FOnWeight(Self, FLastPayload);

  FBuffer := '';
  FState := tpsWaitingSTX;
end;

procedure TToledoProtocol.ProcessByte(const AByte: Char);
begin
  case FState of
    tpsWaitingSTX:
      begin
        if AByte = TOLEDO_STX then
          StartFrame
        else
          Inc(FIgnoredBytes);
      end;

    tpsReadingPayload:
      begin
        if AByte = TOLEDO_STX then
        begin
          // Um novo STX antes do ETX indica perda de sincronismo.
          // Descarta o frame parcial e usa o novo STX como início.
          if FBuffer <> '' then
            Inc(FDiscardedFrames);
          StartFrame;
        end
        else if AByte = TOLEDO_ETX then
        begin
          if FBuffer = '' then
            DiscardFrame
          else
            EmitFrame;
        end
        else
        begin
          FBuffer := FBuffer + AByte;

          // Proteção contra frame sem ETX ou fluxo serial corrompido.
          if Length(FBuffer) > TOLEDO_MAX_PAYLOAD then
            DiscardFrame;
        end;
      end;
  end;
end;

procedure TToledoProtocol.Feed(const AData: string);
var
  I: SizeInt;
begin
  for I := 1 to Length(AData) do
    ProcessByte(AData[I]);
end;

function TToledoProtocol.SupportsCommand(ACommand: TScaleCommand): Boolean;
begin
  // Neste projeto, somente a leitura via ENQ está confirmada para o
  // equipamento Toledo/compatível. Outros comandos permanecem padronizados
  // no núcleo, mas não são enviados sem confirmação do protocolo.
  Result := ACommand = scReadWeight;
end;

function TToledoProtocol.TryEncodeCommand(ACommand: TScaleCommand;
  out AData: string): Boolean;
begin
  AData := '';
  Result := SupportsCommand(ACommand);

  if not Result then
    Exit;

  case ACommand of
    scReadWeight: AData := TOLEDO_ENQ;
  end;
end;

end.
