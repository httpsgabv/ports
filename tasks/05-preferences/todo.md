# Todo 05: preferences

- [x] Task: `PreferencesView` inline (← BACK, STALE AFTER, SHOW SYSTEM PROCESSES, versão) com persistência
  - Acceptance: mudanças aplicam na hora no contador e no destaque; sobrevivem a quit/reabrir
  - Verify: manual: mudar para 1h e ligar system → ver efeito; quit + reabrir
  - Files: `Sources/Ports/Views/PreferencesView.swift`, `Sources/Ports/Views/RootView.swift`, `Sources/Ports/PortStore.swift`

- [x] Task: LAUNCH AT LOGIN via `SMAppService.mainApp`
  - Acceptance: toggle reflete `.status`; erro inline se falhar; `.requiresApproval` abre System Settings
  - Verify: `./scripts/bundle.sh --install`, abrir de `/Applications`, ligar toggle → conferir Login Items
  - Files: `Sources/Ports/Views/PreferencesView.swift`

- [ ] Task: Checkpoint final do app
  - Verify: logout/login → app sobe sozinho com preferências preservadas; percorrer Success Criteria de todas as specs 00–05
