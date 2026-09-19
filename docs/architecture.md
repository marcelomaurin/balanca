# Arquitetura do núcleo da balança

A aplicação passa a separar interface, dispositivo, transporte serial e protocolo.

```text
Tfrmmain
   |
   v
TScaleDevice
   |---- TScaleConfig
   |---- TSerialTransport ---- TLazSerial
   |
   +---- TToledoProtocol
```

## Responsabilidades

### TScaleConfig
Mantém os parâmetros de comunicação serial usados pela balança:
porta, baud rate, data bits, paridade e stop bits.

### TSerialTransport
Encapsula o componente `TLazSerial`. É responsável por aplicar configuração,
conectar, desconectar, escrever e ler dados.

### TToledoProtocol
Concentra os elementos do protocolo Toledo, incluindo ENQ, STX, ETX e a
extração do valor de peso. Nesta etapa o comportamento do parser legado foi
preservado; a máquina de estados robusta será implementada em uma atividade
posterior.

### TScaleDevice
É a fachada usada pela aplicação. Coordena configuração, transporte e protocolo
e concentra o estado operacional:

- peso mais recente;
- frame mais recente recebido;
- último erro;
- data/hora da última leitura;
- estado de conexão.

A interface gráfica não deve implementar regras do protocolo nem detalhes da
configuração serial.
