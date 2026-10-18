# Plan 01: port-scanner

Spec: [specs/01-port-scanner.md](../../specs/01-port-scanner.md)

## Componentes (todos em `Sources/PortsCore/`)

1. `ListeningProcess.swift`: o struct do contrato.
2. `Parsers.swift`: funções puras
   - `parseLsofListen(_:) -> [Int32: (name: String, ports: Set<UInt16>)]`
   - `parsePsDetails(_:) -> [Int32: (startedAt: Date, cpu: Double, rss: UInt64, exe: String)]`
   - `parsePsCommand(_:) -> [Int32: String]`
   - `parseLsofCwd(_:) -> [Int32: String]`
   - `isSystemPath(_:) -> Bool`
3. `Shell.swift`: `run(_ path: String, _ args: [String]) async throws -> (status: Int32, stdout: String)` via `Foundation.Process`. Um lugar só.
4. `Scanner.swift`: `scan()` orquestra: lsof listen → pids → (ps details ∥ ps command ∥ lsof cwd) → merge → filtra pids sem detalhes → ordena por menor porta.

## Ordem (TDD)

Fixtures reais → parsers (red/green) → Shell → scan() → teste de integração com socket real.

## Riscos

| Risco | Mitigação |
|---|---|
| `lsof` retorna exit 1 quando não acha nada | tratar status 1 + stdout vazio como `[]` |
| `lstart` depende de locale | forçar `LC_ALL=C` no environment do `Process` + formatter `en_US_POSIX` |
| `comm` com espaços | `lstart` tem 5 tokens fixos; `comm` = resto da linha após o 8º token |
| Processo some entre chamadas | merge descarta pid sem linha no ps |

## Checkpoint

`swift test` verde, incluindo integração; `scan()` chamado de um teste imprime processos reais desta máquina coerentes com `lsof`.
