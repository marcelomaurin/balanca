# Simulador Arduino da balança

O simulador Arduino emula o fluxo usado pelo projeto para uma balança
Toledo/compatível.

## Comunicação serial

- baud rate: 2400;
- leitura: comando ENQ (`0x05`);
- resposta: `STX + payload + ETX`;
- não é acrescentado CR/LF após ETX.

Exemplo:

```text
PC -> 0x05

Arduino -> 0x02 + +001.250 + 0x03
```

## Comandos do simulador

Estes comandos pertencem ao simulador e não devem ser considerados comandos
Toledo reais:

- `T`: aplica tara ao valor atual;
- `P`: limpa o total acumulado;
- `Z`: zera a tara;
- `C`: liga/desliga envio contínuo;
- `N`: acumula o peso atual e gera novo valor;
- `M`: liga/desliga mudança automática de peso.

## Correções realizadas

### Flags booleanos

O código antigo usava:

```cpp
flgContinuo = ~flgContinuo;
```

Em inteiros, `~1` vira `-2`, que continua sendo diferente de zero. Por isso o
modo contínuo praticamente nunca desligava.

Agora são usados `bool` e:

```cpp
flgContinuo = !flgContinuo;
```

### Buffer de peso

O buffer antigo tinha apenas 6 bytes, apesar de `dtostrf(..., 7, 3, ...)`
precisar de pelo menos 8 bytes contando o terminador.

Agora há folga:

```cpp
char weightText[16];
char frame[20];
```

### Remoção de scanf incorreto

A chamada:

```cpp
scanf(strTara, "%6d", tara);
```

era inválida para o objetivo e foi removida.

### Remoção de String

O frame não usa mais `String`, evitando fragmentação do heap em placas AVR.

### Fim de frame

O código antigo usava `Serial.println(buffer)`, adicionando CR/LF após ETX.

Agora o frame é enviado com:

```cpp
Serial.write(...)
```

terminando exatamente em ETX.

### Botões

Os botões agora usam:

```cpp
INPUT_PULLUP
```

e debounce não bloqueante baseado em `millis()`.

### Loop principal

O atraso de 1000 ms foi reduzido. O loop executa continuamente as etapas:

```text
ProcessSerial
ProcessButtons
ProcessAutoMode
SendWeight (se contínuo)
```

com pequeno intervalo para evitar ocupação excessiva de CPU.

## Observação sobre modo contínuo

Com `flgContinuo = true`, o simulador envia frames repetidamente. Para testes
mais próximos do comportamento consulta/resposta, use o comando `C` para
desativar o envio contínuo e faça as leituras usando ENQ.
