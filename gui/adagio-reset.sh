#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NOLAM Adagio — « Réparer mon affichage »
#  Ré-applique le profil confortable enregistré (annule un dérèglement
#  accidentel). NE ramène PAS au Mint brut — l'accessibilité est préservée.
#
#  Copyright (C) 2026 dpan-Bug / NOLAM
#  SPDX-License-Identifier: GPL-3.0-or-later
# ─────────────────────────────────────────────────────────────
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Profil à rétablir : celui réglé par le wizard, sinon le profil senior par défaut
PROFIL="$HOME/.config/nolam-adagio/mon-profil.conf"
[[ -f "$PROFIL" ]] || PROFIL="senior"

# Confirmation (si zenity dispo), sinon on applique directement
if command -v zenity >/dev/null 2>&1; then
  zenity --question --title="NOLAM Adagio" \
    --text="Revenir à votre affichage habituel ?\n\nVos réglages confortables seront rétablis." \
    --ok-label="Oui, réparer" --cancel-label="Annuler" 2>/dev/null || exit 0
fi

bash "$ROOT/install.sh" "$PROFIL" >/dev/null 2>&1

command -v notify-send >/dev/null 2>&1 && \
  notify-send "NOLAM Adagio" "Votre affichage a été rétabli. 🙂" 2>/dev/null || true
