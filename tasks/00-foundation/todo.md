# Todo 00: foundation

- [x] Task: Criar pacote SwiftPM com targets PortsCore, Ports e PortsCoreTests
  - Acceptance: `swift build` e `swift test` passam (1 teste trivial em PortsCoreTests)
  - Verify: `swift build && swift test`
  - Files: `Package.swift`, `Sources/PortsCore/PortsCore.swift`, `Sources/Ports/PortsApp.swift`, `Tests/PortsCoreTests/SmokeTests.swift`, `.gitignore`

- [x] Task: Theme + MenuBarExtra mínimo (popover preto com `PORTS` e `QUIT`)
  - Acceptance: tokens da spec em `Theme.swift`; popover fundo #000; QUIT chama `NSApp.terminate`
  - Verify: `swift build`; verificação visual na task seguinte
  - Files: `Sources/Ports/Theme.swift`, `Sources/Ports/PortsApp.swift`, `Sources/Ports/Views/RootView.swift`

- [x] Task: Info.plist + scripts/bundle.sh (com `--install`)
  - Acceptance: gera `build/Ports.app` assinado ad-hoc; sem ícone no Dock/⌘Tab
  - Verify: `./scripts/bundle.sh && open build/Ports.app` → checar menu bar, Dock e ⌘Tab; `codesign -v build/Ports.app`
  - Files: `Resources/Info.plist`, `scripts/bundle.sh`

- [x] Task: Checkpoint
  - Verify: `footprint -p $(pgrep -x Ports)` < 30 MB (medido: 14 MB); screenshot do popover
