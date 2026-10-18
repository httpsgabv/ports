# Spec 08: docker-containers

> Stack, comandos, estrutura, estilo: ver [00-foundation](00-foundation.md). Estende [01-port-scanner](01-port-scanner.md) e [02-process-control](02-process-control.md); agrupa via [06-project-identity](06-project-identity.md).

## Objective

Um Postgres ou Redis rodando em Docker hoje é **invisível**. A porta pertence ao `com.docker.backend`, que é um `.app` e por isso cai no filtro de sistema. Quero ver cada container que publica portas como uma linha própria, com nome, imagem e projeto, e pará-lo com um clique.

## Detecção (só paga quando há Docker)

1. O `lsof` de LISTEN encontra um processo cujo executável é de um runtime conhecido: `com.docker.backend` (Docker Desktop), `OrbStack Helper` (OrbStack) ou `limactl`/`ssh` com cwd em `~/.colima` / `~/.lima` (Colima/Lima).
2. Só então roda:
   `docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.CreatedAt}}\t{{.Label "com.docker.compose.project"}}\t{{.Label "com.docker.compose.project.working_dir"}}'`
3. O binário `docker` é procurado em `/usr/local/bin`, `/opt/homebrew/bin` e `~/.orbstack/bin`. Se não achar ou o daemon estiver parado → nenhuma mudança (o runtime continua como processo de sistema).
4. **`run()` precisa repassar `HOME`** para o `docker` achar o contexto (`~/.docker`). Hoje o environment só tem `LC_ALL`.

## Modelo

```swift
public struct Container: Hashable, Sendable {
    public let id: String       // ID curto do docker ps
    public let name: String     // "yt-city-db-1"
    public let image: String    // "postgres:16"
}

// novo campo em ListeningProcess
public let container: Container?
// `id` (Identifiable) passa a ser String: container?.id ?? "\(pid)"
```

- Cada container com porta publicada (`0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp` → host port 5432) vira um `ListeningProcess` próprio: `pid` = PID do runtime, `kind` = nome da imagem sem tag e em caixa alta (`POSTGRES`), `isSystem = false`, `startedAt` = `CreatedAt`, cpu e mem vazios.
- **Projeto:** se tiver label compose, `Project(root: working_dir, name: project)`, o que agrupa o container com o `next dev` do mesmo repo. Senão, sem projeto.
- Portas do runtime que não batem com nenhum container ficam no processo do runtime, que continua `isSystem`.

## Controle

- `×` em container → `docker stop <id>` (timeout padrão do docker, 10s) → `.terminated`. Falha → `.failed(<stderr curto>)`. Nunca `kill` no PID do runtime.
- `OPEN ↗` funciona igual (porta do host).
- `FINDER`/`EDITOR` usam o `working_dir` do compose, quando existe.

## UI

- Título = `kind` (`POSTGRES`). A meta mostra `yt-city-db-1 · postgres:16 · 3h 05m`, sem CPU/mem (`docker stats` custa ~1–2s; fora de escopo).
- Ícone SF Symbol `shippingbox` (peso light) no lugar do dot verde.

## Acceptance criteria

- `docker run -d -p 5432:5432 postgres:16` → aparece `POSTGRES :5432` em ≤ 5s, visível com o filtro de sistema ligado.
- Compose com `db` + o app em `next dev` no mesmo repo → mesmo grupo.
- `×` no container → `docker ps` não lista mais o container; a linha some.
- Docker Desktop fechado → nada quebra e nenhum `docker ps` roda (conferir com `log` ou contador de spawns).

## Testing Strategy

- **Unit:** parser do `docker ps` (portas IPv4/IPv6, várias portas, faixas `8000-8001->…`, sem portas, labels vazias); merge runtime → containers (porta sem container fica no runtime).
- **Integração** (pulada se `docker` não responder): subir `nginx:alpine` em porta efêmera, `scan()` acha o container, `terminate` para o container.
- **Manual:** compose real com app + db.

## Boundaries

- **Ask first:** `docker stats`, `docker rm`, ou qualquer ação além de `stop`.
- **Never:** matar o processo do runtime do Docker.

## Success Criteria

- [ ] Testes de parser e merge verdes; integração verde com Docker rodando.
- [ ] Checklist manual (run, compose, stop, Docker fechado).

## Open Questions

- Nenhuma.
