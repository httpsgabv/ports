# Spec 01: port-scanner

> Stack, comandos, estrutura, estilo e limites: ver [00-foundation](00-foundation.md).

## Objective

Função `scan()` em `PortsCore` que retorna a lista de processos **do usuário atual** ouvindo em portas TCP, com os detalhes necessários para decidir "isso pode morrer?".

## Data contract

```swift
public struct ListeningProcess: Identifiable, Hashable, Sendable {
    public let pid: Int32
    public let name: String            // "node", "postgres", "Raycast"
    public let ports: [UInt16]         // ordenado asc, dedupe IPv4/IPv6
    public let startedAt: Date         // identidade (anti reuso de PID) + uptime
    public let cpuPercent: Double      // %cpu do ps
    public let memoryBytes: UInt64     // RSS
    public let command: String         // linha de comando completa
    public let executablePath: String  // `comm` do ps (pode ser relativo, ex: "node")
    public let cwd: String?            // pasta do projeto; nil se indisponível
    public let isSystem: Bool
}

public func scan() async throws -> [ListeningProcess]   // ordenado por menor porta
```

## Fonte de dados (sem sudo, sem dependências)

| Dado | Comando | Notas |
|---|---|---|
| pid, nome, portas | `lsof -nP -iTCP -sTCP:LISTEN -Fpcn` | ~50ms. Campos `p`/`c`/`n`; porta = sufixo após último `:` de `n` |
| início, cpu, rss, exe | `ps -o pid=,lstart=,%cpu=,rss=,comm= -p <pids>` | `lstart` = 5 tokens fixos (`Sat Oct 17 21:15:53 2026`); `comm` = resto da linha (pode ter espaços) |
| comando | `ps -o pid=,command= -p <pids>` | resto da linha após o pid |
| cwd | `lsof -a -d cwd -p <pids> -Fpn` | |

`ps` do macOS **não** tem `etimes`: usar `lstart` com `DateFormatter` `en_US_POSIX`, formato `EEE MMM d HH:mm:ss yyyy`.

**Classificação `isSystem`:** `executablePath` começa com `/System/`, `/usr/libexec/`, `/usr/sbin/`, `/sbin/` **ou** `/Applications/` (apps GUI tipo Raycast, Logi Options+ não são "projetos"). Caminhos relativos (`node`, `python3`) e `/usr/bin/`, `/opt/homebrew/`, `/usr/local/` → usuário.

## Acceptance criteria

- Processo com várias portas (IPv4+IPv6 na mesma porta, ou 3000+3001) vira **um** `ListeningProcess` com `ports` deduplicado e ordenado.
- Processo que morre entre o `lsof` e o `ps` é descartado silenciosamente (não lança erro).
- `lsof` sem resultados (exit 1, saída vazia) → `[]`, não erro.
- Falha real ao executar um binário → `throw` com mensagem legível.
- Pipeline completo < 300ms na minha máquina.

## Testing Strategy

- **Unit (fixtures reais):** `parseLsofListen`, `parsePsDetails`, `parsePsCommand`, `parseLsofCwd`, `isSystemPath`, merge final.
  - Casos: IPv6 `[::1]:5174`, `*:7000`, dedupe v4/v6, `comm` com espaços (`/Applications/Logi Options+.app/...`), pid ausente no ps.
- **Integração:** teste abre um socket TCP listening numa porta efêmera (`bind` porta 0) e verifica que `scan()` retorna o próprio pid do teste com essa porta.

## Boundaries

- **Always:** parsers puros e separados do `Process` runner.
- **Never:** usar sudo; listar ESTABLISHED/UDP (fora do escopo).
- **Ask first:** trocar CLI por `libproc` (só se o custo de spawn incomodar).

## Success Criteria

- [ ] `swift test --filter Scanner` verde.
- [ ] Com `python3 -m http.server 8765` rodando de `~/tmp/x`, `scan()` retorna `python3`, `[8765]`, `cwd == ~/tmp/x`, `isSystem == false`.
- [ ] `ControlCenter` e `rapportd` vêm com `isSystem == true`.

## Open Questions

- Nenhuma.
