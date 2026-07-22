# NOLAM Adagio — Runbook de déploiement d'un poste (custom, manuel)

> Procédure **manuelle** de mise en place d'un poste NOLAM Adagio, distillée de plusieurs
> déploiements réels (poste senior de bureau, box media TV, poste multilingue DE).
> Compagnon pratique du script `simplebox-branding.sh`. En attendant la **clé USB
> d'install autonome** (`nolam-install.sh`), c'est LE mode opératoire de référence.
>
> 🔒 **Aucun secret ici** : jamais de mot de passe, IP, ID RustDesk ni nom de client dans ce
> fichier. Ça vit dans le gestionnaire de mots de passe + la mémoire privée.

---

## 0. Choisir le profil de poste

| Usage | Exemple | Spécificités |
|---|---|---|
| **Poste senior de bureau** | lecture mail, web, jeux, appli Windows via Wine | profil senior/vision, gros texte, 2 comptes |
| **Box media TV** | matchs en stream, photos, musique sur une TV | 1080p (pas 4K), Kodi/VLC, N2 (store visible), gros texte pour le canapé |
| **Poste de test / démo** | valider une langue, dogfood le script | idem, sans les données client |

---

## 1. Boîte à outils — la clé Ventoy « couteau suisse »

Une **seule** clé USB qui boote tout (drag-drop des ISO, menu au boot) :
- **Linux Mint Cinnamon** (ISO) — l'OS.
- **Rescuezilla** (ISO) — clonage/imagerie avec **jolie UI** (moteur Clonezilla dessous, format ouvert).
- **Clonezilla** (ISO) — le même moteur en secours (live plus à jour si Rescuezilla cale sur du matos très récent ; images interchangeables).
- (option) GParted, Memtest86.

