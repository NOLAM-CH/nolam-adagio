#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NOLAM Adagio — finitions « media box » (salon / TV)
#  Complète simplebox-branding.sh : n'installe QUE les deltas media.
#  Idempotent (relançable sans casse). À lancer APRÈS le branding.
#  (relu code-reviewer 22.07.2026 — bug parsing + garde-fous corrigés)
#
#  Usage :
#    sudo ./media-box.sh <compte_client> [options]
#
#  Options (toutes facultatives) :
#    --nas //SERVEUR/partage   monte un partage NAS pour les photos (SMB/CIFS)
#                              (SMB/CIFS). Le mot de passe N'est PAS ici :
#                              il va dans /etc/nolam/nas-photos.cred (600),
#                              créé par un humain (cf. gabarit posé par ce script).
#    --sport-url URL           crée un lanceur bureau « Sport » plein écran
#                              vers ce site (répétable pour plusieurs sites).
#    --kodi-autostart          lance Kodi automatiquement à l'ouverture de session.
#
#  Ce que ça pose :
#    - apps : kodi, vlc, strawberry (musique), gthumb (photos) ;
#    - décodage vidéo MATÉRIEL (VA-API) pour Firefox → stream sport fluide
#      même sur petit CPU Intel ;
#    - masquage de la veille (une box salon reste joignable H24) ;
#    - icône menu = variante panneau SOMBRE (le profil media est sombre) ;
#    - plomberie de montage NAS photos (sans secret) + lanceur « Photos » ;
#    - gros lanceurs bureau : Kodi, VLC, Photos, Sport.
#
#  NB : le profil d'affichage (media) s'applique à part :
#         ./install.sh media   (dans la session du client)
#
#  Copyright (C) 2026 dpan-Bug / NOLAM — SPDX: GPL-3.0-or-later
# ─────────────────────────────────────────────────────────────
set -uo pipefail

CLIENT=""
NAS_SHARE=""              # ex. //192.168.1.20/photos
KODI_AUTOSTART=0
SPORT_URLS=()
WARN=0
NPOS=0

ok()   { printf '\e[32m✓\e[0m %s\n' "$*"; }
warn() { WARN=$((WARN+1)); printf '\e[33m!\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[31m✗\e[0m %s\n' "$*" >&2; exit 1; }
step() { printf '\n\e[1m== %s ==\e[0m\n' "$*"; }
backup_once() { [ -f "$1" ] && [ ! -f "$1.nolam.bak" ] && cp -p "$1" "$1.nolam.bak" && ok "sauvegarde : $1 → $1.nolam.bak"; return 0; }

# ── Parsing des arguments (valide qu'une option attendant une valeur en a bien
#    une : sinon `shift 2` échoue silencieusement en bash et la boucle tourne à
#    l'infini, en root, sur la machine client. On refuse net.) ──
while [ $# -gt 0 ]; do
  case "$1" in
    --nas)
      [ $# -ge 2 ] && [ -n "${2:-}" ] || die "--nas nécessite une valeur (ex: --nas //192.168.1.20/photos)"
      printf '%s' "$2" | grep -qE '^//[^[:space:],]+/[^[:space:],]+$' \
        || die "--nas : format attendu //SERVEUR/partage (reçu : « $2 »)"
      NAS_SHARE="$2"; shift 2 ;;
    --sport-url)
      [ $# -ge 2 ] && [ -n "${2:-}" ] || die "--sport-url nécessite une URL (ex: --sport-url https://…)"
      SPORT_URLS+=("$2"); shift 2 ;;
    --kodi-autostart)  KODI_AUTOSTART=1; shift ;;
    --*)               printf 'option inconnue ignorée : %s\n' "$1" >&2; shift ;;
    *)                 CLIENT="$1"; NPOS=$((NPOS+1)); shift ;;
  esac
done

[ "$(id -u)" -eq 0 ]         || die "À lancer en root : sudo $0 <compte_client> [options]"
[ -n "$CLIENT" ]             || die "Usage : sudo $0 <compte_client> [--nas //SRV/part] [--sport-url URL] [--kodi-autostart]"
[ "$NPOS" -le 1 ]           || die "Trop d'arguments : un seul compte client attendu (reçu $NPOS)."
id "$CLIENT" >/dev/null 2>&1 || die "Compte « $CLIENT » introuvable."

