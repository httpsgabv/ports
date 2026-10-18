# Plan 07: expected-processes

Spec: [specs/07-expected-processes.md](../../specs/07-expected-processes.md)

## Componentes

1. `Sources/PortsCore/Expected.swift`: `expectationKey(_:)` e `split(_:expected:) -> (active, expected)`.
2. `PortStore`: `expectedKeys: Set<String>` persistido (didSet → `UserDefaults`, padrão da spec 05); `processes` passa a ser só os ativos; novo `expectedProcesses`; `hasStale` e a contagem usam só os ativos.
3. UI: ação `EXPECT`/`UNEXPECT` na linha expandida e na de grupo; seção `EXPECTED · N` colapsável no fim da lista.

## Ordem

Chave + partição (TDD) → store → UI → verificação de persistência via `defaults read`.

## Riscos

| Risco | Mitigação |
|---|---|
| Chave instável (cwd muda entre restarts) | usar `project.root` antes do cwd; testar restart real do Postgres |
| Persistência "parece" funcionar mas não grava (aconteceu na spec 05) | verificar sempre com `defaults read`, não só pela UI |

## Checkpoint

Contador ignora os esperados; persistência confirmada com `defaults read` + restart do app e do processo.
