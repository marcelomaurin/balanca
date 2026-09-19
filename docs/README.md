# Documentação do projeto Balança

Este diretório reúne a documentação técnica e operacional do projeto.

## Visão geral

- [Arquitetura](architecture.md)
- [Desacoplamento da UI](ui-decoupling.md)
- [Modo headless / serviço](headless-service.md)
- [Reconexão automática](reconnection.md)
- [Segurança](security.md)
- [Drivers de protocolo](protocol-drivers.md)
- [CI/CD](ci-cd.md)

## Comunicação e integração

- [API HTTP](api.md)
- [WebSocket](websocket.md)
- [Comandos da balança](commands.md)
- [Protocolo Toledo](toledo-protocol.md)

## Configuração

- [Configuração](configuration.md)

## Simulação e testes

- [Simulador Arduino](simulator-arduino.md)
- [Modos de falha do simulador](simulator-failures.md)
- [Suíte de testes](../tests/README.md)

## Ordem sugerida de leitura

1. [README principal](../README.md)
2. [Arquitetura](architecture.md)
3. [Configuração](configuration.md)
4. [API HTTP](api.md)
5. [WebSocket](websocket.md)
6. [Reconexão automática](reconnection.md)
7. [Segurança](security.md)
8. [Modo headless / serviço](headless-service.md)
9. [Drivers de protocolo](protocol-drivers.md)
10. [Simulador Arduino](simulator-arduino.md)
11. [Testes](../tests/README.md)
12. [CI/CD](ci-cd.md)

## Princípios atuais do projeto

- a UI não contém regras de protocolo;
- `TScaleApplication` coordena o ciclo da balança;
- `TScaleDevice` trabalha com uma abstração de protocolo;
- a serial é encapsulada por `TSerialTransport`;
- protocolos são registrados por fábrica;
- Toledo continua como driver padrão;
- HTTP e WebSocket são camadas de integração;
- segurança é local-only por padrão;
- o modo headless reutiliza o mesmo núcleo;
- o simulador não define automaticamente o comportamento de uma balança real;
- novos comandos/protocolos só devem ser implementados com documentação validada.
