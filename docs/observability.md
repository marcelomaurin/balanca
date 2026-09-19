# Logging e observabilidade

O projeto possui uma camada de observabilidade independente da interface gráfica.

## Logger

Unit:

```text
src/observability/applogger.pas
```

Níveis disponíveis:

```text
DEBUG
INFO
WARN
ERROR
```

Formato:

```text
2026-09-19T13:10:15.123 [INFO] [connection] Conectado em COM13
```

Categorias atualmente usadas:

- `application`
- `connection`
- `serial`
- `command`
- `http`
- `websocket`
- `weight`
- `security`
- `service`

## Configuração

```ini
[logging]
level=info
file=/caminho/balanca.log
console=0
```

No modo headless, a saída de console é forçada para facilitar integração com systemd/journalctl.

## Métricas

Unit:

```text
src/observability/scalemetrics.pas
```

Contadores disponíveis:

- `weight_readings`
- `commands_queued`
- `connection_attempts`
- `successful_connections`
- `reconnections`
- `timeouts`
- `serial_errors`
- `http_requests`
- `http_unauthorized`
- `websocket_connections`
- `uptime_seconds`

## Endpoint

```text
GET /api/v1/metrics
```

Exemplo:

```json
{
  "started_at": "2026-09-19T13:00:00",
  "uptime_seconds": 615,
  "weight_readings": 1200,
  "commands_queued": 4,
  "connection_attempts": 2,
  "successful_connections": 2,
  "reconnections": 1,
  "timeouts": 1,
  "serial_errors": 0,
  "http_requests": 250,
  "http_unauthorized": 3,
  "websocket_connections": 5
}
```

O endpoint segue a mesma política de autenticação da API.

## Status

`GET /api/v1/status` também inclui o bloco `metrics`, permitindo consultar estado e métricas em uma chamada.

## Parser

Os contadores `discarded_frames` e `ignored_bytes` são copiados para o snapshot sob lock, evitando leitura inconsistente em arquiteturas 32 bits.

## Headless

No Linux com systemd:

```bash
journalctl -u balanca -f
```

Os mesmos eventos também podem ser gravados no arquivo configurado em `[logging]`.

## Testes

Os testes incluem:

```text
tests/logger_test.pas
tests/metrics_test.pas
```

e fazem parte de `run_all.sh` e `run_all.bat`.
