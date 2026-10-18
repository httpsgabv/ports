# Spec 00: foundation

> Módulo base. Define stack, comandos, estrutura, estilo e limites **compartilhados por todas as specs** (01–05 referenciam esta).

## Objective

Ter um app nativo que roda na menu bar do macOS, sem ícone no Dock, com um ícone e um item "Quit", buildável e testável por linha de comando. É o esqueleto onde os outros módulos se encaixam.

**Usuário:** eu (dev solo, uso pessoal, uma máquina).

**Critérios de aceite:**
- `./scripts/bundle.sh` gera `build/Ports.app` assinado ad-hoc.
- Abrir o `.app` mostra um ícone na menu bar e **nenhum** ícone no Dock nem no ⌘Tab.
- Clicar no ícone abre um popover (`MenuBarExtra` estilo `.window`) preto com o texto `PORTS` e um botão `QUIT` funcional.
- `swift test` roda e passa (mesmo que só com um teste trivial nesta fase).

## Tech Stack

| Item | Escolha | Motivo |
|---|---|---|
| Linguagem | Swift 6.4 (strict concurrency) | Nativo, leve |
| UI | SwiftUI `MenuBarExtra(.window)` | API oficial de menu bar desde macOS 13 |
| Alvo | macOS 26+ | Só a minha máquina |
| Build | Swift Package Manager (sem `.xcodeproj`) | Tudo por CLI, diff legível |
| Testes | Swift Testing (`import Testing`) | Já vem no toolchain |
| Dependências externas | **nenhuma** | `lsof`/`ps`/`Darwin`/`AppKit` cobrem tudo |

## Commands

```bash
swift build                      # build debug
swift test                       # testes do PortsCore
./scripts/bundle.sh              # release + monta build/Ports.app + codesign ad-hoc
./scripts/bundle.sh --install    # idem + copia para /Applications (necessário p/ launch at login)
open build/Ports.app             # roda
```

## Project Structure

```
Package.swift
Sources/
  PortsCore/        → lógica pura e testável (scanner, parsing, kill, classificação). Sem SwiftUI.
  Ports/            → app SwiftUI (App, Store, Views, Theme). Fino; depende de PortsCore.
    Views/
Tests/
  PortsCoreTests/   → testes unitários + integração do PortsCore
Resources/
  Info.plist        → LSUIElement=YES, bundle id dev.gabriel.ports
scripts/
  bundle.sh         → monta o .app a partir do binário release
specs/              → specs numeradas
tasks/NN-module/    → plan.md + todo.md por spec
```

## Code Style

```swift
import Foundation

/// Um processo ouvindo em uma ou mais portas TCP.
public struct ListeningProcess: Identifiable, Hashable, Sendable {
    public var id: Int32 { pid }
    public let pid: Int32
    public let name: String
    public let ports: [UInt16]          // ordenado, sem duplicatas IPv4/IPv6
    public let startedAt: Date

    public func isStale(now: Date = .now, threshold: TimeInterval) -> Bool {
        now.timeIntervalSince(startedAt) >= threshold
    }
}
```

- Tipos `struct` + `Sendable`; estado de UI em uma única classe `@Observable @MainActor`.
- Parsing é **função pura** `String -> [T]` para testar com fixtures, separada de quem executa o processo.
- Nomes em inglês; sem abstrações com uma implementação só (nada de `ScannerProtocol` "para testes"; testamos o parser).
- Sem comentários óbvios. `// ponytail:` marca simplificações deliberadas com teto conhecido.

### Design tokens (Theme.swift)

Inspiração: Vercel / X / SpaceX / Tesla. **Dark only.** Cor só com significado.

| Token | Valor | Uso |
|---|---|---|
| `bg` | `#000000` | fundo do popover |
| `surface` | `#0A0A0A` | hover/linha expandida |
| `border` | `#1F1F1F` | separadores hairline (0.5pt) |
| `textPrimary` | `#EDEDED` | nome do processo, portas |
| `textSecondary` | `#888888` | metadados |
| `textTertiary` | `#555555` | labels em caixa alta |
| `live` | `#00E676` | dot de status "rodando" |
| `stale` | `#F5A623` | processo "possivelmente esquecido" |
| `danger` | `#FF4D4D` | kill (só no hover/ação) |

Tipografia: só a fonte do sistema (SF Pro) via `Theme.font`, com `.monospacedDigit()` para números não mudarem de largura ao atualizar. Labels em CAPS, 10pt, tracking +1. Sem sombras, sem gradientes, cantos 6pt, ícones SF Symbols em peso `.light`.

## Testing Strategy

- `PortsCoreTests` com Swift Testing.
- **Unitário:** parsers com fixtures de saída real de `lsof`/`ps` (copiadas desta máquina).
- **Integração:** abrir um socket real/spawnar processo real dentro do teste e verificar que o scanner/killer funciona de ponta a ponta.
- UI (`Ports` target): verificação manual guiada por checklist em cada `todo.md`. Sem snapshot tests (YAGNI).

## Boundaries

- **Always:** `swift build && swift test` verdes antes de concluir uma task; manter lógica em `PortsCore`; atualizar a spec se uma decisão mudar.
- **Ask first:** adicionar qualquer dependência (incl. fontes como Geist); mudar target do macOS; usar sudo/privilégios elevados; adicionar entitlements/sandbox.
- **Never:** matar processos de outros usuários/root; rodar com sudo; enviar dados para a rede; commitar `build/`.

## Success Criteria

- [x] `swift build` e `swift test` passam.
- [x] `./scripts/bundle.sh && open build/Ports.app` mostra ícone na menu bar, sem Dock.
- [x] Popover preto abre/fecha ao clicar; `QUIT` encerra o app.
- [x] App ocioso usa < 30 MB de memória real (`footprint -p $(pgrep -x Ports)` → 14 MB). RSS (~75 MB) conta frameworks compartilhados e não serve como métrica.

## Open Questions

- Nome final do app e ícone da menu bar: proposta `Ports` + SF Symbol `point.3.connected.trianglepath.dotted`. Decido visualmente na task.
