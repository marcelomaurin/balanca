# Modos de falha do simulador Arduino

O simulador permite reproduzir falhas de comunicação e comportamento para testar
a robustez do parser, da API e da interface.

Os modos são ativados enviando dois bytes pela serial:

```text
F<modo>
```

Exemplos:

```text
F0
F1
F2
```

## Modos disponíveis

### F0 — Normal

Retorna ao comportamento normal:

```text
STX + peso + ETX
```

### F1 — ETX ausente

Envia um frame iniciado por STX, mas omite ETX.

Objetivo:

- testar timeout lógico;
- testar descarte de frame incompleto;
- testar resincronização no próximo STX.

### F2 — Ruído serial

Envia bytes de ruído antes e depois do frame válido.

Objetivo:

- testar contagem de `IgnoredBytes`;
- validar recuperação do parser até encontrar STX.

### F3 — Frame truncado

Envia apenas aproximadamente metade do frame.

Objetivo:

- testar frame parcial;
- validar descarte quando um novo STX chegar.

### F4 — Resposta atrasada

Atrasa a resposta em aproximadamente 1500 ms.

Objetivo:

- testar comportamento da aplicação com resposta lenta;
- preparar testes de timeout e reconexão.

O atraso é não bloqueante e usa `millis()`.

### F5 — Peso instável

Adiciona pequena variação aleatória ao peso reportado sem alterar o valor real
interno da simulação.

Faixa aproximada:

```text
±0,050
```

Objetivo:

- testar estabilização;
- testar interface com pequenas oscilações;
- preparar futuras regras de peso estável.

### F6 — Silêncio / desconexão simulada

O simulador permanece conectado fisicamente à serial, mas não envia respostas.

Objetivo:

- simular equipamento sem resposta;
- testar timeout;
- testar detecção de indisponibilidade;
- testar futura reconexão automática.

## Comandos normais continuam válidos

Os comandos existentes permanecem inalterados:

- ENQ: leitura;
- `T`: tara;
- `P`: limpa acumulado;
- `Z`: zera tara;
- `C`: alterna modo contínuo;
- `N`: novo peso;
- `M`: alterna mudança automática.

O comando `F` apenas informa que o próximo byte define o modo de falha.

## Exemplos de teste

### Frame sem ETX

```text
Enviar: F1
Enviar: ENQ
Esperado: STX + payload, sem ETX
```

Depois:

```text
Enviar: F0
Enviar: ENQ
Esperado: parser deve recuperar sincronismo no novo STX
```

### Ruído

```text
Enviar: F2
Enviar: ENQ
Esperado: ruído + frame válido + ruído
```

A API `/api/v1/status` deve refletir aumento em `ignored_bytes`.

### Silêncio

```text
Enviar: F6
Enviar: ENQ
Esperado: nenhuma resposta
```

Retorno ao normal:

```text
Enviar: F0
```

## Observação

Esses modos existem somente no simulador de testes. Eles não fazem parte do
protocolo Toledo real e não devem ser enviados a uma balança de produção.