CUID="$(id -u "$CLIENT")"
CHOME="$(getent passwd "$CLIENT" | cut -d: -f6)"
RUNDIR="/run/user/$CUID"
BUS="unix:path=$RUNDIR/bus"

# Exécute une commande DANS la session graphique du client
as_client() { runuser -u "$CLIENT" -- env DISPLAY=:0 XDG_RUNTIME_DIR="$RUNDIR" DBUS_SESSION_BUS_ADDRESS="$BUS" "$@"; }

# Installe seulement les paquets réellement disponibles (ne casse pas toute la
# transaction si un nom manque sur cette version de Mint).
apt_install_available() {
  local want=("$@") have=() p
  for p in "${want[@]}"; do
    if apt-cache show "$p" >/dev/null 2>&1; then have+=("$p"); else warn "paquet indisponible, sauté : $p"; fi
  done
  [ "${#have[@]}" -gt 0 ] || { warn "aucun paquet à installer"; return 0; }
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${have[@]}" >/dev/null 2>&1 \
    && ok "installés : ${have[*]}" || warn "apt-get a signalé une erreur sur : ${have[*]}"
}

# ═══════════ 1. APPLICATIONS MEDIA ═══════════
step "Applications media (Kodi, VLC, Strawberry, gThumb)"
apt-get update >/dev/null 2>&1 || warn "apt-get update a signalé une erreur (on continue)"
apt_install_available kodi vlc strawberry gthumb

# ═══════════ 2. DÉCODAGE VIDÉO MATÉRIEL (VA-API) ═══════════
# But : que le stream de sport tourne fluide sur le petit CPU Intel du Minix.
step "Décodage matériel VA-API + Firefox"
apt_install_available va-driver-all intel-media-va-driver i965-va-driver mesa-va-drivers vainfo gstreamer1.0-vaapi

# Firefox : activer VA-API via autoconfig SYSTÈME (vaut pour tous les profils,
# pas besoin d'un profil déjà créé). defaultPref = l'utilisateur peut encore changer.
if [ -d /usr/lib/firefox ]; then
  AC=/usr/lib/firefox/defaults/pref/autoconfig.js
  CFG=/usr/lib/firefox/firefox.cfg
  install -d /usr/lib/firefox/defaults/pref
  backup_once "$AC"; backup_once "$CFG"
  cat > "$AC" <<'EOF'
// NOLAM Adagio — charge firefox.cfg (décodage matériel VA-API)
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
EOF
  # La 1re ligne DOIT être un commentaire (Firefox ignore la 1re ligne du .cfg)
  cat > "$CFG" <<'EOF'
// NOLAM Adagio media box — décodage vidéo matériel (VA-API)
defaultPref("media.ffmpeg.vaapi.enabled", true);
defaultPref("media.rdd-ffmpeg.enabled", true);
defaultPref("media.hardware-video-decoding.force-enabled", true);
defaultPref("gfx.x11-egl.force-enabled", true);
defaultPref("widget.dmabuf.force-enabled", true);
EOF
  chmod 644 "$AC" "$CFG"
  ok "Firefox : VA-API activé (autoconfig système)"
else
  warn "/usr/lib/firefox absent (Firefox non-deb ?) — VA-API Firefox non posé"
fi

# ═══════════ 3. MASQUER LA VEILLE (box salon H24) ═══════════
# Piège n°1 des postes frais : l'auto-suspend coupe le réseau et tue le support
# à distance. Une box media branchée en permanence ne doit jamais s'endormir.
step "Masquer la veille (box branchée en permanence)"
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 \
  && ok "veille système masquée" || warn "masquage veille : échec partiel"
install -d /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/90-nolam-nosleep.conf <<'EOF'
[Login]
IdleAction=ignore
HandleLidSwitch=ignore
EOF
ok "logind : inactivité ignorée"
if command -v nmcli >/dev/null 2>&1; then
  install -d /etc/NetworkManager/conf.d
  printf '[connection]\nwifi.powersave=2\n' > /etc/NetworkManager/conf.d/90-nolam-wifi-powersave.conf
  ok "WiFi powersave désactivé (réseau stable pour le stream)"
