# Todo 01: port-scanner

- [x] Task: Capturar fixtures reais de lsof/ps desta máquina
  - Acceptance: fixtures cobrem IPv6 `[::1]`, `*:porta`, dedupe v4/v6, `comm` com espaços, processo multi-porta
  - Verify: arquivos legíveis e anonimizados se necessário
  - Files: `Tests/PortsCoreTests/Fixtures.swift`

- [x] Task: `ListeningProcess` + parsers puros + `isSystemPath`
  - Acceptance: todos os casos da spec cobertos por testes; red → green
  - Verify: `swift test --filter Parser`
  - Files: `Sources/PortsCore/ListeningProcess.swift`, `Sources/PortsCore/Parsers.swift`, `Tests/PortsCoreTests/ParserTests.swift`

- [x] Task: `Shell.run` + `scan()` com merge
  - Acceptance: lsof vazio → `[]`; pid sumido descartado; ordenado por menor porta; < 300ms
  - Verify: `swift test --filter Scanner`
  - Files: `Sources/PortsCore/Shell.swift`, `Sources/PortsCore/Scanner.swift`, `Tests/PortsCoreTests/ScannerTests.swift`

- [x] Task: Teste de integração com socket real
  - Acceptance: teste faz bind numa porta efêmera e `scan()` retorna o pid do teste com essa porta, cwd e < 300ms (medido: ~130ms)
  - Verify: `swift test --filter ScannerIntegration`
  - Files: `Tests/PortsCoreTests/ScannerIntegrationTests.swift`

- [x] Task: Checkpoint manual
  - Verify: `python3 -m http.server 8765` em `~/tmp/x` → aparece com cwd correto; ControlCenter/rapportd `isSystem == true`
