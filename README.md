# Miyoo-Bifrost

[![OnionOS](https://img.shields.io/badge/OnionOS-v4.3.1-4CAF50?style=for-the-badge&logo=github&logoColor=white)](https://github.com/OnionUI/Onion)
[![TelmiOS](https://img.shields.io/badge/TelmiOS-v1.10.1-FF8C00?style=for-the-badge&logo=github&logoColor=white)](https://github.com/DantSu/Telmi-story-teller)
[![Vibe coded with Claude Code](https://img.shields.io/badge/Vibe%20coded%20with-Claude%20Code-blueviolet?style=for-the-badge&logo=anthropic&logoColor=white)](https://claude.ai/code)

**Dual Boot pour Miyoo Mini / Mini Plus — OnionOS + TelmiOS**

Un bootloader léger qui affiche un menu graphique au démarrage pour choisir entre **OnionOS** (retrogaming) et **TelmiOS** (histoires pour enfants), avec protection parentale par code secret optionnelle.

> 🤖 Ce projet a été entièrement **vibe codé avec [Claude Code](https://claude.ai/code)** — l'IA de développement d'Anthropic.

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
- Carte SD formatée en **FAT32** (obligatoire — le firmware Miyoo ne supporte pas exFAT)
  - Carte **≤ 32 Go** : Windows peut formater directement en FAT32
  - Carte **> 32 Go** : utilise **[Rufus](https://rufus.ie)** → FAT32, taille d'unité 32 Ko
- **OnionOS** : [github.com/OnionUI/Onion](https://github.com/OnionUI/Onion)
- **TelmiOS** : [github.com/telmios/telmios](https://github.com/telmios/telmios)
- Python 3 + Pillow (`pip install Pillow`) — pour générer les images du menu

---

## Installation — Guide complet pas à pas

> ⏱️ Durée estimée : 15 à 30 minutes selon la taille de ta carte SD.

---

### Étape 0 — Ce dont tu as besoin

Avant de commencer, télécharge et prépare ces éléments sur ton PC :

| Élément | Où le trouver |
|---|---|
| **Ce projet** (Miyoo-Bifrost) | Bouton vert **Code → Download ZIP** sur cette page |
| **OnionOS** (ex: `Onion-v4.3.1-1.zip`) | [Releases OnionOS](https://github.com/OnionUI/Onion/releases) |
| **TelmiOS** (ex: `TelmiOS_v1.10.1.zip`) | [Releases TelmiOS](https://github.com/DantSu/Telmi-story-teller/releases) |
| **Python 3** *(optionnel)* | [python.org/downloads](https://www.python.org/downloads/) — cocher *"Add to PATH"* — nécessaire pour les images du menu |

Une fois téléchargés, extrais les trois archives. Tu dois avoir ces dossiers organisés de cette façon :

```
📁 MonDossier\                   ← n'importe quel dossier sur ton PC
    📁 Miyoo-Bifrost\            ← ce projet (extrait du ZIP)
    📁 Onion-v4.3.1-1\           ← contenu de l'archive OnionOS
    📁 TelmiOS_v1.10.1\          ← contenu de l'archive TelmiOS
```

> ✅ **Les noms de dossiers n'ont pas besoin d'être modifiés** — l'installateur détecte automatiquement tout dossier commençant par `Onion` ou `Telmi`, qu'il soit dans le même dossier ou dans le dossier parent.

---

### Étape 1 — Installer Python *(optionnel mais recommandé)*

Python est nécessaire pour générer les images du menu de boot. L'installateur installe **Pillow automatiquement** si Python est présent.

1. Télécharge Python 3 sur [python.org/downloads](https://www.python.org/downloads/)
2. Lance l'installateur et coche bien **"Add Python to PATH"** avant de cliquer *Install Now*

> Si tu sautes cette étape, l'installation fonctionnera quand même mais les images du menu ne seront pas générées (écran noir au démarrage).

---

### Étape 2 — Formater la carte SD en FAT32

> ⚠️ **SAUVEGARDE tes ROMs et sauvegardes avant !** Le formatage efface tout.

> ❗ **FAT32 est obligatoire.** Le firmware interne du Miyoo ne supporte pas exFAT — une carte exFAT ne bootera pas.

**Carte ≤ 32 Go** — Formatage Windows :
1. Clic droit sur la carte SD → **Formater...**
2. Système de fichiers : **FAT32**, taille d'unité : **32 Ko**
3. Clique **Démarrer**

**Carte > 32 Go** — Windows ne peut pas faire FAT32 au-delà de 32 Go, utilise **Rufus** :
1. Télécharge **[Rufus](https://rufus.ie)** (gratuit)
2. Sélectionne ta carte SD
3. Système de fichiers : **FAT32**, taille d'unité : **32 Ko**
4. Clique **Démarrer**

---

### Étape 3 — Lancer l'installateur automatique

1. Dans le dossier `Miyoo-Bifrost`, fais un **clic droit** sur `INSTALLER_SD.ps1`
2. Clique **Exécuter avec PowerShell**

   > Si Windows bloque le script : clic droit → **Propriétés** → coche **Débloquer** → OK, puis réessaie.

3. **Trois fenêtres de sélection** s'ouvrent dans l'ordre — navigue et clique OK :
   - 📁 **Carte SD** — sélectionne ton lecteur SD (ex: `E:\`)
   - 📁 **OnionOS** — sélectionne le dossier `Onion-v4.3.1-1`
   - 📁 **TelmiOS** — sélectionne le dossier `TelmiOS_v1.10.1`

4. L'installateur fait tout automatiquement :
   - ✅ Copie le bootloader Bifrost sur la SD
   - ✅ Copie les binaires d'OnionOS
   - ✅ Copie les librairies de TelmiOS
   - ✅ Installe TelmiOS dans `SD:\telmios\`
   - ✅ Installe OnionOS dans `SD:\onion\`
   - ✅ Installe Pillow si nécessaire (`pip install Pillow` automatique)
   - ✅ Génère les images du menu de boot (FR / EN / ES)
   - ✅ Vérifie que tout est en place

5. À la fin, tu dois voir **"INSTALLATION REUSSIE !"** en vert
   - Si des fichiers sont marqués `[MANQUANT]`, relis les étapes précédentes

> **Python requis pour les images du menu.** Si Python n'est pas installé, l'installateur continue sans générer les images. Installe Python 3 depuis [python.org](https://www.python.org/downloads/) (cocher *"Add to PATH"*), puis relance le script.

---

### Étape 4 — Éjecter la carte SD proprement

> ⚠️ Ne retire pas la carte SD brutalement — des données pourraient être corrompues.

1. Dans l'Explorateur de fichiers, fais un **clic droit** sur la carte SD
2. Clique **Éjecter**
3. Attends le message *"Vous pouvez retirer le périphérique"*
4. Retire la carte SD

---

### Étape 5 — Insérer la carte SD et démarrer le Miyoo

1. Insère la carte SD dans ton **Miyoo Mini / Mini Plus**
2. Allume la console en maintenant le bouton Power
3. Le **menu Bifrost** apparaît après quelques secondes :
   - À **gauche** : OnionOS (retrogaming)
   - À **droite** : TelmiOS (histoires)

---

### Utilisation du menu

| Bouton | Action |
|---|---|
| **◄ Gauche** | Passer sur OnionOS |
| **► Droite** | Passer sur TelmiOS |
| **A** | Confirmer et lancer l'OS |
| **B** | Lancer directement le dernier OS utilisé |
| *(60 secondes sans action)* | Lance automatiquement le dernier OS |

Le choix est **mémorisé automatiquement** — au prochain démarrage, la console proposera en priorité le dernier OS utilisé.

---

### En cas de problème

| Symptôme | Solution |
|---|---|
| Écran noir au démarrage | Vérifie que `SD:\.tmp_update\runtime.sh` existe |
| Menu ne s'affiche pas | Relance `generate_bootmenu.py` avec la SD insérée |
| OnionOS ne démarre pas | Vérifie que `SD:\onion\` contient bien les fichiers OnionOS |
| TelmiOS ne démarre pas | Vérifie que `SD:\telmios\` contient bien les fichiers TelmiOS |
| La console redémarre en boucle | Les librairies dans `SD:\.tmp_update\lib\` doivent venir de TelmiOS |
| Installateur bloqué par Windows | Clic droit sur `.ps1` → Propriétés → Débloquer |

> Les logs de démarrage sont disponibles sur la SD dans `.tmp_update\logs\dualboot.log`

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
