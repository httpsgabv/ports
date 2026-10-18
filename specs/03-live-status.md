# Spec 03: live-status

> Stack, comandos, estrutura, estilo e limites: ver [00-foundation](00-foundation.md). Consome `scan()` de [01-port-scanner](01-port-scanner.md).

## Objective

Manter o estado atual em memória e mostrar **passivamente** no ícone da menu bar quantos processos estão ouvindo, para que eu perceba sem abrir nada que algo ficou rodando.

## Interface

```swift
@Observable @MainActor
final class PortStore {
    private(set) var processes: [ListeningProcess] = []   // já filtrado
    private(set) var lastError: String?
    private(set) var lastScan: Date?
    var showSystem = false                                 // 05 persiste
    var staleThreshold: TimeInterval = 2 * 3600            // 05 persiste

    func refresh() async
    func isStale(_ p: ListeningProcess) -> Bool
    func remove(_ pid: Int32)                              // remoção otimista pós-kill
}
```

## Comportamento

- **Polling a cada 5s** desde o launch (`Task` com `try await Task.sleep`), mais `refresh()` imediato ao abrir o popover.
- Scans não se sobrepõem: se um ainda está rodando, o tick é pulado.
- **Cache por PID (custo):** com o popover fechado, `scan(reusing:)` roda só o `lsof` de LISTEN e busca detalhes apenas de PIDs novos (~34ms CPU/tick ≈ 0,7%). Popover aberto → scan completo (cpu/mem ao vivo). Sem cache, cada tick custava ~107ms de CPU em processos filhos (~2%). Upgrade se precisar: `libproc` (zero spawns).
- Filtro: `showSystem == false` esconde `isSystem == true`.
- Erro de scan: mantém a última lista, guarda `lastError`; próxima tentativa no próximo tick.
- **Ícone:** SF Symbol + contador em SF Mono (`3`). Com 0 processos: só o símbolo, opacidade reduzida. Se qualquer processo visível estiver stale: o contador fica em `stale` (âmbar).

## Acceptance criteria

- Subir `python3 -m http.server 8765` → contador incrementa em ≤ 5s sem abrir o popover.
- Matar pelo terminal → contador decrementa em ≤ 5s.
- Processos de sistema não contam no ícone quando `showSystem == false`.
- CPU média ociosa < 1% **incluindo os processos filhos** (`lsof`/`ps`), que o `top -pid` não enxerga.

## Testing Strategy

- **Unit:** lógica de filtro e stale como funções puras em `PortsCore` (`visible(_:showSystem:)`, `isStale(now:threshold:)`), testadas com fixtures.
- **Manual:** checklist no `todo.md` (contador, cor âmbar, CPU).

## Boundaries

- **Always:** `scan()` fora da main thread.
- **Never:** polling < 2s.

## Success Criteria

- [x] Testes de filtro/stale verdes (+ teste de reuso do cache).
- [x] Checklist manual do contador ok.
- [x] < 1% CPU ocioso: app 0,07% (`ps -o time` em 60s) + filhos ~0,7% (34ms/5s) ≈ 0,75%.

## Open Questions

- Nenhuma.
