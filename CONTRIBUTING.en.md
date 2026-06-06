# Contributing to NOLAM Adagio

[Français](CONTRIBUTING.md) · **English**

Thanks for your interest! Adagio runs on the idea that **everyone should be able to adapt their computer to themselves** — any help that serves that cause is welcome.

## The simplest way: a new profile

An accessibility profile is **just a file** (`profiles/*.conf`), not code:

```ini
[org.cinnamon.desktop.interface]
text-scaling-factor = 1.4    # text 40% larger
cursor-size = 36             # clearly visible cursor
```

To propose a variant (motor, cognitive, a gentler senior variant…):

1. Copy an existing profile from `profiles/`.
2. Adjust the `gsettings` keys (one per line, `section` in brackets).
3. Test it: `./install.sh your-profile`, then `./restore.sh` to roll back.
4. Open a pull request with a short description: **for whom** and **what it changes**.

## Other useful contributions

- **Translations**: the wizard interface uses `gettext`. Adding a language = one `.po` file in `gui/locale/`.
- **Reports**: a setting that doesn't apply on your version of Mint? Open an issue stating the version (`cinnamon --version`, `lsb_release -d`).
- **Real-world accessibility**: if you are concerned (low vision, motor, cognitive) or support people who are, your feedback is gold. The `non-voyant` (Orca) profile will be **designed with** blind people, not for them in their place.

## Principles

- **Reversibility first**: nothing should be able to "break" someone's screen. Everything goes through `dconf`/`gsettings`, saved before, restorable after.
- **No `sudo`** for profiles: we only touch the user's session, never the system.
- **Simple over clever**: the audience is people whom technology intimidates. Clarity beats cleverness.

## Licence

By contributing, you agree that your work is published under **GPL-3.0**, like the rest of the project. Openness propagates.
