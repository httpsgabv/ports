# Plan 06: project-identity

Spec: [specs/06-project-identity.md](../../specs/06-project-identity.md)

## Componentes

1. `Sources/PortsCore/Identity.swift`
   - `detectKind(command:executable:) -> String?`: tabela de tokens da spec, avaliada em ordem.
   - `resolveProject(cwd:home:) -> Project?`: sobe até achar `.git` (sem passar de `$HOME`), lê `package.json`. Sem cache (só PIDs novos).
2. `ListeningProcess`: novos campos `project`, `kind`. O `merge` preenche os dois, e o `with(ports:)` preserva.
3. `Sources/PortsCore/Grouping.swift`: `ProcessGroup` + `groupByProject`.
4. `Sources/PortsCore/Killer.swift`: `terminateAll(_:) async -> [KillResult]` em paralelo (`withTaskGroup`).
5. UI: `GroupRow.swift` (linha de grupo + filhos) e `RootView` iterando grupos. `ProcessRow` ganha título `kind ?? name` e o projeto na meta.

## Ordem (TDD)

detectKind → resolveProject (dirs temporários) → campos no modelo + merge → groupByProject → terminateAll → UI → medir CPU.

## Riscos

| Risco | Mitigação |
|---|---|
| Falso positivo com nome de pasta (`~/dev/next-gen`) | comparar o último componente de cada token em vez de regex; testado |
| I/O de disco por tick | só para PIDs novos (o fluxo do `scan(reusing:)`) |
| `ListeningProcess` com init interno cresce | testes usam um helper `fake(...)` com defaults |

## Checkpoint

3 servidores no mesmo repo viram 1 grupo; kill do grupo funciona; CPU < 1%.
