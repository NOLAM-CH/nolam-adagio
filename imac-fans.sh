#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NOLAM Adagio — module optionnel « vieux iMac » : ventilo HDD
#  silencieux quand le disque d'origine a été remplacé par un SSD.
#
#  Usage :  sudo ./imac-fans.sh             installe et démarre
#           sudo ./imac-fans.sh --uninstall retire tout, rend la main au SMC
#
#  Idempotent. Ne fait rien sur une machine sans SMC Apple.
#  Copyright (C) 2026 dpan-Bug / NOLAM — SPDX: GPL-3.0-or-later
# ─────────────────────────────────────────────────────────────
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
[ "$(id -u)" -eq 0 ] || { echo "À lancer avec sudo."; exit 1; }

if [ "${1:-}" = "--uninstall" ]; then
    systemctl disable --now nolam-imac-fans.service 2>/dev/null || true
    /usr/local/sbin/nolam-imac-fans --release 2>/dev/null || true
    rm -f /etc/systemd/system/nolam-imac-fans.service /usr/local/sbin/nolam-imac-fans \
          /etc/modules-load.d/nolam-drivetemp.conf
    systemctl daemon-reload
    echo "Module ventilos retiré, le SMC a repris la main."
    exit 0
fi

[ -d /sys/devices/platform/applesmc.768 ] || { echo "Pas de SMC Apple ici, rien à faire."; exit 0; }

# Sources de température : drivetemp (noyau, pas supporté par tous les SSD,
# ex. Kingston A400) puis smartctl en repli.
modprobe drivetemp || true
echo drivetemp > /etc/modules-load.d/nolam-drivetemp.conf
command -v smartctl >/dev/null || apt-get install -y smartmontools

install -m 0755 "$HERE/imac-fans/nolam-imac-fans" /usr/local/sbin/nolam-imac-fans
install -m 0644 "$HERE/imac-fans/nolam-imac-fans.service" /etc/systemd/system/nolam-imac-fans.service
systemctl daemon-reload
systemctl enable nolam-imac-fans.service
systemctl restart nolam-imac-fans.service

sleep 12
/usr/local/sbin/nolam-imac-fans --status
systemctl is-active nolam-imac-fans.service
