# Plan 05: preferences

Spec: [specs/05-preferences.md](../../specs/05-preferences.md)

## Componentes

1. `Sources/Ports/Views/PreferencesView.swift`: tela inline no popover com `← BACK`, Stepper, 2 toggles, versão.
2. `PortStore`: `showSystem` e `staleThreshold` passam a vir de `UserDefaults` (`@AppStorage` na view sincroniza com o store; ou o store lê/escreve `UserDefaults` direto — escolher o que der menos código).
3. Launch at login: `SMAppService.mainApp.register()/unregister()`, estado lido de `.status` ao abrir a tela.

## Ordem

Tela + persistência de stale/showSystem → launch at login → teste em `/Applications` → ciclo logout/login.

## Riscos

| Risco | Mitigação |
|---|---|
| `SMAppService` falha com app ad-hoc fora de `/Applications` | erro inline orientando `./scripts/bundle.sh --install` |
| macOS pede aprovação em Login Items | `.requiresApproval` → mostrar `approve in System Settings` e abrir `SMAppService.openSystemSettingsLoginItems()` |

## Checkpoint

Checklist manual completo, incluindo logout/login real.
