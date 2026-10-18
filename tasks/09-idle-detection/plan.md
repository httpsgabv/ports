# Plan 09: idle-detection

Spec: [specs/09-idle-detection.md](../../specs/09-idle-detection.md)

## Componentes

1. `parseLsofListen` → `parseLsofTCP`: separa as linhas `n` com `->` (conexões) das sem `->` (LISTEN). Retorna portas em LISTEN e a contagem de conexões de entrada por pid (porta local ∈ portas em LISTEN do mesmo pid).
2. `scan`: troca `-sTCP:LISTEN` por `-sTCP:LISTEN,ESTABLISHED`. `inboundConnections` é atualizado **também** nos PIDs reusados (como as portas).
3. Containers (se a spec 08 já existir): conexões na porta do host → container dono da porta.
4. `PortStore`: `lastActive`, `idleSince`, novo `isStale`.
5. UI: meta `up · idle` / `up · N conn`; label `IDLE FOR` nas preferências.

## Ordem (TDD)

Fixture real LISTEN+ESTABLISHED → parser → integração com cliente conectado → store → UI → medir CPU.

## Riscos

| Risco | Mitigação |
|---|---|
| **Linha de conexão vira porta falsa** (o parser atual pega o sufixo após o último `:`; `a:58996->b:58445` viraria a porta 58445) | separar por `->` **antes** de trocar o comando; teste específico com essa fixture |
| Processo com só uma conexão de saída aparece como "listening" | só pids com pelo menos um LISTEN entram na lista |
| Saída do `lsof` maior | medido em 17/out: 22ms vs 20ms de CPU por chamada; re-medir no checkpoint |

## Checkpoint

Vite com aba aberta não fica âmbar; fechando a aba, o idle conta; CPU < 1%.
