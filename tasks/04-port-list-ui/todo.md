# Todo 04: port-list-ui

- [ ] Task: Formatadores puros
  - Acceptance: `formatUptime` (0s, 59s, 59m, 3h 05m, 2d 4h), `formatBytes` (KB/MB/GB, borda 1023/1024), `abbreviateHome`
  - Verify: `swift test --filter Formatting`
  - Files: `Sources/PortsCore/Formatting.swift`, `Tests/PortsCoreTests/FormattingTests.swift`

- [ ] Task: `ProcessRow` colapsada (dot, nome, chips de porta, ×, metadados, barra stale)
  - Acceptance: bate com o layout da spec e os tokens; `#Preview` com dados fake normal + stale
  - Verify: `swift build`; preview/visual
  - Files: `Sources/Ports/Views/ProcessRow.swift`

- [ ] Task: `RootView` com header, lista em ScrollView, vazio, footer (updated Xs · QUIT · ⚙ placeholder, erro de scan)
  - Acceptance: 380pt de largura, máx. 520pt, scroll suave com 20 itens
  - Verify: bundle + abrir com processos reais
  - Files: `Sources/Ports/Views/RootView.swift`

- [ ] Task: Expandir linha (PID, comando, OPEN ↗, FINDER) + clique em porta abre browser
  - Acceptance: uma expandida por vez; FINDER só com cwd
  - Verify: manual com `vite`/`http.server`
  - Files: `Sources/Ports/Views/ProcessRow.swift`

- [ ] Task: Kill pelo × com estados (hover danger, spinner, fade out, erro inline 3s)
  - Acceptance: linha some em < 4s; contador atualiza; erro de permissão visível
  - Verify: matar `http.server` e um `sh -c 'trap "" TERM; sleep 999'` ouvindo porta (via `nc -l`)
  - Files: `Sources/Ports/Views/ProcessRow.swift`, `Sources/Ports/PortStore.swift`

- [ ] Task: Acessibilidade + polish visual
  - Acceptance: VoiceOver lê nome/portas/uptime; × com label "Kill <name>"; Esc fecha
  - Verify: VoiceOver (⌘F5) + screenshot aprovado
  - Files: `Sources/Ports/Views/*.swift`
