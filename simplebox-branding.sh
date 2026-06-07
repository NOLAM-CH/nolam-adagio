#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  NOLAM Adagio / SimpleBox — branding & finitions d'un poste
#  Linux Mint Cinnamon. Idempotent (relançable sans casse).
#
#  Usage :  sudo ./simplebox-branding.sh <compte_client>
#           (ex: sudo ./simplebox-branding.sh client)
#
#  Lit les assets depuis le repo (par défaut /opt/nolam-adagio).
#  Pose : icône menu (clair/sombre selon thème), splash Plymouth,
#  wallpaper + sélecteur, taille menu, barre des tâches,
#  politique Firefox/uBlock, MAJ silencieuses, nags Mint off.
#
#  NB : ce script touche des fichiers SYSTÈME (Plymouth, initramfs,
#  policies.json) que restore.sh ne défait PAS (restore.sh = dconf
#  seulement). Les fichiers écrasés sont sauvegardés en *.nolam.bak.
#
#  Copyright (C) 2026 dpan-Bug / NOLAM — SPDX: GPL-3.0-or-later
# ─────────────────────────────────────────────────────────────
set -uo pipefail

REPO="${NOLAM_REPO:-/opt/nolam-adagio}"
CLIENT="${1:-}"
WARN=0

ok()   { printf '\e[32m✓\e[0m %s\n' "$*"; }
warn() { WARN=$((WARN+1)); printf '\e[33m!\e[0m %s\n' "$*" >&2; }
die()  { printf '\e[31m✗\e[0m %s\n' "$*" >&2; exit 1; }
step() { printf '\n\e[1m== %s ==\e[0m\n' "$*"; }
# sauvegarde un fichier système avant écrasement (une seule fois)
backup_once() { [ -f "$1" ] && [ ! -f "$1.nolam.bak" ] && cp -p "$1" "$1.nolam.bak" && ok "sauvegarde : $1 → $1.nolam.bak"; return 0; }

[ "$(id -u)" -eq 0 ]          || die "À lancer en root : sudo $0 <compte_client>"
[ -n "$CLIENT" ]              || die "Usage : sudo $0 <compte_client>  (ex: client, brigitte)"
id "$CLIENT" >/dev/null 2>&1  || die "Compte « $CLIENT » introuvable."
[ -d "$REPO" ]               || die "Repo introuvable : $REPO"

CUID="$(id -u "$CLIENT")"
CHOME="$(getent passwd "$CLIENT" | cut -d: -f6)"
RUNDIR="/run/user/$CUID"
BUS="unix:path=$RUNDIR/bus"

# Exécute une commande DANS la session graphique du client
as_client() { runuser -u "$CLIENT" -- env DISPLAY=:0 XDG_RUNTIME_DIR="$RUNDIR" DBUS_SESSION_BUS_ADDRESS="$BUS" "$@"; }
# gsettings client, seulement si la clé existe (évite les erreurs bruyantes)
cset() { as_client gsettings list-keys "$1" 2>/dev/null | grep -qx "$2" && as_client gsettings set "$1" "$2" "$3" && ok "$1 $2=$3"; }
# échappement XML minimal
xmlesc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# ═══════════ 1. ICÔNES MENU (système) ═══════════
step "Icônes menu NOLAM"
install -d /usr/share/icons/nolam
cp "$REPO/Logo/start_dk.png" /usr/share/icons/nolam/nolam-menu-light.png || die "start_dk.png manquant dans le repo"
cp "$REPO/Logo/start_c.png"  /usr/share/icons/nolam/nolam-menu-dark.png  || warn "start_c.png manquant (variante sombre)"
# Icône active = variante PANNEAU CLAIR par défaut : un déploiement senior force un
# panneau clair Mint-Y (cf. profil senior), donc la tuile sombre ressort dessus.
# La variante sombre (nolam-menu-dark.png) reste posée : le wizard la basculera si
# l'utilisateur choisit le thème sombre. (Évite le mismatch « tuile sombre / panneau
# sombre par défaut de Mint » observé quand le profil senior n'est pas encore appliqué.)
cp /usr/share/icons/nolam/nolam-menu-light.png /usr/share/icons/nolam/nolam-menu.png
chmod 644 /usr/share/icons/nolam/*.png
ok "icônes posées (active = variante panneau clair ; variante sombre dispo pour le wizard)"

# ═══════════ 2. WALLPAPER + SÉLECTEUR ═══════════
step "Wallpaper + sélecteur Cinnamon"
install -d /usr/share/backgrounds/nolam /usr/share/gnome-background-properties
shopt -s nullglob
MAIN_WP="$REPO/wallpaper_no_logo/${NOLAM_MAIN_WP:-Adagio_startwp.jpg}"
if [ -f "$MAIN_WP" ]; then cp "$MAIN_WP" /usr/share/backgrounds/nolam/nolam-adagio.jpg && chmod 644 /usr/share/backgrounds/nolam/nolam-adagio.jpg && ok "wallpaper principal"; else warn "wallpaper principal absent"; fi
XML=/usr/share/gnome-background-properties/nolam-adagio.xml
{
  echo '<?xml version="1.0"?>'
  echo '<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">'
  echo '<wallpapers>'
  [ -f /usr/share/backgrounds/nolam/nolam-adagio.jpg ] && \
    echo '  <wallpaper deleted="false"><name>NOLAM Adagio</name><filename>/usr/share/backgrounds/nolam/nolam-adagio.jpg</filename><options>zoom</options></wallpaper>'
  # UNIQUEMENT les images (jamais les .pxd sources)
  for f in "$REPO"/wallpaper_no_logo/Adagio_*_WP.jpg "$REPO"/wallpaper_no_logo/Adagio_*_WP.jpeg "$REPO"/wallpaper_no_logo/Adagio_*_WP.png; do
    [ -f "$f" ] || continue
    b="$(basename "$f")"
    cp "$f" "/usr/share/backgrounds/nolam/$b" || { warn "copie $b échouée"; continue; }
    chmod 644 "/usr/share/backgrounds/nolam/$b"
    name="$(printf '%s' "$b" | sed -E 's/^Adagio_//; s/_WP\.[^.]+$//')"   # garde le nom tel quel (Forest2 ≠ Forest)
    printf '  <wallpaper deleted="false"><name>NOLAM Adagio — %s</name><filename>/usr/share/backgrounds/nolam/%s</filename><options>zoom</options></wallpaper>\n' "$(xmlesc "$name")" "$(xmlesc "$b")"
  done
  echo '</wallpapers>'
} > "$XML"
chmod 644 "$XML"
ok "wallpapers (images seules) copiés + sélecteur XML"

# ═══════════ 3. SPLASH PLYMOUTH ═══════════
step "Splash de démarrage Plymouth"
SCRIPT_MOD="$(ls /usr/lib/*/plymouth/script.so 2>/dev/null | head -1)"
if [ -z "$SCRIPT_MOD" ]; then
  warn "Module Plymouth 'script' absent → splash NOLAM NON posé (on garde le branding bureau, on ne casse pas le boot). Installer le paquet 'plymouth-themes' si voulu."
