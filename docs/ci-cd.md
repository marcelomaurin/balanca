# CI/CD

O projeto usa GitHub Actions em três níveis.

## 1. CI obrigatório

Workflow:

```text
.github/workflows/ci.yml
```

Executa em push, pull request e manualmente.

Jobs principais:

- testes FPC no Linux;
- testes FPC no Windows;
- validações de estrutura do repositório;
- job agregador `CI success`.

### Linux

O runner instala Free Pascal pelos pacotes da distribuição e executa:

```bash
sh tests/run_all.sh
```

### Windows

O runner instala Lazarus/FPC e executa:

```bat
tests\run_all.bat
```

### Repository checks

O workflow também verifica:

- documentação obrigatória;
- artefatos de build indevidamente versionados;
- marcadores de conflito de merge.

## 2. Build Lazarus completo

Workflow:

```text
.github/workflows/build-lazarus.yml
```

É iniciado manualmente por `workflow_dispatch`.

A separação é intencional porque a aplicação desktop depende de pacotes Lazarus externos além do FPC básico:

- Indy;
- lNet;
- LazSerial;
- IndustrialStuff;
- SdpoSerial/Sdpo Components.

O workflow recebe dois parâmetros:

```text
lazarus_version
include_packages
```

Isso permite ajustar versões e nomes dos pacotes sem alterar o CI obrigatório.

Quando o ambiente é resolvido com sucesso, o workflow:

1. executa a suíte de testes;
2. compila `src/balanca.lpi`;
3. compila `src/service/balanca_service.lpi`;
4. publica artefatos Linux/Windows.

## 3. Empacotamento

Workflow:

```text
.github/workflows/package.yml
```

É disparado em tags:

```text
v*
```

ou manualmente.

Antes de empacotar, executa a suíte de testes no Linux.

O artefato gerado contém:

- código-fonte;
- documentação;
- simulador;
- testes;
- instaladores.

Arquivo:

```text
balanca-source.tar.gz
```

## Dependências Lazarus

O CI de testes foi mantido independente dos componentes visuais para validar o máximo possível do núcleo mesmo quando algum pacote Lazarus externo estiver indisponível.

O build completo deve ser usado para validar integração entre:

- LCL;
- Indy;
- lNet;
- LazSerial;
- SdpoSerial;
- IndustrialStuff.

## Proteção de branch

Depois que o workflow estiver validado no GitHub, recomenda-se configurar a branch principal para exigir o check:

```text
CI success
```

antes de permitir merge.

## Artefatos

Os artefatos produzidos por GitHub Actions são temporários e não devem ser commitados em `bin/` ou `lib/`.

## Fluxo recomendado

```text
feature branch
      |
      v
Pull Request
      |
      v
CI Linux + Windows
      |
      v
CI success
      |
      v
merge
      |
      +---- build Lazarus manual
      |
      +---- tag vX.Y.Z
               |
               v
          package workflow
```
