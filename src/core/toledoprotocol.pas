unit toledoprotocol;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, scalecommands, scaleprotocol, protocolfactory;

const
  TOLEDO_ENQ = #$05;
  TOLEDO_STX = #$02;
  TOLEDO_ETX = #$03;
  TOLEDO_MAX_PAYLOAD = 64;

type
  TToledoParserState = (
    tpsWaitingSTX,
    tpsReadingPayload
  );

  { TToledoProtocol }
  TToledoProtocol = class(TScaleProtocol)
  private
    FBuffer: string;
    FState: TToledoParserState;
    FLastFrame: string;
    FLastPayload: string;
    FDiscardedFrames: QWord;
    FIgnoredBytes: QWord;

    procedure StartFrame;
    procedure DiscardFrame;
    procedure EmitFrame;
    procedure ProcessByte(const AByte: Char);
  public
    constructor Create;

    procedure Reset; override;
    procedure Feed(const AData: string); override;
    function SupportsCommand(ACommand: TScaleCommand): Boolean; override;
    function TryEncodeCommand(ACommand: TScaleCommand;
      out AData: string): Boolean; override;

    function ProtocolId: string; override;
    function DisplayName: string; override;
    function LastFrame: string; override;
    function LastPayload: string; override;
    function DiscardedFrames: QWord; override;
    function IgnoredBytes: QWord; override;

    property State: TToledoParserState read FState;
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

  EmitWeight(FLastPayload);

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

function TToledoProtocol.ProtocolId: string;
begin
  Result := 'toledo';
end;

function TToledoProtocol.DisplayName: string;
begin
  Result := 'Toledo / PRIX compatível';
end;

function TToledoProtocol.LastFrame: string;
begin
  Result := FLastFrame;
end;

function TToledoProtocol.LastPayload: string;
begin
  Result := FLastPayload;
end;

function TToledoProtocol.DiscardedFrames: QWord;
begin
  Result := FDiscardedFrames;
end;

function TToledoProtocol.IgnoredBytes: QWord;
begin
  Result := FIgnoredBytes;
end;

initialization
  TScaleProtocolFactory.RegisterProtocol('toledo', TToledoProtocol);
  TScaleProtocolFactory.RegisterProtocol('prix3', TToledoProtocol);
  TScaleProtocolFactory.RegisterProtocol('toledo-prix3', TToledoProtocol);

end.
