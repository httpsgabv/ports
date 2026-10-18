# Plan 08: docker-containers

Spec: [specs/08-docker-containers.md](../../specs/08-docker-containers.md)

## Componentes

1. `Shell.run`: environment passa a incluir `HOME` (e `PATH` mínimo) além de `LC_ALL`.
2. `Sources/PortsCore/Docker.swift`
   - `isContainerRuntime(_:) -> Bool` (executável/nome da spec).
   - `dockerBinary() -> String?` (candidatos da spec).
   - `parseDockerPs(_:) -> [DockerContainer]` (id, name, image, hostPorts, createdAt, composeProject, workingDir).
   - `expandContainers(runtime:containers:) -> [ListeningProcess]`: separa as portas do runtime em entradas de container.
3. `ListeningProcess`: `container: Container?`; `id` vira `String`. Revisar todos os usos de `id`/`pid` na UI e no store (`remove(pid)` → `remove(id)`).
4. `Killer`: `terminate` despacha para `docker stop <id>` quando `container != nil`.
5. UI: ícone `shippingbox`, meta sem cpu/mem.

## Ordem (TDD)

HOME no Shell → parser do `docker ps` → expand/merge → `id: String` (refactor com os testes verdes) → stop → UI → integração com Docker real.

## Riscos

| Risco | Mitigação |
|---|---|
| Mudar `id` para String quebra a UI/store | refactor isolado numa task, com `swift build` + testes antes de seguir |
| `docker ps` lento ou travado com o daemon subindo | timeout de 2s no `run` para o docker; em timeout, trata como Docker ausente |
| Formato de `CreatedAt` muda entre versões | parse tolerante; se falhar, `startedAt` = agora (não quebra a linha) |
| `docker stop` demora 10s | spinner já existe; sem timeout custom (YAGNI) |

## Checkpoint

Container aparece, agrupa com o app do compose e para pelo `×`; com o Docker fechado, zero `docker ps`.
