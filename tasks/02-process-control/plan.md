# Plan 02: process-control

Spec: [specs/02-process-control.md](../../specs/02-process-control.md)

## Componentes

1. `Sources/PortsCore/Killer.swift`: `KillResult` + `terminate(_:grace:)`.
   - Identidade: reusa `Shell.run` + `parsePsDetails` da spec 01 para reler `lstart` do pid (sem código novo de parsing).
   - Sinais: `Darwin.kill(pid, SIGTERM/SIGKILL)`, checagem `kill(pid, 0)` + `errno == ESRCH`.
   - Guardas: `pid <= 1 || pid == getpid()` → `.failed("refused")`.
2. `Sources/Ports/Actions.swift`: `openPort(_:)`, `revealInFinder(_:)` (2 funções finas sobre `NSWorkspace`).

## Ordem (TDD)

Testes de integração (sleep, trap TERM, já morto, pid reusado) → implementação → ações AppKit.

## Riscos

| Risco | Mitigação |
|---|---|
| Processo zumbi (filho do teste) continua "vivo" para `kill(pid,0)` | nos testes, usar `Process` e `waitUntilExit` em background; ou spawnar via `sh -c '... &'` para não ser filho |
| Granularidade de `lstart` é 1s | tolerância ±1s na comparação |
| Teste deixa órfão | `defer` mata com SIGKILL no teardown |

## Checkpoint

`swift test --filter Kill` verde e `pgrep -f "sleep 60"` vazio depois.
