# Todo 07: expected-processes

- [ ] Task: `expectationKey` + `split`
  - Acceptance: chave estável sem PID/porta; fallbacks project → cwd → executável
  - Verify: `swift test --filter Expected`
  - Files: `Sources/PortsCore/Expected.swift`, `Tests/PortsCoreTests/ExpectedTests.swift`

- [ ] Task: `expectedKeys` persistido no store; contador/stale só com ativos
  - Acceptance: marcar reduz o contador na hora
  - Verify: `swift build`; `defaults read dev.gabriel.ports expectedKeys` após marcar
  - Files: `Sources/Ports/PortStore.swift`

- [ ] Task: UI `EXPECT`/`UNEXPECT` + seção `EXPECTED · N` colapsável
  - Acceptance: linhas esperadas em tertiary, ainda matáveis
  - Verify: manual: ciclo marcar → quit → reabrir → reiniciar processo → desmarcar
  - Files: `Sources/Ports/Views/ProcessRow.swift`, `Sources/Ports/Views/GroupRow.swift`, `Sources/Ports/Views/RootView.swift`
