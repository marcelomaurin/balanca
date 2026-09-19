# Modo headless / serviço

O projeto possui um executável separado para operação sem interface gráfica:

```text
src/service/balanca_service.lpr
src/service/balanca_service.lpi
```

Ele reutiliza o mesmo núcleo da aplicação desktop:

```text
THeadlessScaleHost
      |
      v
TScaleApplication
   |---- TScaleDevice
   |---- TScaleApi
   |---- WebSocket
   |
   +---- TScaleHttpRouter
```

## Serviços expostos

- HTTP: porta `8097`
- WebSocket: porta `8098`
- WebSocket de peso: `/weight`

O formato das respostas é o mesmo da aplicação gráfica.

## Compilação

Com Lazarus instalado:

```bash
lazbuild src/service/balanca_service.lpi
```

O executável resultante é `balanca_service` no Linux e
`balanca_service.exe` no Windows.

## Execução

Por padrão, usa o diretório de configuração retornado por
`GetAppConfigDir(False)`.

Também é possível informar explicitamente:

```bash
balanca_service --config-dir=/etc/balanca
```

No Windows:

```bat
balanca_service.exe --config-dir=C:\ProgramData\Balanca
```

## Inicialização

O processo:

1. cria/carrega `main.cfg`;
2. inicia HTTP na porta 8097;
3. inicia WebSocket na porta 8098;
4. tenta conectar a serial;
5. entra no loop de serviço;
6. a cada 500 ms processa comandos pendentes e solicita o peso.

Se a serial não estiver disponível, HTTP e WebSocket continuam ativos e o erro
é enviado para stderr. Isso permite que o processo permaneça vivo enquanto a
camada de reconexão automática ainda não foi implementada.

## Linux / systemd

Arquivos:

```text
instalador/linux/balanca.service
instalador/linux/install-service.sh
```

Exemplo:

```bash
sudo sh instalador/linux/install-service.sh ./balanca_service
sudo systemctl start balanca
sudo systemctl status balanca
```

Logs:

```bash
journalctl -u balanca -f
```

O serviço usa:

```text
/opt/balanca/balanca_service
/etc/balanca/main.cfg
```

e executa com usuário de sistema `balanca`.

O usuário do serviço precisa ter permissão sobre a porta serial. Dependendo da
distribuição, isso normalmente exige associação ao grupo proprietário do
dispositivo, por exemplo `dialout`.

## Windows

Foi incluído:

```text
instalador/windows/run-headless.bat
instalador/windows/install-headless-task.ps1
```

O launcher usa:

```text
C:\ProgramData\Balanca
```

como diretório de configuração.

A instalação automática incluída usa o Agendador de Tarefas e executa o processo
como `SYSTEM` no boot:

```powershell
powershell -ExecutionPolicy Bypass -File instalador\windows\install-headless-task.ps1
```

Depois:

```powershell
Start-ScheduledTask -TaskName BalancaHeadless
Stop-ScheduledTask -TaskName BalancaHeadless
```

Isso fornece execução headless automática no Windows. Não é registrado como
serviço nativo do Service Control Manager; um wrapper SCM específico poderá ser
adicionado posteriormente se houver necessidade de integração com comandos
`sc.exe start/stop`.

## Logs

No modo headless os eventos básicos são enviados para stdout/stderr:

```text
Balanca headless iniciando...
config: /etc/balanca/
http: porta 8097
websocket: porta 8098 caminho /weight
serial: conectada em /dev/ttyUSB0
peso: +001.250
```

No Linux com systemd, essas mensagens ficam disponíveis automaticamente no
journal.
