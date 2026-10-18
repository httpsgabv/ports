# Plan 03: live-status

Spec: [specs/03-live-status.md](../../specs/03-live-status.md)

## Componentes

1. `Sources/PortsCore/Filtering.swift`: `visible(_ ps: [ListeningProcess], showSystem: Bool)`; `isStale` já está no struct (spec 00/01).
2. `Sources/Ports/PortStore.swift`: `@Observable @MainActor`, polling com `Task` + `Task.sleep(for: .seconds(5))`, flag `isScanning` para pular ticks.
3. `Sources/Ports/MenuBarLabel.swift`: label do `MenuBarExtra` = símbolo + contador mono; âmbar se algum stale; opacidade reduzida se 0.
4. `PortsApp.swift`: cria o store uma vez, injeta via `.environment`, `refresh()` no `onAppear` do popover.

## Ordem

Filtering (TDD) → PortStore → label → wiring → medir CPU.

## Riscos

| Risco | Mitigação |
|---|---|
| Label do `MenuBarExtra` não aceita cor customizada (template image) | renderizar `Text` com `foregroundStyle`; se o sistema forçar monocromático, usar `Image(nsImage:)` não-template gerada |
| Polling acorda CPU a cada 5s | aceitável (medido ~20ms CPU/tick em lsof); `// ponytail:` aponta libproc como upgrade |

## Checkpoint

Contador reage em ≤ 5s a subir/derrubar `python3 -m http.server`; CPU ociosa < 1%.
