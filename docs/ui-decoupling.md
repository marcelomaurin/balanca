# Desacoplamento da interface gráfica

A interface Lazarus deixou de coordenar diretamente protocolo, API, comandos e
WebSocket.

## Estrutura

```text
Tfrmmain
   |
   v
TScaleApplication
   |---- TScaleDevice
   |---- TScaleApi
   |---- TWeightWebSocketServer
   |
   +---- configuração / comandos / eventos

Tfrmmain
   |
   +---- TScaleHttpRouter
             |
             v
        TScaleApplication
```

## Responsabilidade da interface

`Tfrmmain` agora se limita a:

- reagir a clique de conectar/desconectar;
- mostrar o peso recebido;
- atualizar labels e tray icon;
- encaminhar eventos do componente serial;
- encaminhar eventos TCP/WebSocket;
- encaminhar requisições HTTP ao roteador;
- abrir telas auxiliares.

A interface não:

- interpreta protocolo Toledo;
- gera JSON;
- conhece comandos de domínio;
- gerencia fila de comandos;
- transmite WebSocket diretamente;
- configura manualmente o `TScaleDevice`.

## TScaleApplication

A unit `src/app/scaleapplication.pas` concentra o ciclo de vida da aplicação da
balança:

- aplica a configuração ao dispositivo;
- conecta/desconecta;
- processa dados seriais;
- executa o tick periódico;
- processa comandos pendentes;
- solicita leitura;
- distribui evento de peso;
- publica atualização WebSocket;
- expõe snapshot e API para outras camadas.

## TScaleHttpRouter

A unit `src/api/httprouter.pas` concentra o roteamento HTTP.

Ela trata:

- `GET /api/v1/weight`;
- `GET /api/v1/status`;
- `GET /api/v1/config`;
- rotas de compatibilidade;
- comandos HTTP POST;
- códigos HTTP 202, 404, 405, 409 e 501.

O formulário apenas repassa:

```pascal
FHttpRouter.HandleGet(ARequestInfo, AResponseInfo);
```

ou:

```pascal
FHttpRouter.HandleOther(ARequestInfo, AResponseInfo);
```

## Conexão

O fluxo de conexão também foi corrigido.

Antes, o código usava `finally` e ativava timer/HTTP mesmo quando a abertura da
serial falhava.

Agora os serviços só são ativados depois que:

```pascal
FScaleApp.Connect
```

retorna com sucesso.

Em caso de erro:

- timer permanece desligado;
- status visual passa para erro;
- tray icon não informa conexão;
- o usuário recebe a mensagem da exceção.

## Benefício

Essa separação prepara o projeto para:

- interface alternativa;
- execução como serviço;
- aplicação headless;
- testes mais simples;
- reutilização do núcleo em outro frontend;
- futura remoção gradual de componentes visuais antigos.
