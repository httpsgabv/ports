# Spec 09: idle-detection

> Stack, comandos, estrutura, estilo: ver [00-foundation](00-foundation.md). Muda a definição de stale de [03-live-status](03-live-status.md) e o ajuste de [05-preferences](05-preferences.md).

## Objective

"Rodando há mais de 2h" não significa "esquecido": um servidor com a aba aberta e HMR conectado está em uso. Quero que o âmbar signifique **ninguém usa isso há X horas**.

## Sinal de atividade

Uma **conexão TCP de entrada estabelecida** numa das portas do processo (`127.0.0.1:5173->127.0.0.1:61234`, cujo pid dono é o próprio processo). Ela cobre aba do browser com HMR/websocket, app conectado no Postgres e cliente conectado no Redis.

- Coleta no **mesmo spawn** do tick: `lsof -nP -iTCP -sTCP:LISTEN,ESTABLISHED -Fpcn`. Não é um `lsof` extra.
- Só contam conexões de entrada: porta local ∈ portas em LISTEN do processo. Conexões de saída (o server chamando uma API) não contam.
- Containers (spec 08): conexões de entrada na porta do host, pelo PID do runtime.
- CPU **não** entra (com o popover fechado ela vem do cache e estaria velha).

## Modelo

```swift
// novo campo em ListeningProcess
public let inboundConnections: Int

// PortStore
private var lastActive: [String: Date]      // por ListeningProcess.id; em memória
func idleSince(_ p: ListeningProcess) -> Date   // lastActive[p.id] ?? p.startedAt
func isStale(_ p: ListeningProcess) -> Bool     // now - idleSince ≥ threshold
```

- A cada tick: `inboundConnections > 0` → `lastActive[id] = now`.
- Ao abrir o app, todos começam como ativos no `startedAt` (sem histórico). Isso é conservador, porque um processo antigo e sem conexão já nasce stale, igual ao comportamento atual.

## UI

- Meta: `up 5h 10m · idle 2h 05m` quando ocioso; `up 5h 10m · 2 conn` quando ativo.
- O âmbar passa a usar `idle` e não `up`.
- Preferências: o label `STALE AFTER` vira `IDLE FOR`. A mesma chave `staleHours` continua, então não há migração.

## Acceptance criteria

- Vite com a aba aberta (HMR conectado) há 3h → **não** fica âmbar, e a meta mostra `1 conn`.
- Fechar a aba → `idle` começa a contar; com `IDLE FOR` = 1h, fica âmbar 1h depois.
- Custo ocioso continua < 1% de CPU, porque é o mesmo spawn de `lsof` (re-medir: a saída fica maior).

## Testing Strategy

- **Unit:** parser de `lsof` com LISTEN + ESTABLISHED (fixture real: entrada, saída e browser com conexões que não são do processo) → `inboundConnections` correto; `isStale` com `lastActive` simulado (`now` injetado).
- **Integração:** socket em LISTEN + cliente conectado no próprio teste → `inboundConnections == 1`; fecha o cliente → 0.
- **Manual:** vite + aba aberta/fechada.

## Boundaries

- **Ask first:** persistir `lastActive` em disco.
- **Never:** um `lsof` extra por tick.

## Success Criteria

- [ ] Testes de parser, integração e stale verdes.
- [ ] CPU ociosa re-medida < 1%.
- [ ] Checklist manual da aba aberta/fechada.

## Open Questions

- Nenhuma.
