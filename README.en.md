# NOLAM Adagio

[Français](README.md) · **English**

> *Slowly, and with ease.*

![Licence GPL-3.0](https://img.shields.io/badge/licence-GPL--3.0-2bb3b3)
![Platform](https://img.shields.io/badge/Linux%20Mint-Cinnamon-0d4a50)
![No sudo](https://img.shields.io/badge/no-sudo-success)
![Made in Switzerland](https://img.shields.io/badge/Made%20in-Switzerland%20%F0%9F%87%A8%F0%9F%87%AD-c39a3f)

**What if the computer finally looked like them?**

NOLAM Adagio adapts the **Linux Mint Cinnamon** desktop to the person using it — their sight, their gestures, their habits — instead of asking them to adapt to the machine. A single script, ready-made profiles, and **everything is reversible**.

Designed for **seniors** and people with **low vision**, to be installed by a relative or a technician.

![A NOLAM Adagio desktop in the senior profile: enlarged text, a clearly visible cursor, a clean menu with the "Adapt my screen" entry, alpine wallpaper](docs/screenshots/bureau-senior.png)

---

## Why

Accessibility settings already exist in Linux — but they're scattered across ten menus, and no one dares touch them for fear of breaking everything. Adagio gathers them into **coherent experiences**, applied with one command, undone with another.

Not a distribution to maintain. Not an over-engineered machine. A **gentle layer** on top of a stable system that you keep updated normally.

## Profiles

| Profile | For whom | What it does |
|---------|----------|--------------|
| `senior` | Declining sight, fear of mis-clicking | Bigger text, visible cursor, **single-click** to open, legible titles |
| `malvoyant` | Low vision | Greatly enlarged text, **high contrast**, huge cursor, **screen magnifier** enabled |

*Coming soon: `motricite` (large targets, anti-tremor), `cognitif` (clean, locked-down interface), `non-voyant` (Orca screen reader — in V2, with a tester who is genuinely concerned).*

## The "Adapt my screen" wizard

No need to know the profiles: Adagio includes a **graphical wizard** that sets up the display by asking simple questions — *"can you read this text clearly?"*, `A−` / `A+`, Light / Dark / Contrast thumbnails — with a **live preview**. It's designed to be usable **before** any adjustment: it starts out already large and high-contrast.

![Welcome screen of the NOLAM Adagio "Adapt my screen" wizard](docs/screenshots/assistant-bienvenue.png)

Two dimensions:

1. **Visual comfort** — three doors ("I see poorly", "gestures are hard", "I'm a beginner") lead to a profile, then you fine-tune live.
2. **Autonomy level** — *Calm* / *Curious* / *In control*: decides what is shown or hidden (technical tools, software store), because respecting autonomy is part of accessibility too.

Everything the wizard sets is written to a **reusable, exportable profile** (same format as `profiles/*.conf`). Re-openable any time via the **"Adapt my screen"** launcher. **Bilingual French / German** interface.

## Usage

```bash
git clone https://github.com/dpanbug/nolam-adagio.git
cd nolam-adagio

./install.sh --list          # list the profiles
./install.sh senior          # apply a profile
./restore.sh                 # put everything back as it was
```

No `sudo`: Adagio only changes your session settings (via `dconf`/`gsettings`), never the system.

## How it works

Each profile is a simple, readable `profiles/*.conf` file:

```ini
[org.cinnamon.desktop.interface]
text-scaling-factor = 1.4    # text 40% larger
cursor-size = 36             # clearly visible cursor
```

The engine reads these keys and applies them with `gsettings`. **Adding a variant = writing a file**, not code. Contributions are welcome.

Before applying anything, `install.sh` saves the complete state of your desktop (`dconf dump`). `restore.sh` reloads it identically. That's the safety net that lets you try without fear.

## Notes

- The `malvoyant` profile uses the **HighContrast** theme; if it isn't installed (`sudo apt install gnome-themes-extra`), Adagio cleanly skips that line and applies the rest.
- Tested on Linux Mint 21+ (Cinnamon). Settings absent from a given version are ignored without error.

## Licence

**GPL-3.0** (see [LICENSE](LICENSE)). Free software: you may use, study, modify and share it. Any derivative must stay free under the same licence — openness propagates, no one can lock this project away.

---

*A [NOLAM](https://nolam.ch) project — digital tools that give autonomy back, instead of confiscating it.*
*Overview: [nolam.ch/adagio](https://nolam.ch/adagio/) · Contributing: [CONTRIBUTING.en.md](CONTRIBUTING.en.md)*
