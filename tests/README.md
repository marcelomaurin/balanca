# Testes automatizados

A suíte cobre componentes que podem ser validados sem abrir a interface gráfica.

## Casos

- `toledo_protocol_test.pas`
  - frame completo;
  - frame fragmentado;
  - múltiplos frames;
  - ruído;
  - resincronização por STX;
  - frame vazio;
  - payload excessivo.

- `commands_test.pas`
  - conversão enum → nome;
  - parsing nome → enum;
  - aliases;
  - rejeição de comandos inválidos.

- `config_test.pas`
  - leitura do formato legado `CHAVE:valor`;
  - migração automática para INI;
  - releitura do INI;
  - fallback seguro para valores inválidos;
  - diretório de configuração isolado para teste.

- `api_json_test.pas`
  - JSON de peso;
  - JSON de status;
  - JSON de configuração;
  - JSON de erro;
  - JSON de comandos;
  - compatibilidade legacy;
  - escape de caracteres especiais.

## Linux/macOS

Com Free Pascal instalado:

```bash
cd tests
sh run_all.sh
```

## Windows

No Prompt de Comando com `fpc.exe` no PATH:

```bat
cd tests
run_all.bat
```

Os binários são gerados em:

```text
tests/bin/
```

A pasta deve permanecer fora do versionamento.

## Objetivo

A suíte foi mantida simples, sem framework externo de testes, para poder rodar
em instalações padrão do Free Pascal e posteriormente em CI.
