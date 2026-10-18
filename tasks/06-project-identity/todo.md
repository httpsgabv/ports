# Todo 06: project-identity

- [x] Task: `detectKind` com tabela de comandos reais
  - Acceptance: todos os kinds da spec; sem falso positivo em paths com "next"/"vite" em nomes de pasta
  - Verify: `swift test --filter Identity`
  - Files: `Sources/PortsCore/Identity.swift`, `Tests/PortsCoreTests/IdentityTests.swift`

- [x] Task: `resolveProject` com `.git` pasta/arquivo, `package.json` válido/inválido/ausente, monorepo
  - Acceptance: casos da spec em dirs temporários; nunca sobe além de `$HOME`
  - Verify: `swift test --filter Identity`
  - Files: `Sources/PortsCore/Identity.swift`, `Tests/PortsCoreTests/IdentityTests.swift`

- [x] Task: Campos `project`/`kind` no modelo + `merge` + `groupByProject`
  - Acceptance: fixtures agrupam corretamente; ordem por menor porta do grupo; avulsos sem cwd
  - Verify: `swift test`
  - Files: `Sources/PortsCore/ListeningProcess.swift`, `Sources/PortsCore/Parsers.swift`, `Sources/PortsCore/Grouping.swift`, `Tests/PortsCoreTests/GroupingTests.swift`

- [x] Task: `terminateAll` em paralelo
  - Acceptance: mata 3 processos spawnados em < 4s; retorna um resultado por processo
  - Verify: `swift test --filter Kill`
  - Files: `Sources/PortsCore/Killer.swift`, `Tests/PortsCoreTests/KillerTests.swift`

- [x] Task: UI de grupo (linha de grupo, filhos, kill do grupo, título por kind)
  - Acceptance: layout da spec; erro parcial inline
  - Verify: manual com 3 `http.server` num repo git temporário + 1 avulso
  - Files: `Sources/Ports/Views/GroupRow.swift`, `Sources/Ports/Views/ProcessRow.swift`, `Sources/Ports/Views/RootView.swift`

- [x] Task: Checkpoint de custo
  - Verify: medir CPU ociosa como na spec 03 (app + filhos) → < 1%
