#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NOLAM Adagio — restaure l'état du bureau d'avant le profil
#
#  Copyright (C) 2026 dpan-Bug / NOLAM
#  SPDX-License-Identifier: GPL-3.0-or-later
# ─────────────────────────────────────────────────────────────
set -uo pipefail

BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nolam-adagio"
PRISTINE="$BACKUP_DIR/original-state.dconf"
LAST_LINK="$BACKUP_DIR/last-backup"

if [[ -t 1 ]]; then
  C_OK=$'\e[32m'; C_WARN=$'\e[33m'; C_ERR=$'\e[31m'; C_DIM=$'\e[2m'; C_OFF=$'\e[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_OFF=""
fi
ok()   { printf '%s✓%s %s\n' "$C_OK" "$C_OFF" "$*"; }
die()  { printf '%s✗%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

command -v dconf >/dev/null 2>&1 || die "dconf introuvable."

# Cible : l'état d'origine d'avant Adagio (sinon une sauvegarde précise passée en argument)
TARGET="${1:-$PRISTINE}"
[[ -e "$TARGET" ]] || TARGET="$LAST_LINK"
if [[ "${1:-}" == "--list" ]]; then
  printf 'Sauvegardes disponibles dans %s :\n' "$BACKUP_DIR"
  ls -1t "$BACKUP_DIR"/*.dconf 2>/dev/null || echo "  (aucune)"
  exit 0
fi

[[ -e "$TARGET" ]] || die "Aucune sauvegarde trouvée. (Lancez d'abord ./install.sh, ou ./restore.sh --list)"

printf 'Restauration de l’état depuis : %s\n' "$(readlink -f "$TARGET")"
if dconf load / < "$TARGET"; then
  ok "Bureau restauré dans son état d'origine (d'avant Adagio)."
  printf '%s  Une déconnexion/reconnexion peut être nécessaire pour tout réafficher.%s\n' "$C_DIM" "$C_OFF"
else
  die "Échec de la restauration."
fi
