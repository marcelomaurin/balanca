# Arquitetura

## Visão geral

A aplicação está organizada em camadas para separar interface, integração, domínio, transporte e protocolos.

```text
Desktop / UI
   |
   v
TScaleApplication
   |-----------------------------+
   |                             |
   v                             v
TScaleDevice                 TScaleApi
   |                             |
   |                             +---- JSON
   |
   +---- TSerialTransport ---- TLazSerial
   |
   +---- TScaleProtocol
             |
             +---- TToledoProtocol
             +---- futuros drivers

HTTP
  |
  v
TScaleHttpRouter
  |
  v
TScaleApplication

WebSocket
  |
  v
TWeightWebSocketServer

Headless
  |
  v
THeadlessScaleHost
  |
  v
TScaleApplication
```

## TScaleApplication

É a camada de coordenação. Aplica configurações, seleciona o protocolo, conecta/desconecta, processa serial, executa leituras periódicas, processa comandos, supervisiona timeout, executa reconexão automática, publica WebSocket e fornece estado à API.

## TScaleDevice

Representa a balança de forma independente da UI. Coordena transporte e protocolo, armazena último peso/frame/erro, mantém fila de comandos, expõe snapshot operacional e executa comandos suportados pelo driver ativo.

## TSerialTransport

Encapsula `TLazSerial` e concentra configuração serial, conexão, desconexão, leitura e escrita. Nenhuma regra de protocolo deve ficar nessa camada.

## TScaleProtocol

Contrato abstrato dos drivers de balança. Cada driver interpreta bytes, monta comandos, declara capacidades, emite peso e fornece diagnóstico do parser.

Atualmente:

```text
TScaleProtocol
     |
     +---- TToledoProtocol
```

A criação é feita por `TScaleProtocolFactory`.

## TToledoProtocol

Driver Toledo/PRIX compatível com STX/ETX, ENQ, parser byte a byte, frames fragmentados, múltiplos frames, resincronização e contadores de ruído/descarte.

## TScaleHttpRouter

Concentra as rotas HTTP, autenticação, códigos de resposta, comandos e compatibilidade legada.

## TScaleApi

Monta as representações JSON da balança. A geração JSON genérica está separada em `scalejson.pas`.

## TWeightWebSocketServer

Publica peso em tempo real e implementa handshake RFC 6455, autenticação, ping/pong e controle de clientes.

## THeadlessScaleHost

Executa a aplicação sem formulários. Cria serial, aplicação, HTTP, WebSocket, roteador e loop periódico.

## Configuração

A configuração é persistida em `main.cfg` com as seções:

```text
[serial]
[scale]
[reconnect]
[security]
```

## Fluxo de leitura

```text
Timer / serviço
     |
     v
TScaleApplication.Tick
     |
     v
TScaleDevice.RequestWeight
     |
     v
TScaleProtocol.TryEncodeCommand
     |
     v
TSerialTransport.WriteData
     |
  BALANÇA
     |
     v
TLazSerial
     |
     v
TScaleDevice.ProcessIncoming
     |
     v
TScaleProtocol.Feed
     |
     v
OnWeight
     |
     +---- UI
     +---- WebSocket
     +---- API snapshot
```

## Diretriz

A regra principal é: interface e infraestrutura não devem conhecer detalhes de protocolo. Para adicionar um novo fabricante, a alteração deve ficar concentrada em um novo driver derivado de `TScaleProtocol`.