⚠️ **Fabriquer la clé Ventoy sur une machine PROPRE** — surtout **PAS** un PC bardé d'outils disque (EaseUS Partition Master, Samsung Magician, Stellar…). Leurs **drivers-filtres bloquent le formatage de partition** → Ventoy2Disk (et Rufus VTSI) échouent avec `WriteFile ErrCode:5` (accès refusé). balenaEtcher passe (il écrit une image brute, pas de format en place), mais le plus simple = faire la clé sur une machine sans ces outils. **Une fois la clé faite, ajouter des ISO = simple copie de fichiers → marche depuis n'importe où** (c'était juste le *format* qui bloquait).

---

## 2. (Dual-boot / préserver l'OS existant) — Imager AVANT de wiper

Si la machine a déjà un OS (souvent Windows) et qu'on veut un filet de retour :
1. Boot la clé → **Rescuezilla** (ou Clonezilla) → **save disk/device-image**.
2. Source = le disque de l'OS existant. Destination = **clé exFAT** / **disque interne libre** (ex. eMMC) / **NAS (samba/ssh)**. Idéalement **2 copies** (clé + NAS).
3. Format Clonezilla = **ouvert** → restaurable par n'importe quel Clonezilla/Rescuezilla, **sans lock-in** (contrairement au `.tib` Acronis qui exige Acronis).

> 💡 La licence Windows OEM des mini-PC est **gravée dans l'UEFI** → un Windows réinstallé se
> réactive tout seul. L'image sert surtout à éviter la galère **drivers/config**, pas la licence.
> Ne JAMAIS reformater l'ancien disque tant que le client n'a pas confirmé que tout va bien.

---

## 3. Installer Linux Mint

1. Boot clé Ventoy → **Linux Mint** → **Normal mode** (si Ventoy demande).
2. Installer : **cocher les codecs multimédia**.
3. **Disque cible** : ⚠️ vérifier 3× le bon disque (le rapide de préférence — un M.2 plutôt qu'un eMMC lent). Effacer/utiliser tout le disque cible.
4. Si TV **4K** → régler le **bureau en 1080p** (la TV upscale, ça soulage la petite puce).

> ⚠️ Secure Boot : Mint le gère (shim signé). Si Ventoy/l'install râle, valider l'enrôlement ou
> désactiver Secure Boot dans l'UEFI.

---

## 4. Modèle 2 comptes

- **`adagio`** = admin/maintenance (dans `sudo`, **clé SSH** posée, sudo par mot de passe).
- **`<compte_client>`** = **non-admin**, **autologin** (LightDM `autologin-user`), profil senior.
- Poser **ma clé SSH publique** dans `~adagio/.ssh/authorized_keys` (accès de maintenance).
- Le client ne tape jamais son mot de passe (autologin) → peut être fort et rangé au gestionnaire.

---

## 5. Déployer le branding + finitions (le script)

1. Amener le repo dans **`/opt/nolam-adagio`** (git clone / rsync, `chown -R root:root`).
2. Lancer :
   ```
   sudo /opt/nolam-adagio/simplebox-branding.sh <compte_client> --secure
   ```
   → pose : icône menu (variante panneau clair), splash Plymouth, wallpaper + sélecteur XML,
   taille menu, barre des tâches (Terminal→Geary), uBlock (policies Firefox), MAJ silencieuses,
   nags Mint off, **+ (`--secure`) UFW + SSH par clé uniquement** (garde-fous anti-lock-out).
3. ⚠️ La **session graphique du client doit être ACTIVE** pour les réglages par-utilisateur
   (sinon le script saute la section 4 et prévient → relancer après le 1er login).

---

## 6. Profil d'affichage + wizard

- Appliquer un profil : `install.sh senior` (ou une base senior + vision XL selon la personne),
  dans la session du client.
- **Wizard « Adapter mon écran »** (`nolam-adagio-confort`) — à faire **devant la personne** :
  - **Confort** (vue/gestes/débute) → aperçu en direct.
  - **Autonomie** : **N1 Tranquille** (technique + Store cachés) / **N2 Curieux** (Store visible) /
    **N3 Aux commandes** (tout visible). *(Box media / bricoleur curieux → N2.)*
  - L'Aide (`yelp`) reste visible à tous les niveaux.

---

## 7. Lanceurs bureau (noms parlants)

Poser sur le bureau du client, marqués « de confiance » (`gio set … metadata::trusted true`) :
- **Internet** (firefox), **E-Mail** / **Messagerie** (geary), **Word** (libreoffice-writer),
  les jeux, **« Adapter mon écran »** (wizard).
- ⚠️ **Dossier bureau selon la langue** : `Bureau` (FR) / `Schreibtisch` (DE) → toujours détecter via
  `xdg-user-dir DESKTOP`.
- ⚠️ « Word » pour LibreOffice Writer = OK sur un poste **privé** (nom familier au senior), mais
  **pas** dans le produit public (marque Microsoft).

---

## 8. Réglages machine — les GOTCHAS durement gagnés

- 🔴 **Masquer la veille** (piège n°1 sur poste frais) : un Mint qui s'auto-suspend **coupe le réseau**
  → tue l'apt distant / le support. →
  ```
  sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
  ```
  (+ logind `IdleAction=ignore`, + NetworkManager `wifi.powersave=2`). Idéal pour une box TV branchée H24.
- 🥾 **Logo de boot Plymouth centré/net** : sinon basse résolution avant le driver Intel → logo tordu/qui saute. →
  ```
  echo i915 | sudo tee -a /etc/initramfs-tools/modules
  sudo update-initramfs -u
  ```
- 🧠 **zram** (swap compressé) sur les machines **4 Go** → gros gain.
- 🎬 **Accélération vidéo VA-API** dans Firefox → stream (match) fluide même sur CPU faible.
- 🖥️ Sur 4 Go + eMMC lent : Cinnamon reste **correct** si l'OS est sur le disque **rapide** ; sinon envisager **XFCE** (plus léger, mais le toolkit Adagio cible Cinnamon).

---

## 9. Applications selon l'usage

- **Poste senior** : Wine (appli Windows têtues), jeux natifs (aisleriot/gnome-mines/mahjongg/sudoku), Geary.
  - Appli Windows (ex. jeu de puzzles 2000s) : **préfixe Wine 32-bit dédié**, `Version=winxp`, ne **pas** installer le DirectX du CD. Migrer les **données/créations de l'utilisateur** (pas juste le programme).
- **Box media TV** : **Kodi** (interface 10-pieds, télécommande) OU **VLC** + **Firefox** avec **raccourci géant** vers le site du client.
- **Musique / photos** : **Strawberry** (bibliothèque façon iTunes), **digiKam** (riche) ou **gThumb/Shotwell** (léger) pour les photos. Copier les **fichiers** de l'utilisateur, pas l'appli d'origine.

---

## 10. Support distant

- **RustDesk** (souverain — pas Splashtop). Service **au boot**, se reconnecte après reboot.
- ⚠️ Réseau public RustDesk = seul point joignable depuis Internet (traverse le NAT) →
  **mot de passe permanent FORT (20+, aléatoire) + 2FA**. Migrer vers **relais auto-hébergé** à terme.
- L'imagerie + l'install Mint sont **physiques** (boot USB) — RustDesk sert **après**, pour la maintenance.

---

## 11. Reboot + checklist finale

- **Reboot** (applique proprement : splash, taille menu, thème panneau).
- Vérifier : autologin client OK · **splash NOLAM centré** au boot · **panneau clair + icône menu qui ressort** · lanceurs présents · veille masquée · MAJ auto silencieuses actives · SSH clé-only (password refusé) · UFW actif.
- **À finir (côté humain)** : changer les mots de passe provisoires (admin + client) · RustDesk 2FA · confirmer le dist-upgrade passé.

---

## 12. Pièges & leçons (résumé)

1. **Veille = coupe le réseau** → masquer les targets en 1er.
2. **Clé Ventoy** : la fabriquer sur une machine **propre** (drivers disque = `ErrCode:5`). Ajout d'ISO ensuite = drag-drop partout.
3. **Icône menu** = variante **panneau clair** par défaut (le déploiement senior force un panneau clair ; sinon tuile sombre invisible sur panneau Mint sombre par défaut).
4. **Logo boot** = `i915` early KMS.
5. **i18n** : dossier bureau `Schreibtisch`/`Bureau` (via `xdg-user-dir`) ; prompt sudo = « Passwort » en allemand.
6. **Verify d'abord** : sur un outil connu qui déconne, **lire la doc/les issues GitHub AVANT** de deviner. Et **avant de coder un outil**, chercher s'il existe (souvent oui, ex. Rescuezilla).
7. **Ne jamais** wiper l'ancien disque tant que le client n'a pas validé (garder l'image = filet).

---

## 13. Boîte à outils — liens

- **Ventoy** — clé multi-ISO : <https://www.ventoy.net/en/download.html>
- **Rescuezilla** — clonage à jolie UI (moteur Clonezilla) : <https://rescuezilla.com/> · <https://github.com/rescuezilla/rescuezilla>
- **Clonezilla** — clonage brut, moteur éprouvé (secours) : <https://clonezilla.org/downloads.php>
- **Linux Mint Cinnamon** : <https://linuxmint.com/download.php>

---

## 14. Vers l'automatisation (backlog)

Objectif : **clé USB d'install autonome** (`nolam-install.sh`) → une commande, 20 min chez un client.
Modules à scripter (au-delà du branding déjà fait) : comptes+autologin, masquage veille, i915 boot,
lanceurs bureau localisés, profil+niveau d'autonomie, applis selon usage. Cf. le repo + le tracker projet.
