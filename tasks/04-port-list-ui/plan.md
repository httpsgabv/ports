# Plan 04: port-list-ui

Spec: [specs/04-port-list-ui.md](../../specs/04-port-list-ui.md)

## Componentes

1. `Sources/PortsCore/Formatting.swift`: `formatUptime`, `formatBytes`, `abbreviateHome` (puros, testados).
2. `Sources/Ports/Views/RootView.swift`: header / lista ou vazio / footer. Troca para preferências (spec 05) via `@State`.
3. `Sources/Ports/Views/ProcessRow.swift`: linha colapsada + expandida, chips de porta, botão kill com estados (idle, hover, killing, error).
4. Wiring: kill chama `PortsCore.kill` → `store.remove(pid)` → `refresh()`.

## Ordem

Formatters (TDD) → linha estática com dados fake via `#Preview` → lista real → expandir → ações → estados de erro/vazio → acessibilidade → polish visual com screenshot.

## Riscos

| Risco | Mitigação |
|---|---|
| Popover do `MenuBarExtra` não redimensiona bem com expandir | `ScrollView` com altura máxima fixa; `.fixedSize(horizontal: false, vertical: true)` |
| Path longo quebra layout | `.lineLimit(1).truncationMode(.middle)` |
| Visual "genérico de SwiftUI" | remover estilos padrão (`.buttonStyle(.plain)`, sem `List`, sem materials); iterar com screenshot |

## Checkpoint

Screenshot aprovado + checklist de interação + VoiceOver básico.
