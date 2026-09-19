# Balança

![CI](https://github.com/marcelomaurin/balanca/actions/workflows/ci.yml/badge.svg)

Projeto para leitura de balanças seriais, originalmente desenvolvido para equipamentos Toledo/PRIX compatíveis, com aplicação desktop em Lazarus/Free Pascal, API HTTP, WebSocket em tempo real, modo headless e simulador Arduino.

O projeto foi reorganizado para separar interface, transporte serial, protocolo, API e serviço. A arquitetura atual também permite adicionar novos protocolos de balança sem alterar o núcleo principal.

## Funcionalidades

- leitura serial de peso;
- protocolo Toledo/PRIX compatível;
- parser robusto STX/ETX;
- reconexão automática;
- API HTTP JSON;
- WebSocket de peso em tempo real;
- comandos padronizados;
- segurança por API key;
- bind local por padrão;
- execução desktop;
- execução headless;
- serviço Linux com systemd;
- inicialização automática no Windows;
- simulador Arduino;
- modos de falha para teste;
- suíte de testes FPC;
- arquitetura multi-protocolo;
- logging estruturado e métricas operacionais.

## Arquitetura

```text
                 +--------------------+
                 |   Desktop / UI     |
                 |      Tfrmmain      |
                 +---------+----------+
                           |
                           v
                 +--------------------+
                 | TScaleApplication  |
                 +----+----------+----+
                      |          |
                      |          +-------------------+
                      v                              v
              +---------------+              +-------------+
              | TScaleDevice  |              | TScaleApi   |
              +-------+-------+              +-------------+
                      |
          +-----------+------------+
          |                        |
          v                        v
+-------------------+     +-------------------+
| TSerialTransport  |     | TScaleProtocol    |
|    TLazSerial     |     |   abstrato        |
+-------------------+     +---------+---------+
                                    |
                                    v
                           +-------------------+
                           | TToledoProtocol   |
                           +-------------------+

HTTP 8097  -> TScaleHttpRouter
WebSocket 8098 -> TWeightWebSocketServer

Headless:
THeadlessScaleHost -> TScaleApplication
```

## Estrutura do repositório

```text
src/
  api/
    httprouter.pas
    scaleapi.pas
    scalejson.pas
    websocketserver.pas

  app/
    scaleapplication.pas

  core/
    protocolfactory.pas
    scalecommands.pas
    scaleconfig.pas
    scaledevice.pas
    scaleprotocol.pas
    serialtransport.pas
    simulatorcommands.pas
    toledoprotocol.pas

  service/
    balanca_service.lpr
    balanca_service.lpi
    headlesshost.pas

simulator/
  arduino/
    balanca/
      balanca.ino

tests/
docs/
instalador/
```

## Configuração

O arquivo principal é:

```text
main.cfg
```

Exemplo:

```ini
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
```

O formato legado `CHAVE:valor` ainda pode ser lido e é migrado automaticamente para INI.

## Protocolos

O protocolo padrão é:

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

Todos apontam para o driver Toledo/PRIX compatível.

Novos protocolos devem implementar `TScaleProtocol` e ser registrados em `TScaleProtocolFactory`.

Veja [docs/protocol-drivers.md](docs/protocol-drivers.md).

## API HTTP

Porta padrão:

```text
8097
```

Principais endpoints:

```text
GET  /api/v1/weight
GET  /api/v1/status
GET  /api/v1/config
GET  /api/v1/metrics

POST /api/v1/commands/read
POST /api/v1/commands/tare
POST /api/v1/commands/zero
POST /api/v1/commands/print
POST /api/v1/commands/continuous_start
POST /api/v1/commands/continuous_stop
```

Nem todos os comandos são necessariamente suportados pelo protocolo ativo. Atualmente, no driver Toledo, somente `read` está confirmado e habilitado.

Exemplo:

```bash
curl http://127.0.0.1:8097/api/v1/status
```

Com API key:

```bash
curl -H "X-API-Key: sua-chave" \
  http://127.0.0.1:8097/api/v1/status
```

Veja [docs/api.md](docs/api.md) e [docs/security.md](docs/security.md).

## WebSocket

Porta padrão:

```text
8098
```

Endpoint:

```text
ws://127.0.0.1:8098/weight
```

Cada nova leitura válida é transmitida automaticamente aos clientes conectados.

Exemplo JavaScript:

```javascript
const ws = new WebSocket("ws://127.0.0.1:8098/weight");

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log(data.weight);
};
```

Com chave:

```javascript
const ws = new WebSocket(
  "ws://192.168.1.20:8098/weight?api_key=sua-chave"
);
```

Veja [docs/websocket.md](docs/websocket.md).

## Reconexão automática

A aplicação monitora a ausência de resposta da balança e tenta restabelecer a conexão.

Backoff padrão:

```text
1 s
2 s
4 s
8 s
16 s
30 s
30 s...
```

O estado pode ser consultado em:

```text
GET /api/v1/status
```

Veja [docs/reconnection.md](docs/reconnection.md).

## Segurança

Por padrão:

```ini
[security]
http_bind=127.0.0.1
websocket_bind=127.0.0.1
api_key=
allow_remote_without_api_key=0
commands_enabled=1
```

Para exposição remota, configure uma API key.

A chave nunca é retornada pela API.

Veja [docs/security.md](docs/security.md).

## Desktop

O projeto principal Lazarus é:

```text
src/balanca.lpi
```

Compilação:

```bash
lazbuild src/balanca.lpi
```

A interface gráfica atua como cliente da camada `TScaleApplication`.

Veja [docs/ui-decoupling.md](docs/ui-decoupling.md).

## Modo headless

Projeto:

```text
src/service/balanca_service.lpi
```

Compilação:

```bash
lazbuild src/service/balanca_service.lpi
```

Execução:

```bash
./balanca_service --config-dir=/etc/balanca
```

Serviços:

```text
HTTP      8097
WebSocket 8098
```

Veja [docs/headless-service.md](docs/headless-service.md).

## Linux / systemd

Arquivos:

```text
instalador/linux/balanca.service
instalador/linux/install-service.sh
```

Instalação:

```bash
sudo sh instalador/linux/install-service.sh ./balanca_service
sudo systemctl start balanca
sudo systemctl status balanca
```

Logs:

```bash
journalctl -u balanca -f
```

## Windows headless

Arquivos:

```text
instalador/windows/run-headless.bat
instalador/windows/install-headless-task.ps1
```

O PowerShell instala uma tarefa no Agendador de Tarefas para execução automática no boot.

## Simulador Arduino

O simulador está em:

```text
simulator/arduino/balanca/balanca.ino
```

Comunicação padrão:

```text
2400 baud
ENQ -> solicitação de leitura
STX + peso + ETX -> resposta
```

Comandos exclusivos do simulador:

```text
T = tara
P = limpa acumulado
Z = zera tara
C = alterna contínuo
N = próximo peso
M = alterna modo automático
```

Veja [docs/simulator-arduino.md](docs/simulator-arduino.md).

## Modos de falha

O simulador permite testar cenários de erro:

```text
F0 = normal
F1 = ETX ausente
F2 = ruído serial
F3 = frame truncado
F4 = resposta atrasada
F5 = peso instável
F6 = silêncio / sem resposta
```

Veja [docs/simulator-failures.md](docs/simulator-failures.md).

## Testes

A suíte está em:

```text
tests/
```

Linux:

```bash
cd tests
sh run_all.sh
```

Windows:

```bat
cd tests
run_all.bat
```

A suíte cobre:

- parser Toledo;
- comandos;
- configuração;
- migração para INI;
- geração JSON;
- seleção/fábrica de protocolos.

Veja [tests/README.md](tests/README.md).

## CI/CD

O GitHub Actions valida automaticamente a suíte FPC em Linux e Windows, além de verificar a estrutura do repositório.

O build Lazarus completo fica em um workflow manual separado por depender de pacotes externos do IDE. Tags `v*` geram um pacote de código-fonte validado pelos testes.

Veja [docs/ci-cd.md](docs/ci-cd.md).

## Logging e observabilidade

Logs estruturados e métricas operacionais estão disponíveis para desktop e modo headless.

Endpoint:

```text
GET /api/v1/metrics
```

Veja [docs/observability.md](docs/observability.md).

## Compatibilidade

As rotas:

```text
/
 /legacy
```

preservam o formato histórico para consumidores antigos.

## Documentação

Índice completo:

[docs/README.md](docs/README.md)

## Status do projeto

A arquitetura atual está preparada para:

- novos drivers de balança;
- execução sem interface;
- integração com sistemas web;
- telemetria em tempo real;
- testes automatizados;
- operação resiliente com reconexão;
- implantação como serviço.

## Licença e autoria

Consulte os arquivos do repositório para informações de licença e autoria.