fi

# ═══════════ 4. ICÔNE MENU — VARIANTE PANNEAU SOMBRE ═══════════
# Le profil media est SOMBRE → la tuile menu doit être la variante « panneau
# sombre » (sinon la tuile sombre par défaut du branding senior est invisible).
step "Icône menu (variante panneau sombre)"
if [ -f /usr/share/icons/nolam/nolam-menu-dark.png ]; then
  cp /usr/share/icons/nolam/nolam-menu-dark.png /usr/share/icons/nolam/nolam-menu.png
  chmod 644 /usr/share/icons/nolam/nolam-menu.png
  ok "icône menu = variante panneau sombre"
else
  warn "nolam-menu-dark.png absent → lance d'abord simplebox-branding.sh (il pose les icônes)"
fi

# ═══════════ 5. NAS PHOTOS (optionnel, SANS secret en dur) ═══════════
step "Montage NAS photos"
NAS_MOUNT=/media/nas-photos
NAS_CRED=/etc/nolam/nas-photos.cred
if [ -n "$NAS_SHARE" ]; then
  apt_install_available cifs-utils
  install -d "$NAS_MOUNT"
  install -d -m 700 /etc/nolam
  if [ ! -f "$NAS_CRED" ]; then
    cat > "$NAS_CRED" <<'EOF'
# NOLAM Adagio — identifiants du NAS photos (à REMPLIR par un humain).
# Aucun secret n'est stocké dans le repo ni dans ce script.
username=A_REMPLIR
password=A_REMPLIR
EOF
    warn "gabarit d'identifiants NAS créé : $NAS_CRED (600) → À REMPLIR (username/password) avant le montage."
  fi
  chmod 600 "$NAS_CRED"   # défense en profondeur (inconditionnel)
  # Entrée fstab : montage réseau en lecture seule, propriété = client.
  #   nofail + x-systemd.automount = ne bloque JAMAIS le boot (monté à la demande)
  #   _netdev = systemd sait que c'est un fs réseau (démonte avant de couper le net)
  #   pas de vers= figé : le noyau négocie le meilleur dialecte SMB dispo
  FSTAB_LINE="$NAS_SHARE  $NAS_MOUNT  cifs  credentials=$NAS_CRED,ro,uid=$CUID,gid=$CUID,iocharset=utf8,nofail,_netdev,x-systemd.automount  0  0"
  if grep -qsE "[[:space:]]${NAS_MOUNT}[[:space:]]" /etc/fstab; then
    if grep -qsF "$FSTAB_LINE" /etc/fstab; then
      ok "entrée fstab NAS déjà présente (identique)"
    else
      warn "une entrée fstab existe déjà pour $NAS_MOUNT mais DIFFÈRE de la demande → laissée telle quelle. Corrige à la main /etc/fstab si le partage a changé."
    fi
  else
    backup_once /etc/fstab
    printf '%s\n' "$FSTAB_LINE" >> /etc/fstab
    ok "entrée fstab ajoutée pour $NAS_SHARE → $NAS_MOUNT (lecture seule)"
  fi
  # Tente le montage seulement si les identifiants ont été remplis
  if grep -q 'A_REMPLIR' "$NAS_CRED" 2>/dev/null; then
    warn "montage NON tenté : identifiants $NAS_CRED encore à remplir."
  else
    systemctl daemon-reload >/dev/null 2>&1
    if mount "$NAS_MOUNT" >/dev/null 2>&1; then ok "NAS monté : $NAS_MOUNT"; else warn "montage NAS échoué (vérifier chemin/identifiants/pare-feu NAS)"; fi
  fi
else
  ok "pas de --nas fourni → montage NAS sauté (à ajouter plus tard, archi prête)"
fi

