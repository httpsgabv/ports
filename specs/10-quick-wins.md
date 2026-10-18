# Spec 10: quick-wins

> Stack, comandos, estrutura, estilo: ver [00-foundation](00-foundation.md). Três melhorias pequenas e independentes; cada uma é uma task.

## 10.1 Marca `LAN` (porta exposta na rede)

**Por quê:** um dev server em `*:5173` fica acessível a qualquer um no mesmo Wi-Fi (café, coworking). Quase sempre isso é acidental (`--host`).

- O parser do `lsof` guarda o endereço: exposto se **qualquer** LISTEN for `*:`, `0.0.0.0:` ou `[::]:`. `127.0.0.1` e `[::1]` são locais.
- Novo campo `isExposed: Bool` em `ListeningProcess`. Containers com `0.0.0.0:5432->…` também são expostos (é verdade: o Docker publica em todas as interfaces).
- UI: chip `LAN` em CAPS 9pt, contorno `textTertiary`, à esquerda das portas. Tooltip: `Reachable from your local network`.

**Aceite:** `python3 -m http.server 8765` (bind `*`) mostra `LAN`; `python3 -m http.server 8765 --bind 127.0.0.1` não mostra.

## 10.2 Botão `EDITOR`

- Ao lado de `FINDER` na linha expandida, e na linha de grupo. Abre a **raiz do projeto** (spec 06), senão o cwd.
- Preferências: `EDITOR` com os editores **instalados** entre Cursor (`com.todesktop.230313mzl4w4u92`), VS Code (`com.microsoft.VSCode`), Zed (`dev.zed.Zed`), Windsurf (`com.exafunction.windsurf`), Sublime Text (`com.sublimetext.4`) e Xcode (`com.apple.dt.Xcode`). Detectados via `NSWorkspace.urlForApplication(withBundleIdentifier:)`. O padrão é o primeiro instalado, nessa ordem. Persistido em `editorBundleID`.
- Abre via `NSWorkspace.open([url], withApplicationAt:configuration:)`.
- Sem editor instalado → o botão não aparece.

**Aceite:** com o Cursor instalado, `EDITOR` abre a raiz do repo no Cursor; trocando para Zed nas preferências, abre no Zed.

## 10.3 Total no header

- O header passa de `3 ACTIVE` para `3 ACTIVE · 46 MB`: soma da memória dos processos **visíveis e não esperados** (spec 07). Containers somam 0 (sem dados).
- Com o popover fechado nada muda (o header não aparece). Com ele aberto, o scan já é completo.

**Aceite:** a soma bate com a memória das linhas visíveis (conta manual com 3 processos).

## Testing Strategy

- **Unit:** `isExposed` a partir das fixtures de `lsof` (`*:`, `0.0.0.0`, `[::]`, `127.0.0.1`, `[::1]`, mistura v4 local + v6 exposto → exposto); soma do total respeitando visíveis/esperados.
- **Manual:** os três aceites acima.

## Boundaries

- **Ask first:** adicionar editores além da lista.

## Success Criteria

- [x] Testes de `isExposed` (incl. mistura v4 local + v6 exposto e exposição por porta de container) e total verdes.
- [x] Os três aceites manuais ok: LAN só no `http.server` em `*` (scan real: `LAN: true/false`); header `2 ACTIVE · 51 MB`; EDITOR abriu o repo no VS Code e, após trocar, no Xcode (`editorBundleID = com.apple.dt.Xcode` no plist).

## Open Questions

- Nenhuma.
