# Todo 08: docker-containers

- [ ] Task: `run` com `HOME`/`PATH` + timeout opcional
  - Acceptance: `docker context ls` funciona via `run`; timeout aborta e lança erro
  - Verify: `swift test --filter Shell`
  - Files: `Sources/PortsCore/Shell.swift`, `Tests/PortsCoreTests/ScannerIntegrationTests.swift`

- [ ] Task: Parser do `docker ps` + detecção de runtime + `expandContainers`
  - Acceptance: portas v4/v6/faixas/sem porta; porta sem container fica no runtime
  - Verify: `swift test --filter Docker`
  - Files: `Sources/PortsCore/Docker.swift`, `Tests/PortsCoreTests/DockerTests.swift`, `Tests/PortsCoreTests/Fixtures.swift`

- [ ] Task: Refactor `id: String` + campo `container`
  - Acceptance: todos os testes verdes, app compila, `remove(id)` funcionando
  - Verify: `swift build && swift test`
  - Files: `Sources/PortsCore/ListeningProcess.swift`, `Sources/Ports/PortStore.swift`, `Sources/Ports/Views/*.swift`

- [ ] Task: `scan` chama o docker só com runtime presente; `terminate` → `docker stop`
  - Acceptance: integração com `nginx:alpine` (pulada sem Docker)
  - Verify: `swift test --filter DockerIntegration` com o Docker Desktop aberto
  - Files: `Sources/PortsCore/Scanner.swift`, `Sources/PortsCore/Killer.swift`, `Tests/PortsCoreTests/DockerIntegrationTests.swift`

- [ ] Task: UI de container + checklist manual
  - Verify: `docker run -d -p 5432:5432 postgres:16`; compose app + db; `×`; Docker fechado
  - Files: `Sources/Ports/Views/ProcessRow.swift`
