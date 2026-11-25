#!/bin/zsh
# Gera downloads/Treinamentos-Mac.zip e Treinamentos.dmg (app universal Apple Silicon + Intel, assinatura ad-hoc).
set -e
cd "$(dirname "$0")/.."
B=$(mktemp -d)
APP="$B/Treinamentos.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" downloads
for arch in arm64 x86_64; do
  X=(); [ $arch = x86_64 ] && X=(-runtime-compatibility-version none)  # CLT atual não traz as libs de compatibilidade Intel
  swiftc -O -swift-version 5 -target $arch-apple-macos12.3 "${X[@]}" app-mac/main.swift -o "$B/bin-$arch"
done
lipo -create "$B/bin-arm64" "$B/bin-x86_64" -output "$APP/Contents/MacOS/Treinamentos"
cp app-mac/Info.plist "$APP/Contents/Info.plist"
# ícone: Chrome headless -> PNG 1024 -> iconset -> icns
P=$(mktemp -d)
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --user-data-dir="$P" --hide-scrollbars \
  --window-size=1024,1024 --default-background-color=00000000 --screenshot="$B/icon.png" "file://$PWD/tools/icon/icon-mac.html" >/dev/null 2>&1
rm -rf "$P"
IS="$B/AppIcon.iconset"; mkdir "$IS"
for s in 16 32 128 256 512; do
  sips -z $s $s "$B/icon.png" --out "$IS/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$B/icon.png" --out "$IS/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$IS" -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep -s - "$APP"
# .dmg com atalho para Aplicativos
D="$B/dmg"; mkdir "$D"; cp -R "$APP" "$D/"; ln -s /Applications "$D/Aplicativos"
rm -f downloads/Treinamentos.dmg
hdiutil create -quiet -volname "Treinamentos" -srcfolder "$D" -fs HFS+ -format UDZO -ov downloads/Treinamentos.dmg
# .zip (download principal: abre com dois cliques ou qualquer extrator)
rm -f downloads/Treinamentos-Mac.zip
ditto -c -k --sequesterRsrc --keepParent "$APP" downloads/Treinamentos-Mac.zip
echo "$APP"
ls -la downloads/
