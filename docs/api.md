# API HTTP v1

O servidor HTTP usa por padrão a porta `8097` e bind `127.0.0.1`.

Consulte [security.md](security.md) antes de expor a API em rede.

## Autenticação

Quando `api_key` estiver configurada, use preferencialmente:

```http
X-API-Key: sua-chave
```

Também são aceitos:

```http
Authorization: Bearer sua-chave
```

e, para clientes simples:

```text
?api_key=sua-chave
```

## GET /api/v1/weight

Retorna o último peso válido:

```json
{
  "weight": "+001.250",
  "connected": true,
  "last_read": "2026-09-19T11:30:00"
}
```

## GET /api/v1/status

Retorna estado da balança, parser, protocolo e supervisor.

Exemplo resumido:

```json
{
  "connected": true,
  "weight": "+001.250",
  "last_read": "2026-09-19T11:30:00",
  "last_error": "",
  "discarded_frames": 0,
  "ignored_bytes": 2,
  "protocol": {
    "id": "toledo",
    "name": "Toledo / PRIX compatível"
  },
  "supervisor": {
    "desired_active": true,
    "auto_reconnect": true,
    "state": "connected",
    "message": "Conectado em COM13",
    "reconnect_attempts": 0,
    "response_timeout_ms": 3000
  }
}
```

## GET /api/v1/metrics

Retorna métricas operacionais cumulativas da aplicação, incluindo leituras, comandos, tentativas de conexão, reconexões, timeouts, erros seriais, requisições HTTP e conexões WebSocket.

O endpoint usa a mesma autenticação da API.

## GET /api/v1/config

Retorna configuração pública do serviço. A API não retorna o valor da chave.

Exemplo resumido:

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
    "port": 8097,
    "websocket_port": 8098,
    "websocket_path": "/weight"
  },
  "scale": {
    "protocol": "toledo",
    "protocol_name": "Toledo / PRIX compatível"
  },
  "security": {
    "http_bind": "127.0.0.1",
    "websocket_bind": "127.0.0.1",
    "api_key_enabled": false,
    "allow_remote_without_api_key": false,
    "commands_enabled": true
  }
}
```

## POST /api/v1/commands/read

Solicita uma leitura.

Resposta quando enfileirado:

```json
{
  "command": "read",
  "accepted": true,
  "message": "queued"
}
```

## Outros comandos

Rotas padronizadas:

```text
POST /api/v1/commands/tare
POST /api/v1/commands/zero
POST /api/v1/commands/print
POST /api/v1/commands/continuous_start
POST /api/v1/commands/continuous_stop
```

O fato de a rota existir não significa que o driver ativo suporte o comando. No driver Toledo atual, apenas `read` está confirmado.

Quando o comando não é suportado, a resposta é HTTP `501`.

## Códigos relevantes

- `200`: consulta executada;
- `202`: comando aceito;
- `401`: API key inválida ou ausente;
- `403`: comandos remotos desabilitados;
- `404`: rota/comando inexistente;
- `405`: método HTTP incorreto;
- `409`: balança indisponível;
- `501`: comando não suportado pelo protocolo;
- `503`: configuração de segurança remota inválida.

## Compatibilidade legada

As rotas `/` e `/legacy` mantêm a resposta histórica em HTML contendo:

```json
{"rs":{"peso":"+001.250"}}
```

Isso permite migrar aplicações antigas gradualmente.
