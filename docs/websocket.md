# WebSocket de peso em tempo real

A aplicação disponibiliza um servidor WebSocket separado do HTTP.

- HTTP API: porta `8097`
- WebSocket: porta `8098`
- caminho principal: `/weight`
- caminho alternativo: `/api/v1/weight`

Exemplo:

```text
ws://localhost:8098/weight
```

## Mensagens

A cada nova leitura válida recebida da balança, o servidor envia um frame de
texto JSON com o mesmo formato de `GET /api/v1/weight`:

```json
{
  "weight": "+001.250",
  "connected": true,
  "last_read": "2026-09-19T11:30:00"
}
```

O servidor não faz polling para cada cliente. A leitura serial ocorre uma vez e
a atualização é distribuída para todos os clientes WebSocket conectados.

## Cliente JavaScript

```javascript
const ws = new WebSocket("ws://localhost:8098/weight");

ws.onopen = () => {
  console.log("WebSocket conectado");
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log("Peso:", data.weight);
};

ws.onclose = () => {
  console.log("WebSocket desconectado");
};
```

## Handshake

O servidor implementa o handshake RFC 6455:

1. recebe `Sec-WebSocket-Key`;
2. concatena o GUID padrão WebSocket;
3. calcula SHA-1;
4. codifica o hash em Base64;
5. responde HTTP `101 Switching Protocols`.

São aceitos apenas os caminhos `/weight` e `/api/v1/weight`.

## Frames

O servidor:

- envia frames de texto não mascarados, conforme RFC 6455;
- suporta payload de texto de até 65535 bytes;
- responde a frames `ping` com `pong`;
- trata frames `close`;
- aceita frames mascarados enviados pelo cliente;
- remove o cliente da lista ao desconectar.

## Arquitetura

```text
Balança serial
     |
     v
TScaleDevice
     |
     +---- HTTP /api/v1/weight
     |
     +---- OnWeight
             |
             v
      TWeightWebSocketServer
          |     |     |
       cliente cliente cliente
```

O WebSocket reutiliza o componente `TLTCPComponent` que já fazia parte do
projeto, evitando uma nova dependência de rede.

A API `GET /api/v1/config` também informa:

```json
{
  "server": {
    "port": 8097,
    "websocket_port": 8098,
    "websocket_path": "/weight"
  }
}
```
