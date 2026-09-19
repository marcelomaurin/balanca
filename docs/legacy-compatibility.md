# Compatibilidade legada

A compatibilidade com versões antigas foi isolada em uma camada própria.

## Estrutura

```text
src/legacy/
  legacyapi.pas
  legacyconfig.pas
  legacysettings.pas
```

O núcleo moderno não precisa conhecer formatos históricos.

## HTTP legado

As rotas históricas são:

```text
/
 /legacy
```

Elas preservam a resposta HTML antiga contendo:

```json
{"rs":{"peso":"+001.250"}}
```

A geração dessa resposta fica exclusivamente em:

```text
legacyapi.pas
```

Pode ser desativada por configuração:

```ini
[compatibility]
legacy_http_enabled=0
```

Quando desabilitada, as rotas antigas retornam HTTP 404.

## Configuração antiga

Versões antigas usavam:

```text
DEVICE:1
POSX:100
COMPORT:COM13
BAUDRATE:3
```

A leitura desse formato fica em:

```text
legacyconfig.pas
```

São mantidos:

- leitura de `CHAVE:valor`;
- fallback seguro para inteiros inválidos;
- booleanos `0/1`, `true/false`, `yes/no`, `sim/nao`.

A migração automática para INI continua ligada por padrão:

```ini
[compatibility]
legacy_config_migration=1
```

## Campos históricos

Campos sem função no núcleo atual foram agrupados em:

```text
TLegacySettings
```

Incluem:

- empresa;
- localização;
- tipo1/tipo2/tipo3;
- contadores;
- painel;
- tipo/modelo de impressão.

Eles continuam persistidos na seção:

```ini
[legado]
...
```

Para não quebrar código externo, `TSetMain` ainda expõe propriedades antigas,
mas elas são apenas uma fachada para `TLegacySettings`.

Exemplo:

```pascal
Settings.Empresa := 'Exemplo';
```

equivale internamente a:

```pascal
Settings.Legacy.Empresa := 'Exemplo';
```

## API moderna

`TScaleApi` não contém mais geração de resposta legada.

`scalejson.pas` também não contém mais o formato:

```text
{"rs":{"peso":...}}
```

Isso impede que regras de compatibilidade se espalhem novamente pela API v1.

## Estado da compatibilidade

`GET /api/v1/config` informa:

```json
{
  "compatibility": {
    "legacy_http_enabled": true,
    "legacy_config_migration": true
  }
}
```

## Testes

A suíte possui:

```text
tests/legacy_test.pas
```

que valida:

- leitura de valores antigos;
- fallback numérico;
- booleanos;
- detecção de arquivo legado;
- defaults históricos;
- JSON antigo;
- HTML antigo.

## Estratégia de remoção futura

A compatibilidade pode ser removida gradualmente:

1. manter as flags ligadas durante migração;
2. migrar consumidores para `/api/v1/*`;
3. definir `legacy_http_enabled=0`;
4. verificar logs e consumidores;
5. remover os campos da seção `[legado]` apenas quando não houver dependências;
6. por fim remover `src/legacy`.

Assim o núcleo moderno pode evoluir sem depender permanentemente do formato
histórico.