elif [ ! -f "$REPO/Logo/boot_ico.png" ]; then
  warn "boot_ico.png absent du repo → splash NON posé."
else
  PT=/usr/share/plymouth/themes/nolam
  install -d "$PT"
  cp "$REPO/Logo/boot_ico.png" "$PT/boot_ico.png"
  cat > "$PT/nolam.plymouth" <<EOF
[Plymouth Theme]
Name=NOLAM Adagio
Description=Splash de demarrage NOLAM Adagio
ModuleName=script

[script]
ImageDir=$PT
ScriptFile=$PT/nolam.script
EOF
  # Logo mis à l'échelle AU BOOT (≈380px de large) → aucune dépendance image au déploiement
  cat > "$PT/nolam.script" <<'EOF'
Window.SetBackgroundTopColor(0,0,0);
Window.SetBackgroundBottomColor(0,0,0);
orig = Image("boot_ico.png");
s = 380 / orig.GetWidth();
logo.image  = orig.Scale(orig.GetWidth() * s, orig.GetHeight() * s);
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth()  / 2 - logo.image.GetWidth()  / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);
msg = Sprite();
msg.SetPosition(10, 10, 10000);
fun cb (t) { msg.SetImage(Image.Text(t, 0.8, 0.7, 0.4)); }
Plymouth.SetMessageFunction(cb);
EOF
  # sauvegarde du thème courant (HORS $PT pour survivre à un purge du thème nolam ; jamais « nolam » lui-même)
  PREV=/var/lib/nolam/previous-plymouth-theme
  install -d /var/lib/nolam
  CUR="$( (plymouth-set-default-theme 2>/dev/null) || basename "$(readlink -f /etc/alternatives/default.plymouth 2>/dev/null)" .plymouth)"
  [ -n "$CUR" ] && [ "$CUR" != "nolam" ] && [ ! -f "$PREV" ] && printf '%s\n' "$CUR" > "$PREV" && ok "thème Plymouth précédent mémorisé : $CUR"
  RC=0
  if command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme -R nolam >/dev/null 2>&1 || RC=$?
  else
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$PT/nolam.plymouth" 200 >/dev/null 2>&1
    update-alternatives --set default.plymouth "$PT/nolam.plymouth" >/dev/null 2>&1
    update-initramfs -u >/dev/null || RC=$?
  fi
  if [ "$RC" -eq 0 ]; then ok "thème Plymouth « nolam » posé (initramfs reconstruit ; thème précédent: ${CUR:-?})"
  else warn "Plymouth : update-initramfs/échec (code $RC) → le splash peut ne pas s'appliquer. Vérifier au reboot."; fi
fi

# ═══════════ 4. RÉGLAGES SESSION CLIENT ═══════════
step "Réglages session client ($CLIENT)"
if [ ! -S "$RUNDIR/bus" ]; then
  warn "Session graphique de $CLIENT INACTIVE (pas de bus dbus) → réglages utilisateur SAUTÉS. Relancer ce script APRÈS le 1er login du client."
