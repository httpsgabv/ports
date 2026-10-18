# Plan 10: quick-wins

Spec: [specs/10-quick-wins.md](../../specs/10-quick-wins.md)

Três tasks independentes; qualquer ordem.

## 10.1 LAN

- O parser já vê o endereço em `n`; guardar `isExposed` por pid (`*:`, `0.0.0.0:`, `[::]:`).
- `isExposed` vem sempre do `lsof` atual (também nos reusados, como as portas).
- Chip `LAN` na `ProcessRow`/`GroupRow`.

## 10.2 EDITOR

- `Sources/Ports/Editors.swift`: lista fixa `(name, bundleID)`, `installedEditors()`, `open(path, editor)`.
- Preferências: picker `EDITOR` (só os instalados), `editorBundleID` persistido.
- Botão na linha expandida e na de grupo.

## 10.3 Total

- `totalMemory(_:)` em PortsCore (soma dos visíveis ativos). Header: `N ACTIVE · X MB`.

## Riscos

| Risco | Mitigação |
|---|---|
| Bundle ID do Cursor muda entre versões | detectar também por nome (`/Applications/Cursor.app`) como fallback |

## Checkpoint

Os três aceites manuais da spec.
