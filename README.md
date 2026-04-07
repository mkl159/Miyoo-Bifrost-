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
- Carte SD (32 Go recommandé) — FAT32 ≤ 32 Go, exFAT > 32 Go
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
| **Python 3** | [python.org/downloads](https://www.python.org/downloads/) — cocher *"Add to PATH"* à l'installation |

Une fois téléchargés, extrais les trois archives. Tu dois avoir ces dossiers organisés de cette façon :

```
📁 MonDossier\                   ← n'importe quel dossier sur ton PC
    📁 Miyoo-Bifrost\            ← ce projet (extrait du ZIP)
    📁 Onion-v4.3.1-1\           ← contenu de l'archive OnionOS
    📁 TelmiOS_v1.10.1\          ← contenu de l'archive TelmiOS
```

> ✅ **Les noms de dossiers n'ont pas besoin d'être modifiés** — l'installateur détecte automatiquement tout dossier commençant par `Onion` ou `Telmi`, qu'il soit dans le même dossier ou dans le dossier parent.

---

### Étape 1 — Installer Python et Pillow

1. Ouvre le **menu Démarrer**, cherche `cmd`, clique **Invite de commandes**
2. Tape cette commande et appuie sur **Entrée** :
   ```
   pip install Pillow
   ```
3. Attends que l'installation se termine (tu verras `Successfully installed Pillow`)

> Si tu vois une erreur `pip n'est pas reconnu`, réinstalle Python en cochant bien **"Add Python to PATH"**.

---

### Étape 2 — Formater la carte SD

> ⚠️ **SAUVEGARDE tes ROMs et sauvegardes avant !** Le formatage efface tout.

1. Insère ta carte SD dans ton PC
2. Ouvre l'**Explorateur de fichiers** (touche `Windows + E`)
3. Fais un **clic droit** sur la carte SD → **Formater...**
4. Choisis le système de fichiers :
   - Carte SD **≤ 32 Go** → sélectionne **FAT32**, taille d'unité **32 Ko**
   - Carte SD **> 32 Go** → sélectionne **exFAT**, taille d'unité **32 Ko**
5. Clique **Démarrer** puis confirme
6. Note la lettre de ta carte SD (ex: `E:`)

---

### Étape 3 — Générer les images du menu de démarrage

Les images du menu (Onion / TelmiOS) doivent être générées sur ton PC.

1. Ouvre l'**Explorateur de fichiers**
2. Va dans le dossier `Miyoo-Bifrost`
3. Dans la barre d'adresse en haut, clique et tape `cmd` puis **Entrée**
   → Une invite de commandes s'ouvre directement dans ce dossier
4. Tape :
   ```
   python generate_bootmenu.py
   ```
5. Tu dois voir s'afficher :
   ```
   [OK] Carte SD trouvee -> RAW direct sur E:\.tmp_update\res
   -> bootmenu_onion_FR ... OK
   -> bootmenu_telmios_FR ... OK
   ...
   TERMINE !
   ```

> Si la carte SD n'est pas encore insérée, le script crée les fichiers dans le dossier `Miyoo-Bifrost`. Il faudra les copier manuellement dans `SD:\.tmp_update\res\` plus tard.

---

### Étape 4 — Lancer l'installateur automatique

1. Dans le dossier `Miyoo-Bifrost`, fais un **clic droit** sur `INSTALLER_SD.ps1`
2. Clique **Exécuter avec PowerShell**

   > Si Windows bloque le script : clic droit → **Propriétés** → coche **Débloquer** → OK, puis réessaie.

3. L'installateur va :
   - ✅ Copier le bootloader Bifrost sur la SD
   - ✅ Copier les binaires d'OnionOS
   - ✅ Copier les librairies de TelmiOS
   - ✅ Installer TelmiOS dans `SD:\telmios\`
   - ✅ Installer OnionOS dans `SD:\onion\`
   - ✅ Vérifier que tout est en place

4. À la fin, tu dois voir **"INSTALLATION REUSSIE !"** en vert
   - Si des fichiers sont marqués `[MANQUANT]`, relis les étapes précédentes

---

### Étape 5 — Éjecter la carte SD proprement

> ⚠️ Ne retire pas la carte SD brutalement — des données pourraient être corrompues.

1. Dans l'Explorateur de fichiers, fais un **clic droit** sur la carte SD
2. Clique **Éjecter**
3. Attends le message *"Vous pouvez retirer le périphérique"*
4. Retire la carte SD

---

### Étape 6 — Insérer la carte SD et démarrer le Miyoo

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
