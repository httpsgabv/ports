#!/bin/bash
# Captura só a janela do popover do Ports para o README (precisa de permissão de Gravação de Tela).
# Uso: ./scripts/screenshots.sh nome1 nome2 ...   → docs/screenshots/<nome>.png
# Para cada nome: espera o popover estar aberto, conta 10s (tempo de arrumar a tela), captura e toca um som.
set -euo pipefail
cd "$(dirname "$0")/.."
out=docs/screenshots
mkdir -p "$out"

pid=$(pgrep -x Ports) || { echo "Ports não está rodando"; exit 1; }

# id da janela do popover: a maior janela do Ports com mais de 100pt de altura (o ícone da menu bar é baixinho)
popover_id() {
    swift - "$pid" <<'EOF' 2>/dev/null
import CoreGraphics
let pid = Int(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
let popovers = list.filter { ($0[kCGWindowOwnerPID as String] as? Int) == pid }
    .compactMap { w -> (Int, Double)? in
        let b = w[kCGWindowBounds as String] as! [String: Double]
        return b["Height"]! > 100 ? (w[kCGWindowNumber as String] as! Int, b["Height"]!) : nil
    }
if let top = popovers.max(by: { $0.1 < $1.1 }) { print(top.0) }
EOF
}

for name in "${@:-main}"; do
    echo "[$name] abra o popover…"
    until id=$(popover_id) && [[ -n "$id" ]]; do sleep 0.5; done
    for s in 10 9 8 7 6 5 4 3 2 1; do printf "\r[%s] capturando em %2ds" "$name" "$s"; sleep 1; done
    id=$(popover_id)
    screencapture -x -o -l"$id" "$out/$name.png"   # -o: sem sombra
    afplay /System/Library/Sounds/Tink.aiff &
    printf "\r[%s] salvo em %s/%s.png          \n" "$name" "$out" "$name"
done
