#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NOLAM Adagio — applique un profil d'accessibilité
#  Lentement et avec aise. Réversible. Sans toucher au système.
#
#  Copyright (C) 2026 dpan-Bug / NOLAM
#  SPDX-License-Identifier: GPL-3.0-or-later
# ─────────────────────────────────────────────────────────────
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$ROOT/profiles"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nolam-adagio"

# Couleurs (désactivées si pas un terminal)
if [[ -t 1 ]]; then
  C_OK=$'\e[32m'; C_WARN=$'\e[33m'; C_ERR=$'\e[31m'; C_DIM=$'\e[2m'; C_OFF=$'\e[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_OFF=""
fi

say()  { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_OK" "$C_OFF" "$*"; }
warn() { printf '%s!%s %s\n' "$C_WARN" "$C_OFF" "$*" >&2; }
die()  { printf '%s✗%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
NOLAM Adagio — adapte l'interface de Linux Mint Cinnamon.

Usage :
  ./install.sh <profil>     applique un profil (ex. senior, malvoyant)
  ./install.sh --list       liste les profils disponibles
  ./install.sh --help       affiche cette aide

Pour revenir en arrière :  ./restore.sh
EOF
}

list_profiles() {
  say "Profils disponibles :"
  shopt -s nullglob
  local found=0
  for f in "$PROFILE_DIR"/*.conf; do
    found=1
    local name desc
    name="$(basename "$f" .conf)"
    desc="$(grep -m1 '^# Objectif' "$f" | sed 's/^# Objectif *: *//')"
    printf '  %s%-14s%s %s\n' "$C_OK" "$name" "$C_OFF" "${C_DIM}${desc}${C_OFF}"
  done
  [[ $found -eq 1 ]] || warn "Aucun profil dans $PROFILE_DIR"
}

# ── Pré-vol ──────────────────────────────────────────────────
command -v gsettings >/dev/null 2>&1 || die "gsettings introuvable — ce système n'est pas un bureau GNOME/Cinnamon."

case "${1:-}" in
  ""|-h|--help) usage; exit 0 ;;
  --list)       list_profiles; exit 0 ;;
esac

PROFILE_NAME="$1"
PROFILE_FILE="$PROFILE_DIR/$PROFILE_NAME.conf"
[[ -f "$PROFILE_FILE" ]] || die "Profil « $PROFILE_NAME » introuvable. Essayez : ./install.sh --list"

if [[ "${XDG_CURRENT_DESKTOP:-}" != *Cinnamon* ]]; then
  warn "Bureau détecté : « ${XDG_CURRENT_DESKTOP:-inconnu} » (Adagio vise Cinnamon)."
  warn "On continue, mais certains réglages peuvent ne rien faire."
fi

# ── Sauvegarde complète de l'état dconf (la garantie de retour) ──
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/before-$PROFILE_NAME.dconf"
LAST_LINK="$BACKUP_DIR/last-backup"
if dconf dump / > "$BACKUP_FILE" 2>/dev/null; then
  ln -sf "$BACKUP_FILE" "$LAST_LINK"
  ok "État actuel sauvegardé → $BACKUP_FILE"
  say "${C_DIM}  (./restore.sh remettra tout exactement comme avant)${C_OFF}"
else
  warn "Sauvegarde dconf impossible — on continue sans filet de retour automatique."
fi

# ── Application du profil ────────────────────────────────────
say ""
say "Application du profil ${C_OK}$PROFILE_NAME${C_OFF}…"
schema=""
applied=0; skipped=0
while IFS= read -r line || [[ -n "$line" ]]; do
  # Nettoyage : retire commentaires et espaces
  line="${line%%#*}"
  line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$line" ]] && continue

  # Section [schema]
  if [[ "$line" =~ ^\[(.+)\]$ ]]; then
    schema="${BASH_REMATCH[1]}"
    continue
  fi

  # Ligne clé = valeur
  if [[ "$line" == *"="* ]]; then
    key="${line%%=*}"
    val="${line#*=}"
    key="$(printf '%s' "$key" | sed 's/[[:space:]]*$//')"
    val="$(printf '%s' "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$schema" ]] && { warn "clé « $key » hors de toute section — ignorée"; continue; }

    if gsettings set "$schema" "$key" "$val" 2>/dev/null; then
      ok "$schema $key → $val"
      ((applied++))
    else
      warn "ignoré : $schema $key (clé/valeur absente sur ce système)"
      ((skipped++))
    fi
  fi
done < "$PROFILE_FILE"

say ""
ok "Terminé : $applied réglage(s) appliqué(s), $skipped ignoré(s)."
[[ $skipped -gt 0 ]] && say "${C_DIM}  Les réglages ignorés correspondent à des options non installées (ex. thème HighContrast).${C_OFF}"
say "Pour revenir en arrière à tout moment : ${C_OK}./restore.sh${C_OFF}"
