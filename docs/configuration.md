# Configuração da aplicação

A configuração continua sendo armazenada em `main.cfg`, dentro do diretório
retornado por `GetAppConfigDir(False)`.

A partir desta versão, o arquivo usa formato INI por meio de `TIniFile`.

## Exemplo

```ini
[geral]
device=0
hide=0
exec=0
splash=0

[janela]
posx=100
posy=100

[serial]
comport=COM13
baudrate=3
databit=0
paridade=0
stopbit=0

[legado]
empresa=maurinsoft
localizacao=nothing
tipo1=Normal
tipo2=Idoso
tipo3=Especial
contagem1=0
contagem2=0
contagem3=0
painel=192.168.0.108
tipoimp=0
modeloimp=0
```

No Linux, o valor padrão da porta é `/dev/ttyS0`.

## Migração automática

Versões antigas gravavam o arquivo assim:

```text
DEVICE:0
POSX:100
POSY:100
COMPORT:COM13
BAUDRATE:3
```

Ao iniciar:

1. a aplicação detecta se o arquivo possui seções INI;
2. se for formato antigo, carrega os pares `CHAVE:valor`;
3. valores inválidos usam o valor padrão em vez de provocar exceção;
4. o arquivo é regravado automaticamente no formato INI.

A migração mantém os nomes e valores existentes sempre que possível.

## Segurança de leitura

O carregamento usa valores padrão para campos ausentes. A migração do formato
legado usa `TryStrToInt` e interpretação tolerante de booleanos, evitando que
um `main.cfg` parcialmente corrompido impeça a inicialização da aplicação.

## Organização

As seções têm responsabilidades separadas:

- `geral`: comportamento da aplicação;
- `janela`: posição da interface;
- `serial`: comunicação com a balança;
- `legado`: campos históricos ainda mantidos para compatibilidade.

Os campos em `legado` poderão ser eliminados futuramente após confirmar que
não são usados por integrações externas.
