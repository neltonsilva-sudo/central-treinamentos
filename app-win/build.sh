#!/bin/zsh
# Gera downloads/Treinamentos-Windows.zip (instalador .cmd com o ícone embutido).
set -e
cd "$(dirname "$0")/.."
B=$(mktemp -d); P=$(mktemp -d)
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --user-data-dir="$P" --hide-scrollbars \
  --window-size=1024,1024 --default-background-color=00000000 --screenshot="$B/icon.png" "file://$PWD/tools/icon/icon-mac.html" >/dev/null 2>&1
rm -rf "$P"
for s in 16 24 32 48 64 128 256; do sips -z $s $s "$B/icon.png" --out "$B/i$s.png" >/dev/null; done
# .ico com imagens PNG embutidas (Windows Vista ou mais novo)
python3 - "$B" <<'PY'
import struct, sys, os
b = sys.argv[1]; sizes = [16, 24, 32, 48, 64, 128, 256]
imgs = [open(os.path.join(b, f'i{s}.png'), 'rb').read() for s in sizes]
head = struct.pack('<HHH', 0, 1, len(sizes)); off = 6 + 16 * len(sizes); ents = b''
for s, d in zip(sizes, imgs):
    ents += struct.pack('<BBBBHHII', s % 256, s % 256, 0, 0, 1, 32, len(d), off); off += len(d)
open(os.path.join(b, 'Treinamentos.ico'), 'wb').write(head + ents + b''.join(imgs))
PY
ICO=$(base64 -i "$B/Treinamentos.ico" | tr -d '\n')
mkdir "$B/Treinamentos"
python3 - "$B" "$ICO" <<'PY'
import sys
b, ico = sys.argv[1], sys.argv[2]
for src, dst in (('app-win/instalar.cmd.in', 'Instalar Treinamentos.cmd'), ('app-win/desinstalar.cmd.in', 'Desinstalar Treinamentos.cmd')):
    t = open(src, encoding='utf-8').read().replace('@@ICO@@', ico).replace('\r\n', '\n').replace('\n', '\r\n')
    open(f'{b}/Treinamentos/{dst}', 'w', encoding='utf-8', newline='').write(t)
PY
printf 'Central de Treinamentos para Windows\r\n\r\n1. Dê dois cliques em "Instalar Treinamentos.cmd".\r\n2. Se o Windows avisar, clique em "Mais informações" e depois em "Executar assim mesmo".\r\n3. O atalho "Treinamentos" aparece na Área de Trabalho e no Menu Iniciar.\r\n\r\nPrecisa do Microsoft Edge (já vem no Windows) ou do Google Chrome.\r\nPara remover: "Desinstalar Treinamentos.cmd".\r\n' > "$B/Treinamentos/LEIA-ME.txt"
rm -f downloads/Treinamentos-Windows.zip
(cd "$B" && zip -q -r -X "$OLDPWD/downloads/Treinamentos-Windows.zip" Treinamentos)
ls -la downloads/Treinamentos-Windows.zip
