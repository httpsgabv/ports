# Todo 03: live-status

- [ ] Task: `visible(_:showSystem:)` + testes de stale/filtro
  - Acceptance: filtro e stale cobertos (limite exato, abaixo, acima)
  - Verify: `swift test --filter Filtering`
  - Files: `Sources/PortsCore/Filtering.swift`, `Tests/PortsCoreTests/FilteringTests.swift`

- [ ] Task: `PortStore` com polling de 5s, sem sobreposição, erro preservando lista
  - Acceptance: `refresh()` fora da main thread; `lastError` setado em falha; `remove(pid)` otimista
  - Verify: `swift build`
  - Files: `Sources/Ports/PortStore.swift`

- [ ] Task: Label da menu bar com contador e estado stale; wiring no App
  - Acceptance: contador mono; âmbar se stale; esmaecido com 0
  - Verify: `./scripts/bundle.sh && open build/Ports.app`; subir/derrubar `python3 -m http.server 8765` e observar
  - Files: `Sources/Ports/MenuBarLabel.swift`, `Sources/Ports/PortsApp.swift`

- [ ] Task: Checkpoint de performance
  - Verify: `top -pid $(pgrep -x Ports) -l 12 -s 5 -stats cpu` → média < 1%
