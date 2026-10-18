# Plan 00: foundation

Spec: [specs/00-foundation.md](../../specs/00-foundation.md)

## Componentes

1. `Package.swift`: library `PortsCore`, executable `Ports` (depende de PortsCore), test target `PortsCoreTests`. `platforms: [.macOS(.v26)]`.
2. `Resources/Info.plist`: `LSUIElement=YES`, `CFBundleIdentifier=dev.gabriel.ports`, `CFBundleExecutable=Ports`, versão.
3. `scripts/bundle.sh`: `swift build -c release` → monta `build/Ports.app/Contents/{MacOS,Info.plist}` → `codesign --force -s - build/Ports.app` → `--install` copia para `/Applications`.
4. `Sources/Ports/PortsApp.swift`: `@main` com `MenuBarExtra(...){ RootView() }.menuBarExtraStyle(.window)`.
5. `Sources/Ports/Theme.swift`: tokens de cor/fonte da spec.

## Ordem

Package → Theme + App mínimo → Info.plist + bundle.sh → verificar Dock/⌘Tab.

## Riscos

| Risco | Mitigação |
|---|---|
| Executável SwiftPM puro mostra ícone no Dock | Só rodar via `.app` com `LSUIElement`; `swift run` é só para debug |
| `MenuBarExtra(.window)` sem estilo preto total (material do sistema) | `.background(Theme.bg)` + `.preferredColorScheme(.dark)`; validar visualmente cedo |

## Checkpoint

App bundle abre, ícone na menu bar, popover preto, Quit funciona, `swift test` verde.
