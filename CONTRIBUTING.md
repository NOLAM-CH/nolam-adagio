# Contribuer à NOLAM Adagio

Merci de l'intérêt ! Adagio vit de l'idée que **chacun devrait pouvoir adapter son ordinateur à lui** — toute aide qui sert cette cause est bienvenue.

## La façon la plus simple : un nouveau profil

Un profil d'accessibilité est **un simple fichier** `profiles/*.conf`, pas du code :

```ini
[org.cinnamon.desktop.interface]
text-scaling-factor = 1.4    # texte 40 % plus grand
cursor-size = 36             # curseur bien visible
```

Pour proposer une déclinaison (motricité, cognitif, une variante senior plus douce…) :

1. Copiez un profil existant de `profiles/`.
2. Ajustez les clés `gsettings` (une par ligne, `section` entre crochets).
3. Testez : `./install.sh votre-profil` puis `./restore.sh` pour revenir en arrière.
4. Ouvrez une *pull request* avec une courte description : **pour qui** et **ce que ça change**.

## Autres contributions utiles

- **Traductions** : l'interface de l'assistant utilise `gettext`. Ajouter une langue = un fichier `.po` dans `gui/locale/`.
- **Rapports** : un réglage qui ne s'applique pas sur votre version de Mint ? Ouvrez une *issue* en précisant la version (`cinnamon --version`, `lsb_release -d`).
- **Accessibilité réelle** : si vous êtes concerné·e (basse vision, motricité, cognition) ou accompagnez des personnes qui le sont, vos retours valent de l'or. Le profil `non-voyant` (Orca) sera **conçu avec** des personnes non-voyantes, pas pour elles à leur place.

## Principes

- **Réversibilité d'abord** : rien ne doit pouvoir « casser » l'écran de quelqu'un. Tout passe par `dconf`/`gsettings`, sauvegardé avant, restaurable après.
- **Sans `sudo`** pour les profils : on ne touche qu'à la session de l'utilisateur, jamais au système.
- **Simple avant malin** : la cible, ce sont des personnes que la technique intimide. La clarté prime sur l'astuce.

## Licence

En contribuant, vous acceptez que votre travail soit publié sous **GPL-3.0**, comme le reste du projet. L'ouverture se propage.
