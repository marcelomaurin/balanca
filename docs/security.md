# Segurança da API e WebSocket

A aplicação usa uma política segura por padrão para evitar exposição acidental
da balança na rede.

## Configuração padrão

```ini
[security]
http_bind=127.0.0.1
websocket_bind=127.0.0.1
api_key=
allow_remote_without_api_key=0
commands_enabled=1
```

Com essa configuração, o HTTP fica vinculado ao loopback e o WebSocket aceita
apenas clientes locais.

## Exposição em rede

Para expor o serviço em outras máquinas:

```ini
[security]
http_bind=0.0.0.0
websocket_bind=0.0.0.0
api_key=troque-por-uma-chave-longa-e-aleatoria
allow_remote_without_api_key=0
commands_enabled=1
```

Se um bind não local for configurado sem `api_key`, a API e o handshake
WebSocket recusam o acesso por segurança, exceto se
`allow_remote_without_api_key=1` for definido explicitamente.

## Autenticação HTTP

A chave pode ser enviada por:

```http
X-API-Key: sua-chave
```

ou:

```http
Authorization: Bearer sua-chave
```

Também há suporte a `?api_key=...`, principalmente para clientes simples.
Para produção, prefira header para evitar que a chave apareça em histórico,
logs ou URLs.

Exemplo:

```bash
curl -H "X-API-Key: sua-chave" http://192.168.1.20:8097/api/v1/status
```

Comando:

```bash
curl -X POST   -H "X-API-Key: sua-chave"   http://192.168.1.20:8097/api/v1/commands/read
```

## WebSocket

Com chave:

```javascript
const ws = new WebSocket(
  "ws://192.168.1.20:8098/weight?api_key=sua-chave"
);
```

Clientes que permitem headers podem usar `X-API-Key` ou
`Authorization: Bearer`.

Quando `websocket_bind=127.0.0.1`, clientes não-loopback são rejeitados no
handshake mesmo que a biblioteca TCP subjacente esteja ouvindo de forma mais
ampla.

## Comandos remotos

Os comandos podem ser desligados sem desativar telemetria:

```ini
[security]
commands_enabled=0
```

Nesse modo, requisições POST de comandos retornam HTTP 403.

## API de configuração

`GET /api/v1/config` informa apenas metadados:

```json
{
  "security": {
    "http_bind": "127.0.0.1",
    "websocket_bind": "127.0.0.1",
    "api_key_enabled": true,
    "allow_remote_without_api_key": false,
    "commands_enabled": true
  }
}
```

A chave nunca é retornada pela API.

## Códigos de resposta

- `401`: chave ausente ou inválida;
- `403`: comandos remotos desabilitados;
- `503`: configuração remota insegura, sem chave;
- `404`: rota inexistente.

## Arquivo de configuração

A chave é armazenada no `main.cfg`. Em instalação headless, proteja o arquivo
com permissões do sistema operacional.

Exemplo Linux:

```bash
sudo chown balanca:balanca /etc/balanca/main.cfg
sudo chmod 600 /etc/balanca/main.cfg
```

## HTTPS/WSS

Esta etapa protege autenticação e exposição de rede, mas não adiciona TLS
obrigatório. Em redes não confiáveis, use um reverse proxy TLS ou uma VPN antes
de expor a API. Uma API key enviada por HTTP puro não é criptografada.
