#!/usr/bin/env bash
# Install the Daedric Morrowind SDDM theme and make it current.  sudo ./install.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo" >&2; exit 1; }
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DST=/usr/share/sddm/themes/daedric-morrowind
mkdir -p "$DST"
cp -r "$HERE"/{Main.qml,metadata.desktop,theme.conf,assets,fonts,preview.jpg} "$DST"/
chmod -R a+rX "$DST"
mkdir -p /etc/sddm.conf.d
# SDDM reads its config files in name order and the last Current= wins, so update
# every file that already sets it (this keeps System Settings in charge afterwards)
found=0
for f in /etc/sddm.conf /etc/sddm.conf.d/*.conf; do
    if [[ -f $f ]] && grep -q '^Current=' "$f"; then
        echo "previous theme in $f: $(grep '^Current=' "$f")"
        sed -i 's/^Current=.*/Current=daedric-morrowind/' "$f"
        found=1
    fi
done
(( found )) || printf '[Theme]\nCurrent=daedric-morrowind\n' > /etc/sddm.conf.d/daedric-morrowind.conf
echo "Installed. Switch themes any time in System Settings > Colors & Themes > Login Screen (SDDM)."