else
  # 4a — applet menu : icône + taille (écriture atomique)
  MENUJSON="$(ls "$CHOME"/.config/cinnamon/spices/menu@cinnamon.org/*.json 2>/dev/null | head -1)"
  if [ -n "$MENUJSON" ]; then
    if as_client python3 - "$MENUJSON" <<'PY'
import json,sys,os
p=sys.argv[1]
try: d=json.load(open(p))
except Exception as e: print(e); sys.exit(1)
def setv(k,v):
    if isinstance(d.get(k),dict): d[k]["value"]=v
setv("menu-custom",True); setv("menu-label","")
setv("menu-icon","/usr/share/icons/nolam/nolam-menu.png"); setv("menu-icon-size",44)
setv("popup-width",1200); setv("popup-height",720)
setv("application-icon-size",48); setv("category-icon-size",24)
t=p+".nolam.tmp"
json.dump(d,open(t,"w"),indent=4); os.replace(t,p)
PY
    then ok "menu : icône NOLAM + taille 1200x720"; else warn "menu : échec d'écriture du JSON applet"; fi
  else warn "config applet menu introuvable (skip)"; fi

  # 4b — barre des tâches : Terminal -> Geary (écriture atomique)
  GWL="$(ls "$CHOME"/.config/cinnamon/spices/grouped-window-list@cinnamon.org/*.json 2>/dev/null | head -1)"
  if [ -n "$GWL" ]; then
    if as_client python3 - "$GWL" <<'PY'
import json,sys,os
p=sys.argv[1]
try: d=json.load(open(p))
except Exception as e: print(e); sys.exit(1)
if isinstance(d.get("pinned-apps"),dict):
    d["pinned-apps"]["value"]=["nemo.desktop","firefox.desktop","org.gnome.Geary.desktop"]
    t=p+".nolam.tmp"; json.dump(d,open(t,"w"),indent=4); os.replace(t,p)
else: sys.exit(2)
PY
    then ok "barre des tâches : nemo / firefox / geary"; else warn "barre des tâches : clé pinned-apps absente (skip)"; fi
  else warn "config grouped-window-list introuvable (skip)"; fi

  # 4c — wallpaper
  cset org.cinnamon.desktop.background picture-uri "file:///usr/share/backgrounds/nolam/nolam-adagio.jpg"
  cset org.cinnamon.desktop.background picture-options "zoom"

  # 4d — nags Mint off
  as_client bash -c 'mkdir -p "$HOME/.config/autostart"; for a in mintwelcome mintreport mintupdate; do printf "[Desktop Entry]\nType=Application\nHidden=true\n" > "$HOME/.config/autostart/$a.desktop"; done' && ok "nags Mint neutralisés (autostart)"
  cset com.linuxmint.updates hide-systray true
  cset com.linuxmint.updates tracker-disable-notifications true
  cset com.linuxmint.report automonitor false

  # 4e — recharger les applets à chaud (pas de cinnamon --replace, cf. leçon curseur)
  as_client dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon org.Cinnamon.ReloadXlet string:"menu@cinnamon.org" string:"APPLET" >/dev/null 2>&1
  as_client dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon org.Cinnamon.ReloadXlet string:"grouped-window-list@cinnamon.org" string:"APPLET" >/dev/null 2>&1
  ok "applets rechargés"
fi

# ═══════════ 5. FIREFOX uBlock + anti-nag (système) ═══════════
step "Politique Firefox (uBlock)"
if [ -d /usr/lib/firefox ]; then
  install -d /usr/lib/firefox/distribution
  FFP=/usr/lib/firefox/distribution/policies.json
  if [ -f "$FFP" ] && ! grep -q 'uBlock0@raymondhill.net' "$FFP" 2>/dev/null; then backup_once "$FFP"; fi
  cat > "$FFP" <<'EOF'
{ "policies": {
  "ExtensionSettings": { "uBlock0@raymondhill.net": {
    "installation_mode": "force_installed",
    "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi" } },
  "DisableTelemetry": true, "DisableFirefoxStudies": true,
  "DontCheckDefaultBrowser": true, "OverrideFirstRunPage": "", "OverridePostUpdatePage": "" } }
EOF
  ok "policies.json (uBlock + anti-nag)"
else warn "/usr/lib/firefox absent (Firefox non-deb ?) — skip"; fi

# ═══════════ 6. MAJ SILENCIEUSES ═══════════
step "Mises à jour silencieuses"
if command -v mintupdate-automation >/dev/null 2>&1; then
  mintupdate-automation upgrade enable    >/dev/null 2>&1 && ok "upgrade auto activé"
  mintupdate-automation autoremove enable >/dev/null 2>&1 && ok "autoremove auto activé"
else warn "mintupdate-automation indispo — skip"; fi

# ═══════════ BILAN ═══════════
step "TERMINÉ"
if [ "$WARN" -eq 0 ]; then ok "Aucun avertissement."; else warn "$WARN avertissement(s) ci-dessus — à vérifier."; fi
echo "→ REBOOT recommandé : applique proprement le splash Plymouth + la taille du menu."
