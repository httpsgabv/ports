# Capability Map: Ports

App de menu bar para macOS que mostra quais processos estão ouvindo em portas TCP e permite matá-los.
Problema: servidores de dev esquecidos rodando e consumindo recursos sem que eu perceba.

## v1 (implementado)

| # | Module id | Responsabilidade | Depende de |
|---|---|---|---|
| 00 | `foundation` | Pacote SwiftPM, bundle `.app`, app só na menu bar (sem Dock), tokens de design, convenções | — |
| 01 | `port-scanner` | Descobre processos em TCP LISTEN + detalhes (cwd, uptime, CPU, mem, comando) e classifica sistema/usuário | foundation |
| 02 | `process-control` | Kill SIGTERM→SIGKILL seguro contra reuso de PID, abrir `localhost:PORTA` no browser, revelar pasta no Finder | port-scanner |
| 03 | `live-status` | Store com polling de 5s, contador no ícone da menu bar, filtro de sistema, detecção de "esquecido" | port-scanner |
| 04 | `port-list-ui` | Popover: lista minimalista, linha por processo, expandir detalhes, ações | live-status, process-control |
| 05 | `preferences` | Limite de "esquecido" (padrão 2h), mostrar processos de sistema, iniciar no login, persistência | live-status, port-list-ui |

## v2 (especificado)

| # | Module id | Responsabilidade | Depende de |
|---|---|---|---|
| 06 | `project-identity` | Projeto de cada processo (raiz do git → nome do `package.json`/pasta), framework pelo comando (`VITE`, `NEXT`…), agrupamento e kill do grupo | port-scanner, process-control, port-list-ui |
| 07 | `expected-processes` | Marcar processos como esperados: fora do contador e do âmbar, seção `EXPECTED` colapsada | project-identity, preferences |
| 08 | `docker-containers` | Portas do Docker viram containers (nome, imagem, projeto compose) com `docker stop` | port-scanner, process-control, project-identity |
| 09 | `idle-detection` | "Esquecido" passa a ser **ocioso** (sem conexões de entrada) por X horas, não só antigo | port-scanner, live-status, preferences |
| 10 | `quick-wins` | Marca `LAN` para porta exposta na rede, botão `EDITOR`, total de memória no header | port-scanner, port-list-ui, preferences, project-identity |

**Build order v2:** `project-identity` → `expected-processes` → `docker-containers` → `idle-detection` → `quick-wins`

> 08, 09 e 10 não dependem entre si e podem ir em qualquer ordem depois de 07. Mas 06, 08 e 09 mexem no `ListeningProcess` e no scanner, então vão em sequência para evitar conflito.

## Índice

- Specs: [`specs/`](specs/) — `NN-<module-id>.md`
- Plano e tarefas: [`tasks/NN-<module-id>/plan.md`](tasks/) e `todo.md`

## Fora do escopo

- **v1 (entrevista):** UDP, notificações do sistema, kill all, atalho global, busca/filtro, tema claro, App Store/notarização.
- **v2:**
  - **Matar a árvore de processos.** Testado em 17/out: `npm run dev` sai sozinho quando o filho que escuta a porta morre. Só supervisores como `nodemon` sobrariam, e esse caso é raro. Revisitar se aparecer na prática.
  - **Auto-kill por regra.** Um falso positivo custa caro; o âmbar + `EXPECTED` resolvem.
  - **Reiniciar processo.** Recriar o env e o shell original é frágil.
  - **CPU/mem de containers.** `docker stats` custa ~1–2s por chamada.
