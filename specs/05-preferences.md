# Spec 05: preferences

> Stack, comandos, estrutura, estilo: ver [00-foundation](00-foundation.md). Configura [03-live-status](03-live-status.md); acessada pelo `⚙` de [04-port-list-ui](04-port-list-ui.md).

## Objective

Três ajustes, persistidos, sem janela separada: a tela de preferências substitui a lista **dentro do próprio popover** (com `← BACK`). Janela de Settings em app sem Dock é frágil; inline é mais simples e mais coerente com o visual.

## Ajustes

| Label (UI) | Tipo | Padrão | Persistência |
|---|---|---|---|
| `STALE AFTER` | Stepper 1–48h | 2h | `@AppStorage("staleHours")` |
| `SHOW SYSTEM PROCESSES` | Toggle | off | `@AppStorage("showSystem")` |
| `LAUNCH AT LOGIN` | Toggle | off | `SMAppService.mainApp` (estado lido do sistema, não do UserDefaults) |

## Comportamento

- Mudanças aplicam na hora (o contador do ícone e o destaque âmbar reagem sem reiniciar).
- `LAUNCH AT LOGIN`: `register()`/`unregister()`; se falhar (ex: app fora de `/Applications`), o toggle volta e mostra `move app to /Applications` em `danger` pequeno.
- Footer da tela: versão do app em tertiary.

## Acceptance criteria

- Mudar `STALE AFTER` para 1h destaca na hora processos com > 1h.
- Ligar `SHOW SYSTEM PROCESSES` mostra ControlCenter/rapportd e atualiza o contador.
- Valores sobrevivem a quit + reabrir.
- Com o app em `/Applications`, `LAUNCH AT LOGIN` on → aparece em System Settings › General › Login Items; após logout/login, o app sobe sozinho.

## Testing Strategy

- **Manual:** checklist no `todo.md` (é cola entre `@AppStorage`, `SMAppService` e o store; não há lógica própria para teste unitário).

## Boundaries

- **Ask first:** adicionar qualquer ajuste além dos três.
- **Never:** guardar estado de login no UserDefaults (fonte da verdade é o `SMAppService.status`).

## Success Criteria

- [ ] Checklist manual completo, incluindo um ciclo real de logout/login.

## Open Questions

- Nenhuma.
