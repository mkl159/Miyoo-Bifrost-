# Miyoo-Bifrost

[![OnionOS](https://img.shields.io/badge/OnionOS-v4.3.1-4CAF50?style=for-the-badge&logo=github&logoColor=white)](https://github.com/OnionUI/Onion)
[![TelmiOS](https://img.shields.io/badge/TelmiOS-v1.10.1-FF8C00?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Turbo-Telmios/TelmiOS)

**Dual Boot pour Miyoo Mini / Mini Plus — OnionOS + TelmiOS**

Un bootloader léger qui affiche un menu graphique au démarrage pour choisir entre **OnionOS** (retrogaming) et **TelmiOS** (histoires pour enfants), avec protection parentale par code secret optionnelle.

---

## Aperçu

| OnionOS sélectionné | TelmiOS sélectionné |
|---|---|
| ![OnionOS](preview/bootmenu_onion_FR.png) | ![TelmiOS](preview/bootmenu_telmios_FR.png) |

| Écran protégé OnionOS | Écran protégé TelmiOS |
|---|---|
| ![Locked Onion](preview/bootmenu_locked_onion_FR.png) | ![Locked TelmiOS](preview/bootmenu_locked_telmios_FR.png) |

---

## Fonctionnalités

- **Menu graphique** affiché directement sur `/dev/fb0` — pas de SDL, zéro segfault
- **Navigation D-pad** : gauche/droite pour changer, A pour confirmer, B pour relancer le dernier OS
- **Vibration** au changement et à la confirmation (puissance configurable)
- **Timeout 60s** → boot automatique sur le dernier OS choisi
- **Mémorisation** du choix (fichier `.bootchoice` à la racine SD)
- **3 langues** : Français, English, Español
- **Compatibilité** Miyoo Mini (283) et Miyoo Mini Plus (354) — image pivotée 180° automatiquement pour MM
- **Protection parentale** : code secret par séquence de boutons (optionnel)
- **Configuration** par fichier texte simple sur la SD

---

## Versions OS supportées

| OS | Version testée |
|---|---|
| OnionOS | v4.3.1-1 |
| TelmiOS | v1.10.1 |

---

## Prérequis

- PC Windows
- Carte SD (32 Go recommandé) — FAT32 ≤ 32 Go, exFAT > 32 Go
- **OnionOS** : [github.com/OnionUI/Onion](https://github.com/OnionUI/Onion)
- **TelmiOS** : [github.com/telmios/telmios](https://github.com/telmios/telmios)
- Python 3 + Pillow (`pip install Pillow`) — pour générer les images du menu

---

## Installation rapide

### 1. Générer les images du menu
```bat
pip install Pillow
python generate_bootmenu.py
```

### 2. Installer automatiquement
Lancer `INSTALLER_SD.ps1` (clic droit → *Exécuter avec PowerShell*).

Le script copie automatiquement le bootloader, les binaires et les OS sur la SD.

### 3. Structure SD finale
```
SD:\
├── .tmp_update\          ← bootloader Bifrost
│   ├── runtime.sh
│   ├── bin\              ← copié depuis OnionOS
│   ├── lib\              ← copié depuis TelmiOS
│   ├── config\
│   │   └── dualboot.cfg  ← configuration
│   └── res\              ← images .raw générées
├── onion\                ← OnionOS complet
├── telmios\              ← TelmiOS complet
└── autorun.inf
```

---

## Utilisation

| Bouton | Action |
|---|---|
| ◄ Gauche | Sélectionner OnionOS |
| ► Droite | Sélectionner TelmiOS |
| A | Confirmer et lancer |
| B | Relancer le dernier OS mémorisé |
| *(timeout 60s)* | Boot automatique |

---

## Configuration

Éditer `SD:\.tmp_update\config\dualboot.cfg` :

```sh
LANG=FR                          # FR / EN / ES
VIBRATION_POWER=25               # 0-100
VIBRATION_SELECT=60              # ms changement OS
VIBRATION_CONFIRM=100            # ms confirmation

PASSWORD_PROTECT=none            # none / onion / telmios / both
PASSWORD_SEQUENCE="UP UP DOWN DOWN A"   # séquence boutons
```

### Protection parentale

Changer `PASSWORD_PROTECT=none` en `PASSWORD_PROTECT=onion` (ou `telmios` / `both`).

Au démarrage, si l'OS protégé est sélectionné, un écran cadenas apparaît. Entrer la séquence définie dans `PASSWORD_SEQUENCE`. Appuyer B pour annuler et revenir au menu.

---

## Architecture technique

Le firmware Miyoo exécute `/mnt/SDCARD/.tmp_update/runtime.sh` au démarrage. Bifrost s'y installe comme bootloader et utilise des **bind mounts Linux** pour rediriger les chemins vers l'OS choisi, de façon transparente pour chaque OS.

- Menu rendu via `dd if=image.raw of=/dev/fb0` (BGRA 640×480, sans SDL)
- Lectures des touches via `/dev/input/eventX` + `dd | od` en arrière-plan
- `unset SDL_VIDEODRIVER` avant `exec` → SDL auto-détecte `mmiyoo` sans crash
- Vibration via GPIO 48 (logique inversée : 0=ON, 1=OFF)

---

## Fichiers du projet

| Fichier | Rôle |
|---|---|
| `DualBoot/.tmp_update/runtime.sh` | Script bootloader principal |
| `DualBoot/.tmp_update/config/dualboot.cfg` | Configuration par défaut |
| `generate_bootmenu.py` | Génération des images menu (Python/Pillow) |
| `INSTALLER_SD.ps1` | Installation automatique sur SD (PowerShell) |
| `GUIDE_INSTALLATION.txt` | Guide d'installation détaillé |

---

## Licence

Projet communautaire non officiel. OnionOS et TelmiOS sont des projets indépendants.

- [OnionOS](https://github.com/OnionUI/Onion) — MIT License
- [TelmiOS](https://github.com/telmios/telmios)
