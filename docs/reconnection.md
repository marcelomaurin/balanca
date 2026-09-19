# Reconexão automática

A aplicação possui um supervisor de conexão na camada `TScaleApplication`.

## Objetivo

O processo diferencia:

- intenção do usuário de manter a balança ativa;
- estado atual da porta serial;
- disponibilidade real de respostas da balança.

Assim, uma queda física da serial ou ausência de resposta não equivale a um
desligamento manual.

## Estados

O supervisor trabalha com:

```text
stopped
connecting
connected
waiting_reconnect
```

## Timeout de resposta

Depois que a porta serial é aberta, a aplicação espera leituras válidas.

Se nenhuma leitura válida for recebida dentro de:

```ini
[reconnect]
response_timeout_ms=3000
```

a conexão é considerada degradada, a serial é fechada e entra em reconexão.

O modo de falha `F6` do simulador pode ser usado para testar esse cenário.

## Backoff

As tentativas usam atraso progressivo.

Configuração padrão:

```ini
[reconnect]
enabled=1
response_timeout_ms=3000
initial_delay_ms=1000
max_delay_ms=30000
```

Sequência típica:

```text
1 s
2 s
4 s
8 s
16 s
30 s
30 s
...
```

Ao restabelecer a conexão, o contador volta para zero.

## Erros tratados

A reconexão é acionada quando ocorre:

- falha ao abrir a porta;
- exceção durante leitura serial;
- exceção ao enviar comando;
- ausência de resposta válida dentro do timeout.

## Desconexão manual

Quando o usuário clica em desconectar ou o serviço executa `Disconnect`,
`DesiredActive` passa para falso.

Nesse estado não há tentativa automática de reconexão.

## Desktop

Na interface gráfica:

- `Conectando...` durante tentativa;
- `Conectado` em operação;
- `Reconectando...` durante backoff;
- `Desconectado` após parada manual.

HTTP e WebSocket podem continuar ativos durante a reconexão.

## Headless

O serviço registra transições como:

```text
conexao: connecting - Conectando em /dev/ttyUSB0
conexao: waiting_reconnect - Timeout sem resposta da balança - nova tentativa em 1000 ms
conexao: connecting - Conectando em /dev/ttyUSB0
conexao: connected - Conectado em /dev/ttyUSB0
```

## API

`GET /api/v1/status` agora inclui o supervisor:

```json
{
  "connected": false,
  "weight": "+001.250",
  "last_read": "2026-09-19T11:30:00",
  "last_error": "",
  "discarded_frames": 0,
  "ignored_bytes": 0,
  "supervisor": {
    "desired_active": true,
    "auto_reconnect": true,
    "state": "waiting_reconnect",
    "message": "Timeout sem resposta da balança - nova tentativa em 1000 ms",
    "reconnect_attempts": 1,
    "response_timeout_ms": 3000
  }
}
```

## Teste com simulador

1. iniciar em `F0`;
2. conectar normalmente;
3. enviar `F6`;
4. aguardar o timeout;
5. observar estado `waiting_reconnect`;
6. enviar `F0`;
7. aguardar nova tentativa;
8. confirmar retorno para `connected`.

Também podem ser usados `F4` e os demais modos para validar tolerância a atraso
e corrupção.
