# Todo 10: quick-wins

- [ ] Task: `isExposed` + chip `LAN`
  - Acceptance: casos da spec; `--bind 127.0.0.1` não mostra LAN
  - Verify: `swift test --filter Parser`; manual com `http.server` com e sem `--bind`
  - Files: `Sources/PortsCore/Parsers.swift`, `Sources/PortsCore/ListeningProcess.swift`, `Tests/PortsCoreTests/ParserTests.swift`, `Sources/Ports/Views/ProcessRow.swift`

- [ ] Task: Editores instalados + preferência `EDITOR` + botão
  - Acceptance: picker só com instalados; abre a raiz do projeto no editor escolhido
  - Verify: manual com 2 editores instalados
  - Files: `Sources/Ports/Editors.swift`, `Sources/Ports/Views/PreferencesView.swift`, `Sources/Ports/Views/ProcessRow.swift`, `Sources/Ports/PortStore.swift`

- [ ] Task: Total de memória no header
  - Acceptance: soma só visíveis e não esperados
  - Verify: `swift test --filter Filtering`; conta manual
  - Files: `Sources/PortsCore/Filtering.swift`, `Tests/PortsCoreTests/FilteringTests.swift`, `Sources/Ports/Views/RootView.swift`
