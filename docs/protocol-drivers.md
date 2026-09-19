# Drivers de protocolo de balança

O núcleo não depende mais diretamente do protocolo Toledo.

## Arquitetura

```text
TScaleDevice
     |
     v
TScaleProtocol (abstrato)
     |
     +---- TToledoProtocol
     |
     +---- futuros drivers
```

A criação dos drivers é feita por:

```text
TScaleProtocolFactory
```

## Configuração

O protocolo é selecionado em `main.cfg`:

```ini
[scale]
protocol=toledo
```

Aliases atualmente registrados:

```text
toledo
prix3
toledo-prix3
```

Os três selecionam o mesmo driver Toledo/PRIX compatível já existente no
projeto.

## Contrato TScaleProtocol

Um driver deve implementar:

```pascal
procedure Reset;
procedure Feed(const AData: string);

function SupportsCommand(ACommand: TScaleCommand): Boolean;
function TryEncodeCommand(ACommand: TScaleCommand;
  out AData: string): Boolean;

function ProtocolId: string;
function DisplayName: string;
function LastFrame: string;
function LastPayload: string;
function DiscardedFrames: QWord;
function IgnoredBytes: QWord;
```

O evento de peso é emitido pelo método protegido:

```pascal
EmitWeight(AWeight);
```

## Registro de um novo driver

Exemplo estrutural:

```pascal
unit fabricantexprotocol;

interface

uses
  scaleprotocol, protocolfactory, scalecommands;

type
  TFabricanteXProtocol = class(TScaleProtocol)
  public
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
  end;

implementation

initialization
  TScaleProtocolFactory.RegisterProtocol(
    'fabricante-x',
    TFabricanteXProtocol
  );

end.
```

Depois:

```ini
[scale]
protocol=fabricante-x
```

Nenhuma alteração é necessária em:

- `TScaleDevice`;
- `TScaleApplication`;
- API HTTP;
- WebSocket;
- interface gráfica;
- modo headless.

## Segurança contra protocolo desconhecido

Se for configurado:

```ini
[scale]
protocol=nao-existe
```

a fábrica gera erro explícito:

```text
Protocolo não registrado: nao-existe
```

A política de reconexão continuará tentando, mas não enviará bytes de um
protocolo incorreto ao equipamento.

## Toledo

O driver atual permanece em:

```text
src/core/toledoprotocol.pas
```

Ele mantém:

- framing STX/ETX;
- resincronização;
- contadores de descarte/ruído;
- leitura por ENQ;
- comandos suportados declarados explicitamente.

## API

`GET /api/v1/config` informa:

```json
{
  "scale": {
    "protocol": "toledo",
    "protocol_name": "Toledo / PRIX compatível"
  }
}
```

`GET /api/v1/status` também informa o driver ativo:

```json
{
  "protocol": {
    "id": "toledo",
    "name": "Toledo / PRIX compatível"
  }
}
```

## Diretriz para novos fabricantes

Um protocolo só deve ser implementado quando houver documentação confiável ou
captura validada do equipamento real.

Não deve ser inferido um comando de tara, zero, impressão ou framing com base em
similaridade com outro fabricante.
