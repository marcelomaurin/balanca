# Comandos da balança

A aplicação agora diferencia comandos padronizados do domínio da balança dos
comandos particulares do simulador Arduino.

## Comandos padronizados

Definidos em `src/core/scalecommands.pas`:

- `read`;
- `tare`;
- `zero`;
- `print`;
- `continuous_start`;
- `continuous_stop`.

A existência de um comando no domínio não significa que todos os protocolos o
implementam. Cada protocolo deve declarar explicitamente quais comandos suporta.

## Protocolo Toledo atual

No projeto atual, apenas a leitura via ENQ (`0x05`) está confirmada e habilitada
para o equipamento Toledo/compatível.

Assim:

- `read`: suportado;
- `tare`: não habilitado;
- `zero`: não habilitado;
- `print`: não habilitado;
- `continuous_start`: não habilitado;
- `continuous_stop`: não habilitado.

Isso evita enviar ao equipamento real bytes que só existem no simulador.

## Comandos exclusivos do simulador Arduino

Definidos separadamente em `src/core/simulatorcommands.pas`:

- `T`: tara do simulador;
- `P`: limpa o total acumulado;
- `Z`: zera a tara;
- `C`: alterna modo contínuo;
- `N`: gera/próximo peso;
- `M`: alterna mudança automática.

Esses bytes não são tratados como comandos Toledo reais.

## API

Os comandos são solicitados por HTTP POST:

```text
POST /api/v1/commands/read
POST /api/v1/commands/tare
POST /api/v1/commands/zero
POST /api/v1/commands/print
POST /api/v1/commands/continuous_start
POST /api/v1/commands/continuous_stop
```

O servidor HTTP não escreve diretamente na serial. O comando é enfileirado e
executado pela thread da aplicação através de `TScaleDevice.ProcessPendingCommands`.

### Respostas

`202 Accepted` quando o comando foi aceito e colocado na fila:

```json
{
  "command": "read",
  "accepted": true,
  "message": "queued"
}
```

`409 Conflict` quando a balança não está conectada.

`501 Not Implemented` quando o comando existe no domínio, mas não é suportado
pelo protocolo Toledo atualmente configurado.

`404 Not Found` para um nome de comando desconhecido.

## Segurança arquitetural

A separação impede que comandos de laboratório/simulador sejam enviados
acidentalmente para um equipamento real. Para habilitar tara, zero ou outro
comando em uma balança real, a implementação deve ser adicionada explicitamente
ao protocolo correspondente.
