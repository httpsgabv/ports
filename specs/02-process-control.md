# Spec 02: process-control

> Stack, comandos, estrutura, estilo e limites: ver [00-foundation](00-foundation.md). Usa `ListeningProcess` de [01-port-scanner](01-port-scanner.md).

## Objective

Ações sobre um processo listado: **matar** com segurança, **abrir** a porta no browser e **revelar** a pasta no Finder.

## Interface

```swift
public enum KillResult: Equatable, Sendable {
    case terminated        // morreu com SIGTERM
    case killed            // precisou de SIGKILL
    case alreadyGone       // não existia mais
    case pidReused         // PID agora é outro processo → não sinalizou
    case failed(String)    // EPERM etc.
}

public func kill(_ process: ListeningProcess, grace: Duration = .seconds(3)) async -> KillResult
```

Em `Ports` (app, usa AppKit):
- `open http://localhost:<port>` via `NSWorkspace.shared.open(URL)`.
- Revelar `cwd` via `NSWorkspace.shared.activateFileViewerSelecting([url])`.

## Comportamento do kill

1. **Verificar identidade:** reler o `lstart` do pid; se diferente de `process.startedAt` (±1s) → `.pidReused`, não envia sinal. Se não existir → `.alreadyGone`.
2. `kill(pid, SIGTERM)`. `EPERM` → `.failed("permission denied")`.
3. Poll `kill(pid, 0)` a cada 100ms até `grace`. Morreu → `.terminated`.
4. Senão `SIGKILL`, poll até 1s → `.killed`; se ainda vivo → `.failed("still running")`.

Sem confirmação (decidido). Mata **só o pid listado**, não o grupo; se o `npm run dev` pai sobrar, ele normalmente sai sozinho quando o filho morre.

## Acceptance criteria

- Processo comum morre com SIGTERM em < 3s → `.terminated`.
- Processo que ignora SIGTERM → `.killed` em ~3s.
- Pid inexistente → `.alreadyGone`, sem crash.
- Pid reutilizado (startedAt diferente) → `.pidReused`, **nenhum sinal enviado**.
- `kill` nunca bloqueia a main thread.

## Testing Strategy

- **Integração** com processos reais spawnados no teste:
  - `/bin/sleep 60` → `.terminated`.
  - `/bin/sh -c 'trap "" TERM; sleep 60'` → `.killed` (usar `grace: .milliseconds(300)` no teste).
  - pid de processo já finalizado → `.alreadyGone`.
  - `ListeningProcess` com `startedAt` falso → `.pidReused` e processo continua vivo.
- Abrir browser/Finder: verificação manual (é chamada direta de `NSWorkspace`).

## Boundaries

- **Always:** checar identidade antes de qualquer sinal.
- **Never:** sinalizar pid ≤ 1 ou o próprio pid do app; usar sudo.

## Success Criteria

- [ ] `swift test --filter Kill` verde (4 casos acima).
- [ ] Nenhum teste deixa processo órfão (`pgrep -f "sleep 60"` vazio após `swift test`).

## Open Questions

- Nenhuma.
