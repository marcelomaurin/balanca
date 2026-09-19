# Configuração da aplicação

A configuração é armazenada em `main.cfg`, no diretório retornado por `GetAppConfigDir(False)` ou no diretório informado por `--config-dir` no modo headless.

O arquivo usa formato INI por meio de `TIniFile`.

## Exemplo completo

```ini
[geral]
device=0
hide=0
exec=0
splash=0

[janela]
posx=100
posy=100

[serial]
comport=COM13
baudrate=3
databit=0
paridade=0
stopbit=0

[scale]
protocol=toledo

[reconnect]
enabled=1
response_timeout_ms=3000
initial_delay_ms=1000
max_delay_ms=30000

[security]
http_bind=127.0.0.1
websocket_bind=127.0.0.1
api_key=
allow_remote_without_api_key=0
commands_enabled=1

[logging]
level=info
file=balanca.log
console=0

[legado]
empresa=maurinsoft
localizacao=nothing
tipo1=Normal
tipo2=Idoso
tipo3=Especial
contagem1=0
contagem2=0
contagem3=0
painel=192.168.0.108
tipoimp=0
modeloimp=0
```

No Linux, o valor padrão da porta serial é `/dev/ttyS0`.

## Seção [serial]

Os valores de baud rate, data bits, paridade e stop bits continuam armazenados como índices compatíveis com `TLazSerial`, preservando a configuração histórica do projeto.

## Seção [scale]

Seleciona o driver de protocolo:

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

## Seção [reconnect]

Configura a supervisão da conexão:

- `enabled`: habilita reconexão automática;
- `response_timeout_ms`: tempo máximo sem frame válido;
- `initial_delay_ms`: atraso da primeira tentativa;
- `max_delay_ms`: teto do backoff.

## Seção [security]

Configura exposição de rede e autenticação:

- `http_bind`: endereço HTTP;
- `websocket_bind`: política de bind WebSocket;
- `api_key`: chave opcional;
- `allow_remote_without_api_key`: permite explicitamente acesso remoto sem chave;
- `commands_enabled`: habilita/desabilita comandos POST.

O padrão é local-only (`127.0.0.1`).

## Seção [logging]

Configura observabilidade:

- `level`: `debug`, `info`, `warn` ou `error`;
- `file`: arquivo de log;
- `console`: também envia logs para stdout/stderr.

## Migração automática

Versões antigas gravavam o arquivo assim:

```text
DEVICE:0
POSX:100
POSY:100
COMPORT:COM13
BAUDRATE:3
```

Ao iniciar:

1. a aplicação detecta se o arquivo possui seções INI;
2. se for formato antigo, carrega os pares `CHAVE:valor`;
3. valores inválidos usam o valor padrão em vez de provocar exceção;
4. o arquivo é regravado automaticamente no formato INI.

## Segurança de leitura

Campos ausentes usam valores padrão. Inteiros legados usam `TryStrToInt`, e booleanos antigos são interpretados de forma tolerante.

## Organização

- `geral`: comportamento geral;
- `janela`: posição da interface;
- `serial`: comunicação serial;
- `scale`: protocolo da balança;
- `reconnect`: resiliência da conexão;
- `security`: exposição de rede e autenticação;
- `logging`: nível e destinos de log;
- `legado`: campos históricos mantidos temporariamente.
