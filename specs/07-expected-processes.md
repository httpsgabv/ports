# Spec 07: expected-processes

> Stack, comandos, estrutura, estilo: ver [00-foundation](00-foundation.md). Usa `Project`/`kind` de [06-project-identity](06-project-identity.md). Persistência no padrão de [05-preferences](05-preferences.md).

## Objective

Alguns processos **devem** ficar rodando (o Postgres local, um proxy). Hoje eles contam no ícone e ficam âmbar para sempre, então o contador nunca chega a 0 e deixa de funcionar como alerta. Quero marcá-los como **esperados**.

## Identidade (sobrevive a restart do processo e do Mac)

```swift
public func expectationKey(_ p: ListeningProcess) -> String
// "<kind ?? name>@<project.root ?? cwd ?? executablePath>"
// ex: "POSTGRES@/opt/homebrew/var/postgresql@16", "VITE@/Users/gabriel/dev/yt-city"
```

PID e porta ficam **fora** da chave: os dois mudam a cada restart. Containers (spec 08) usam `"container@<nome>"`.

Persistido em `UserDefaults` (`expectedKeys: [String]`), lido e gravado pelo `PortStore`.

## Comportamento

- **Marcar:** ação `EXPECT` na linha expandida (e na linha de grupo, que marca todos os filhos).
- **Efeito:** não conta no ícone, nunca fica âmbar, sai do total do header (spec 10).
- **Lista:** seção no fim do popover: `EXPECTED · 2` colapsada por padrão. Expandida, mostra as linhas esmaecidas (opacidade 0.55), com ação `UNEXPECT` e o `×` normal.
- **Precedência:** o filtro de sistema vem primeiro. Um processo de sistema escondido não aparece nem em `EXPECTED`.
- Chaves de processos que não estão rodando ficam guardadas, sem limpeza automática (lista pequena; YAGNI).

## Acceptance criteria

- Marcar o Postgres como esperado → o contador cai 1 na hora; após quit + reabrir, continua esperado.
- Reiniciar o Postgres (novo PID) → continua esperado.
- `UNEXPECT` → volta para a lista principal e para o contador.
- Com todos os processos esperados, o ícone fica com 0 e esmaecido.

## Testing Strategy

- **Unit:** `expectationKey` (com e sem projeto/kind/cwd); partição `split(_:expected:) -> (active, expected)`.
- **Manual:** ciclo marcar → quit → reabrir → reiniciar processo → desmarcar, conferindo com `defaults read dev.gabriel.ports expectedKeys`.

## Boundaries

- **Never:** esconder um processo esperado de vez. Ele precisa continuar visível e matável na seção `EXPECTED`.

## Success Criteria

- [x] Testes de chave e partição verdes.
- [x] Persistência verificada via `defaults read`: EXPECT grava a chave; ela sobrevive ao restart do app e do processo (o novo PID gera a mesma chave, checado no scan real); UNEXPECT esvazia a lista.
- [ ] Contador do ícone caindo ao marcar: só observável na tela, não conferido por mim.

## Open Questions

- Nenhuma.
