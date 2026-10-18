# Capability Map: Ports

App de menu bar para macOS que mostra quais processos estão ouvindo em portas TCP e permite matá-los.
Problema: servidores de dev esquecidos rodando e consumindo recursos sem que eu perceba.

| # | Module id | Responsabilidade | Depende de |
|---|---|---|---|
| 00 | `foundation` | Pacote SwiftPM, bundle `.app`, app só na menu bar (sem Dock), tokens de design, convenções | — |
| 01 | `port-scanner` | Descobre processos em TCP LISTEN + detalhes (cwd, uptime, CPU, mem, comando) e classifica sistema/usuário | foundation |
| 02 | `process-control` | Kill SIGTERM→SIGKILL seguro contra reuso de PID, abrir `localhost:PORTA` no browser, revelar pasta no Finder | port-scanner |
| 03 | `live-status` | Store com polling de 5s, contador no ícone da menu bar, filtro de sistema, detecção de "esquecido" | port-scanner |
| 04 | `port-list-ui` | Popover: lista minimalista, linha por processo, expandir detalhes, ações | live-status, process-control |
| 05 | `preferences` | Limite de "esquecido" (padrão 2h), mostrar processos de sistema, iniciar no login, persistência | live-status, port-list-ui |

**Build order:** `foundation` → `port-scanner` → `process-control` ∥ `live-status` → `port-list-ui` → `preferences`

## Índice

- Specs: [`specs/`](specs/) — `NN-<module-id>.md`
- Plano e tarefas: [`tasks/NN-<module-id>/plan.md`](tasks/) e `todo.md`

## Fora do escopo (decidido na entrevista)

UDP, conexões ESTABLISHED, notificações do sistema, kill all, atalho global, busca/filtro, tema claro, App Store/notarização.
