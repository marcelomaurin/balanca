# API HTTP v1

O servidor HTTP permanece na porta `8097`.

## GET /api/v1/weight

Retorna o último peso válido conhecido.

Exemplo:

```json
{
  "weight": "+001.250",
  "connected": true,
  "last_read": "2026-09-19T11:30:00"
}
```

## GET /api/v1/status

Retorna o estado operacional da balança e do parser.

Exemplo:

```json
{
  "connected": true,
  "weight": "+001.250",
  "last_read": "2026-09-19T11:30:00",
  "last_error": "",
  "discarded_frames": 0,
  "ignored_bytes": 2
}
```

## GET /api/v1/config

Retorna a configuração serial atualmente cadastrada.

Exemplo:

```json
{
  "serial": {
    "port": "COM13",
    "baudrate_index": 3,
    "databit_index": 0,
    "parity_index": 0,
    "stopbit_index": 0
  },
  "server": {
    "port": 8097
  }
}
```

Os valores de baud rate, data bits, paridade e stop bits permanecem como índices
dos enums usados por `TLazSerial`, preservando compatibilidade com a configuração
existente.

## Compatibilidade

As rotas `/` e `/legacy` preservam o formato histórico da aplicação:
HTML contendo o objeto:

```json
{"rs":{"peso":"+001.250"}}
```

Isso permite migrar consumidores antigos gradualmente para a API v1.

## Erros

Rotas inexistentes retornam HTTP 404 com JSON:

```json
{
  "error": "not_found",
  "path": "/rota/inexistente"
}
```

Todas as rotas `/api/v1/*` usam `Content-Type: application/json; charset=utf-8`.
