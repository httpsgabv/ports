# Todo 09: idle-detection

- [x] Task: Fixture real LISTEN+ESTABLISHED + `parseLsofTCP`
  - Acceptance: conexões não viram portas; conta só as de entrada; pids só com conexão de saída descartados
  - Verify: `swift test --filter Parser`
  - Files: `Sources/PortsCore/Parsers.swift`, `Tests/PortsCoreTests/ParserTests.swift`, `Tests/PortsCoreTests/Fixtures.swift`

- [x] Task: `scan` com LISTEN,ESTABLISHED + `inboundConnections` (também nos reusados)
  - Acceptance: integração: cliente conectado → 1; desconectado → 0
  - Verify: `swift test --filter ScannerIntegration`
  - Files: `Sources/PortsCore/Scanner.swift`, `Sources/PortsCore/ListeningProcess.swift`, `Tests/PortsCoreTests/ScannerIntegrationTests.swift`

- [x] Task: `lastActive`/`idleSince`/`isStale` no store + testes de stale com `now` injetado
  - Acceptance: ativo nunca é stale; ocioso vira stale após o limite
  - Verify: `swift test`
  - Files: `Sources/Ports/PortStore.swift`, `Sources/PortsCore/Filtering.swift`, `Tests/PortsCoreTests/FilteringTests.swift`

- [x] Task: UI (`up · idle` / `N conn`, label `IDLE FOR`) + checklist
  - Verify: vite + aba aberta/fechada; CPU ociosa < 1%
  - Files: `Sources/Ports/Views/ProcessRow.swift`, `Sources/Ports/Views/PreferencesView.swift`
