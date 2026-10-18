# Spec 04: port-list-ui

> Stack, comandos, estrutura, estilo, **design tokens**: ver [00-foundation](00-foundation.md). Estado de [03-live-status](03-live-status.md), ações de [02-process-control](02-process-control.md).

## Objective

O popover que aparece ao clicar no ícone: em um olhar, saber **o que** está rodando, **de qual projeto**, **há quanto tempo**, e matar com um clique.

## Layout (380pt de largura, altura máx. 520pt com scroll)

```
┌──────────────────────────────────────────────┐
│ PORTS                              3 ACTIVE  │  header: labels CAPS 10pt tertiary
├──────────────────────────────────────────────┤
│ ● node                     :5174       [ × ] │  linha (1 por processo)
│   ~/dev/yt-city · 39m · 0.3% · 16 MB         │  metadados secondary, mono
├──────────────────────────────────────────────┤
│▌● postgres                 :5432       [ × ] │  stale: barra 2pt âmbar à esquerda
│▌  ~/dev/api · 26h 4m · 0.0% · 48 MB          │         + uptime em âmbar
├──────────────────────────────────────────────┤
│ ● next-server          :3000 :3001     [ × ] │  expandida ↓
│   ~/dev/site · 12m · 4.1% · 312 MB           │
│   PID 47102                                  │
│   node …/next dev --port 3000                │  comando completo, mono, 2 linhas + truncate
│   [ OPEN ↗ ]  [ FINDER ]                     │
├──────────────────────────────────────────────┤
│ ⚙                          updated 2s · QUIT │  footer
└──────────────────────────────────────────────┘
```

## Comportamento

- **Linha:** dot `live` verde, nome, portas como chips mono à direita, botão `×`.
- **Clicar na linha** expande/colapsa (uma por vez). Hover = fundo `surface`.
- **Clicar numa porta** abre `http://localhost:<porta>`.
- **`×`:** ao passar o mouse vira `danger`; ao clicar vira spinner, chama `kill`; sucesso → linha sai com fade e `store.remove(pid)`; falha → texto vermelho inline curto (`permission denied`) por 3s.
- **cwd:** `$HOME` abreviado para `~`; nil → omitido. `FINDER` só aparece se houver cwd.
- **Uptime:** `12m`, `3h 05m`, `2d 4h`. Memória: `16 MB`, `1.2 GB`. CPU: `0.3%`.
- **Vazio:** centro com `NO OPEN PORTS` tertiary.
- **Erro de scan:** linha discreta no footer `scan failed · retrying`.
- `⚙` abre a tela de preferências (spec 05); nesta spec, pode ser um placeholder.
- Esc fecha o popover.

## Acceptance criteria

- Visual bate com os tokens da spec 00 (preto puro, hairlines, mono nos números, sem cor fora de live/stale/danger).
- Kill pelo `×` remove a linha em < 4s e o contador do ícone atualiza junto.
- Lista com 20 processos rola suave, sem layout quebrado com nomes/caminhos longos (truncamento no meio para paths).
- Navegável por VoiceOver: cada linha anuncia nome, portas e uptime; `×` tem label "Kill <name>".

## Testing Strategy

- **Unit (PortsCore):** formatadores `formatUptime`, `formatBytes`, `abbreviateHome` com casos de borda (0s, 59m, 24h, 1023 MB…).
- **Manual:** checklist visual no `todo.md`, com 3+ processos reais (vite, http.server, um processo que ignora SIGTERM).

## Boundaries

- **Ask first:** qualquer cor nova ou fonte externa.
- **Never:** animações > 200ms; modais de confirmação (decidido: sem confirmação).

## Success Criteria

- [x] Formatadores testados.
- [x] Checklist visual e de interação ok (visual, expandir, portas, Finder, kill com SIGTERM e com escalonamento).
- [x] Popover aprovado por mim.
- [ ] VoiceOver e Esc para fechar: ainda não verificados.

## Open Questions

- Nenhuma.
