# Spec 06: project-identity

> Stack, comandos, estrutura, estilo e limites: ver [00-foundation](00-foundation.md). Estende [01-port-scanner](01-port-scanner.md), [02-process-control](02-process-control.md) e [04-port-list-ui](04-port-list-ui.md).

## Objective

Hoje três vites do mesmo projeto aparecem como três linhas `node`. Quero ver **o que** cada processo é (`VITE`, `NEXT`, `POSTGRES`) e **de qual projeto** ele é, com os processos do mesmo projeto agrupados e um kill que derruba o projeto inteiro.

## Data contract

```swift
public struct Project: Hashable, Sendable {
    public let root: String   // raiz do git; senão o próprio cwd
    public let name: String   // "name" do package.json da raiz; senão nome da pasta
}

// novos campos em ListeningProcess
public let project: Project?    // nil quando cwd é nil
public let kind: String?        // "VITE", "NEXT"…; nil = usar `name`

public struct ProcessGroup: Identifiable, Sendable {
    public let id: String                   // project.root, ou "pid:<pid>" sem projeto
    public let project: Project?
    public let processes: [ListeningProcess]
}

public func groupByProject(_ processes: [ListeningProcess]) -> [ProcessGroup]   // ordem: menor porta do grupo
```

## Regras

**Projeto:** sobe a partir do `cwd` até achar um `.git` (pasta ou arquivo, para cobrir worktrees). Se não achar, usa o próprio `cwd`. O nome vem do `"name"` do `package.json` da raiz (JSON inválido → ignora); se não houver, é o último componente do caminho. Resultado cacheado por `cwd`, e só PIDs novos pagam o I/O (mesma lógica do `scan(reusing:)`).

**Kind**, por regex na linha de comando, em ordem (o primeiro que casa ganha):

| Kind | Casa com |
|---|---|
| `VITE` | `/vite(\.js)?\b` ou `\bvite\b` |
| `NEXT` | `\bnext(-server)?\b` |
| `NUXT` | `\bnuxt\b` |
| `ASTRO` | `\bastro\b` |
| `REMIX` | `\bremix\b` |
| `STORYBOOK` | `\bstorybook\b` |
| `EXPO` | `\bexpo\b` ou `\bmetro\b` |
| `WEBPACK` | `webpack(-dev-server)?` |
| `RAILS` | `\brails\b` ou `\bpuma\b` |
| `DJANGO` | `manage\.py runserver` |
| `UVICORN` | `\buvicorn\b` |
| `FLASK` | `\bflask\b` |
| `HTTP.SERVER` | `http\.server` |
| `POSTGRES` | executável `postgres` |
| `REDIS` | executável `redis-server` |
| `MYSQL` | executável `mysqld` |
| `MONGO` | executável `mongod` |

Sem match → `nil`, e a UI mostra o `name` do processo como hoje.

## UI

- **Grupo com 1 processo:** linha normal. O título é `kind ?? name`, e a meta mostra o nome do projeto no lugar do caminho completo.
- **Grupo com ≥ 2 processos:** linha de grupo `yt-city` · `3 SERVERS` · soma da memória · chips com todas as portas · `×`. Clicar expande e mostra as linhas filhas (as mesmas de hoje, indentadas). O caminho completo continua no detalhe expandido.
- **`×` do grupo:** chama `terminate` em todos os processos em paralelo, **sem confirmação** (decidido). Se algum falhar, mostra o erro inline na linha do grupo (`1 of 3 failed: permission denied`).
- Processo **sem projeto** (sem cwd): sempre linha avulsa.
- Stale (âmbar) do grupo: se qualquer filho estiver stale.

## Acceptance criteria

- 3 vites em `~/dev/yt-city` → 1 linha `yt-city`, `3 SERVERS`, com `:5173 :5174 :5175`.
- Monorepo: processos em `apps/web` e `apps/api` do mesmo repo → mesmo grupo.
- `python3 -m http.server` numa pasta sem git → linha avulsa, kind `HTTP.SERVER`, projeto = nome da pasta.
- Kill do grupo derruba os 3 em < 4s, e a linha some.
- Custo ocioso continua < 1% de CPU: a resolução de projeto só roda para PIDs novos.

## Testing Strategy

- **Unit:** `detectKind(command:executable:)` com uma tabela de comandos reais (`vite.js --port 5174`, `next-server`, `.../postgres -D ...`, `manage.py runserver`); `groupByProject` com fixtures (1 grupo de 3, avulso sem cwd, ordem por porta).
- **Integração:** `resolveProject(cwd:)` sobre diretórios temporários (com `.git` pasta, `.git` arquivo, sem git, `package.json` válido/inválido/ausente, subpasta de monorepo).
- **Manual:** 3 servidores no mesmo repo + 1 avulso; kill do grupo.

## Boundaries

- **Always:** I/O de projeto fora da main thread e só para PIDs novos.
- **Ask first:** ler outros manifests além do `package.json` (`Cargo.toml`, `pyproject.toml`…).
- **Never:** subir além de `$HOME` procurando `.git`.

## Success Criteria

- [ ] Testes de kind, agrupamento e resolução de projeto verdes.
- [ ] Checklist manual de agrupamento e kill do grupo ok.
- [ ] CPU ociosa re-medida < 1%.

## Open Questions

- Nenhuma.
