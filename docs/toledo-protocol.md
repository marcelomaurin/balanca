# Parser do protocolo Toledo

O núcleo usa `TToledoProtocol` para reconstruir frames recebidos pela porta
serial.

## Delimitadores

- ENQ: `0x05` — solicitação de leitura;
- STX: `0x02` — início do frame;
- ETX: `0x03` — fim do frame.

Exemplo:

```text
ENQ ->
     <- STX + +001.250 + ETX
```

## Máquina de estados

```text
              STX
WAITING_STX ---------> READING_PAYLOAD
    ^                        |
    |                        | ETX
    +------------------------+
```

### WAITING_STX

Bytes recebidos antes de STX são tratados como ruído e ignorados. Isso inclui
CR/LF deixados por equipamentos ou simuladores que acrescentem final de linha.

### READING_PAYLOAD

Todos os bytes são acumulados até ETX.

Se outro STX chegar antes de ETX, o frame parcial é descartado e o parser usa o
novo STX para se resincronizar.

Se o payload ultrapassar `TOLEDO_MAX_PAYLOAD`, o frame é descartado para evitar
crescimento indefinido do buffer quando houver perda de ETX ou corrupção do
fluxo serial.

## Cenários suportados

O parser aceita:

- frame completo em uma única leitura;
- frame dividido entre várias leituras seriais;
- vários frames na mesma leitura;
- ruído antes/depois de um frame;
- perda de sincronismo seguida de novo STX;
- CR/LF após ETX.

O conteúdo entre STX e ETX é preservado. Nesta camada não são impostas regras
sobre quantidade de casas decimais, sinal ou unidade, evitando rejeitar modelos
Toledo/compatíveis que usem payloads diferentes.

## Diagnóstico

`TToledoProtocol` mantém:

- `LastFrame`;
- `LastPayload`;
- `DiscardedFrames`;
- `IgnoredBytes`.

`TScaleDevice` expõe os contadores de frames descartados e bytes ignorados para
uso futuro na tela de diagnóstico e na API.

## Teste de regressão

O arquivo `tests/toledo_protocol_test.pas` cobre os principais cenários do
parser. Ele pode ser compilado apontando o caminho de units para `src/core`.
