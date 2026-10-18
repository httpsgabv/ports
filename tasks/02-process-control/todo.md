# Todo 02: process-control

- [ ] Task: Testes de integração do kill (4 casos da spec) — red
  - Acceptance: testes compilam e falham pelo motivo certo
  - Verify: `swift test --filter Kill` (falhando)
  - Files: `Tests/PortsCoreTests/KillerTests.swift`

- [ ] Task: Implementar `kill(_:grace:)` com checagem de identidade e escalonamento
  - Acceptance: 4 casos verdes; nunca sinaliza pid ≤ 1 ou o próprio app; sem órfãos
  - Verify: `swift test --filter Kill && pgrep -f "sleep 60"` (vazio)
  - Files: `Sources/PortsCore/Killer.swift`

- [ ] Task: Ações AppKit `openPort` e `revealInFinder`
  - Acceptance: compilam; usadas pela UI na spec 04
  - Verify: `swift build`; teste manual na spec 04
  - Files: `Sources/Ports/Actions.swift`