# ═══════════ 6. LANCEURS BUREAU (gros, parlants) ═══════════
# Nécessite une session graphique cliente ACTIVE (comme simplebox-branding.sh)
# pour marquer les lanceurs « de confiance ». Sinon on saute proprement.
step "Lanceurs bureau media"
if [ ! -S "$RUNDIR/bus" ]; then
  warn "Session graphique de $CLIENT INACTIVE → lanceurs bureau SAUTÉS. Relancer ce script APRÈS le 1er login du client."
else
  DESKTOP="$(as_client xdg-user-dir DESKTOP 2>/dev/null)"; DESKTOP="${DESKTOP:-$CHOME/Bureau}"
  as_client mkdir -p "$DESKTOP"

  # Pose un .desktop sur le bureau du client, marqué « de confiance ».
  # Le message ok ne s'affiche que si le marquage a réellement réussi.
  put_launcher() { # $1=nom_fichier  $2=Name  $3=Exec  $4=Icon
    local f="$DESKTOP/$1"
    cat > "$f" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$2
Exec=$3
Icon=$4
Terminal=false
EOF
    chown "$CLIENT:$CLIENT" "$f"; chmod +x "$f"
    if as_client gio set "$f" metadata::trusted true >/dev/null 2>&1; then
      ok "lanceur : $2"
    else
      warn "lanceur : $2 (posé mais NON marqué de confiance → avertissement possible au 1er clic)"
    fi
  }

  command -v kodi >/dev/null 2>&1 && put_launcher "kodi.desktop" "Médiathèque (Kodi)" "kodi" "kodi"
  command -v vlc  >/dev/null 2>&1 && put_launcher "vlc.desktop"  "Vidéos (VLC)"       "vlc"  "vlc"

  # Photos : le NAS s'il est configuré, sinon le dossier Images du client
  # (évite un lanceur qui pointe dans le vide quand on déploie sans --nas).
  if [ -n "$NAS_SHARE" ]; then
    PHOTOS_DIR="$NAS_MOUNT"
  else
    PHOTOS_DIR="$(as_client xdg-user-dir PICTURES 2>/dev/null)"; PHOTOS_DIR="${PHOTOS_DIR:-$CHOME}"
  fi
  command -v gthumb >/dev/null 2>&1 && put_launcher "photos.desktop" "Photos" "gthumb $PHOTOS_DIR" "gthumb"

  # Lanceurs « Sport » plein écran (un par --sport-url)
  if [ "${#SPORT_URLS[@]}" -gt 0 ]; then
    i=0
    for u in "${SPORT_URLS[@]}"; do
      [ -n "$u" ] || continue
      i=$((i+1))
      label="Sport"; [ "$i" -gt 1 ] && label="Sport $i"
      put_launcher "sport-$i.desktop" "$label" "firefox --kiosk $u" "firefox"
    done
  else
    warn "aucun --sport-url fourni → pas de lanceur Sport (relance avec --sport-url https://… quand tu as le site)"
  fi
fi

# ═══════════ 7. KODI AU DÉMARRAGE (optionnel) ═══════════
if [ "$KODI_AUTOSTART" = 1 ]; then
  step "Kodi au démarrage de session"
  if command -v kodi >/dev/null 2>&1; then
    as_client bash -c 'mkdir -p "$HOME/.config/autostart"; printf "[Desktop Entry]\nType=Application\nName=Kodi\nExec=kodi\nX-GNOME-Autostart-enabled=true\n" > "$HOME/.config/autostart/kodi.desktop"' \
      && ok "Kodi lancé automatiquement à l'ouverture de session"
  else warn "Kodi non installé → autostart sauté"; fi
fi

# ═══════════ BILAN ═══════════
step "TERMINÉ"
if [ "$WARN" -eq 0 ]; then ok "Aucun avertissement."; else warn "$WARN avertissement(s) ci-dessus — à vérifier."; fi
cat <<EOF
Prochaines étapes (humain) :
  • Appliquer le profil d'affichage dans la session du client :
      ./install.sh media        (+ ./install.sh leger pour la fluidité)
  • Régler le niveau d'autonomie au WIZARD devant la personne : N2 (Store visible).
  • Si NAS : remplir $NAS_CRED puis :  sudo mount $NAS_MOUNT
  • REBOOT pour appliquer proprement thème + menu + veille masquée.
EOF
