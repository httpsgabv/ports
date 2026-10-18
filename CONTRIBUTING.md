# Contributing to Ports

Thanks for taking the time to contribute! Ports is a small app with a strong opinion: **do one thing, stay tiny,
look sharp.** This guide explains how to work on it without fighting that.

## Table of contents

- [Ground rules](#ground-rules)
- [Getting started](#getting-started)
- [Workflow: spec first](#workflow-spec-first)
- [Code style](#code-style)
- [Testing](#testing)
- [Design rules](#design-rules)
- [Commits and pull requests](#commits-and-pull-requests)
- [Reporting bugs](#reporting-bugs)

## Ground rules

- **No new dependencies** without discussing it in an issue first. Everything today is the Swift standard library,
  Foundation, SwiftUI/AppKit and tools macOS already ships (`lsof`, `ps`, `docker`).
- **No elevated privileges.** Ports never uses `sudo` and never signals processes it doesn't own.
- **No network calls, no telemetry.**
- **Keep it cheap.** The idle cost (app + child processes) must stay **under 1% CPU**. If your change touches the
  scan loop, measure it (see [Testing](#testing)).
- Be kind in reviews and issues.

## Getting started

Requirements: macOS 26+, Xcode 26+ (Swift 6.2+).

```bash
git clone https://github.com/httpsgabv/ports.git
cd ports
swift build && swift test
./scripts/bundle.sh && open build/Ports.app
```

Run the app as a bundle (`build/Ports.app`), not with `swift run`: only the bundle has `LSUIElement`, which keeps
it out of the Dock.

> [!TIP]
> If you already have Ports installed, quit it first (`pkill -x Ports`). Two copies share the same preferences.

## Workflow: spec first

Every capability has a numbered spec and a task list:

```
CAPABILITY-MAP.md            index of modules, dependencies and build order
specs/NN-<module>.md         what and why: objective, acceptance criteria, boundaries
tasks/NN-<module>/plan.md    how: components, order, risks
tasks/NN-<module>/todo.md    checklist with acceptance + verify steps per task
```

The existing specs are written in Portuguese; new ones may be in English or Portuguese.

- **Bug fix or small tweak:** no spec needed. Fix it at the root cause and add a test that fails without the fix.
- **New feature or behavior change:** open an issue first. If it's accepted, add the next numbered spec
  (`specs/11-<module>.md`) and its `tasks/` folder, update the capability map, then implement.
- **Decision changed while implementing?** Update the spec in the same PR. The spec is the source of truth, not the code.

## Code style

```swift
/// Um processo (ou container Docker) ouvindo em uma ou mais portas TCP.
public struct ListeningProcess: Identifiable, Hashable, Sendable {
    public var id: String { container.map { "c:\($0.id)" } ?? "\(pid)" }
    public internal(set) var ports: [UInt16]   // sorted, IPv4/IPv6 deduplicated
    // …
}
```

- **Logic lives in `PortsCore`**, UI lives in `Ports`. `PortsCore` never imports SwiftUI.
- **Parsers are pure functions** (`String -> [T]`), separate from the code that runs the process, so they can be
  tested against real captured output.
- Value types (`struct`, `Sendable`). UI state lives in a single `@Observable @MainActor` store.
- **No speculative abstractions:** no protocol with one implementation, no factory for one product, no config for
  a value that never changes. Test the parser, not a mock.
- Names in English. Comments explain *why*, not *what*. Mark deliberate shortcuts with a known ceiling with
  `// ponytail:` plus the upgrade path.
- Swift 6 strict concurrency. Never block the main thread; shell calls go through `run()` in `Shell.swift`.

## Testing

```bash
swift test                               # everything
swift test --filter ParserTests          # one suite
swift test --filter DockerIntegration    # needs Docker running + caddy:2-alpine locally
```

- **Unit tests** use real output captured from `lsof`, `ps` and `docker` (see `Tests/PortsCoreTests/Fixtures.swift`).
  Add a fixture when you find output the parser doesn't handle.
- **Integration tests** open real sockets and spawn real processes. They must clean up after themselves:
  `pgrep -f "sleep 60"` must be empty after `swift test`.
- **UI changes** are verified manually. Describe what you checked in the PR, with a screenshot when it changes visually.
- **Performance:** if you touch the scan loop, measure the idle cost of the app *and* its child processes
  (`top` does not see `lsof`/`ps`). Compare `ps -o time=` of the app over 60s, plus `getrusage(RUSAGE_CHILDREN)`
  around a few `scan(reusing:)` calls.

## Design rules

The look is tech-minimal (think Vercel, X, SpaceX): **dark only, pure black, hairlines, no decoration.**

| Token | Value | Only for |
|---|---|---|
| `bg` | `#000000` | background |
| `surface` | `#0A0A0A` | hover / expanded row |
| `border` | `#1F1F1F` | 0.5pt hairlines |
| `textPrimary` / `textSecondary` / `textTertiary` | `#EDEDED` / `#888888` / `#555555` | text hierarchy |
| `live` | `#00E676` | running status dot |
| `stale` | `#F5A623` | idle too long |
| `danger` | `#FF4D4D` | kill hover, errors |

- **Color only with meaning.** New colors need a reason and an issue.
- System font only (`Theme.font`), with monospaced digits so numbers don't jitter when they update.
- Labels in CAPS, 10pt, +1 tracking (`CapsLabel`).
- Animations of 200ms or less. **No modals.**
- `.buttonStyle(.plain)` only hit-tests opaque pixels: always add `.contentShape(Rectangle())` to plain buttons.
- Every interactive element needs an accessibility label.

## Commits and pull requests

Commits follow [Conventional Commits](https://www.conventionalcommits.org/), scoped by module id from the capability map:

```
feat(docker-containers): group kill stops the whole compose stack
fix(ui): make plain-style buttons clickable over their whole frame
docs(preferences): reopen persistence criterion pending re-check
```

Before opening a PR:

- [ ] `swift build` has no warnings and `swift test` passes
- [ ] New logic has a test that fails without it
- [ ] The spec and `todo.md` are updated if behavior or a decision changed
- [ ] Idle CPU is still under 1% (if you touched the scan loop)
- [ ] Screenshot attached for visual changes
- [ ] No new dependency, `sudo`, or network call

Keep PRs focused: one capability or one fix per PR.

## Reporting bugs

Open an issue with:

1. What you did, what you expected, and what happened
2. macOS version (`sw_vers`) and how you installed Ports
3. For process/port issues, the relevant line from `lsof -nP -iTCP -sTCP:LISTEN`
4. For kill issues, the app log:

   ```bash
   /usr/bin/log show --last 10m --predicate 'subsystem == "dev.gabriel.ports"' --style compact
   ```

Check the output for paths or project names you don't want to share before posting it.
