#!/usr/bin/env bash
# =====================================================================
#  Miyoo Bifrost - macOS Installer
#  Configure une carte SD pour le dual-boot Miyoo Mini / Mini Plus
#
#  Usage : bash install_macos.sh
#  Requis : macOS 10.14+, Python 3 + Pillow (pour les images)
# =====================================================================
set -euo pipefail

# --- Check macOS ---
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Ce script est uniquement compatible macOS."
    echo "This script is macOS only."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/Desktop/bifrost_install.log"
: > "$LOG_FILE"

# ------------------------------------------------------------------
log() {
    local msg="$1"
    local level="${2:-INFO}"
    local line="[$(date '+%H:%M:%S')] [$level] $msg"
    echo "$line" | tee -a "$LOG_FILE"
}

log_only() {
    local msg="$1"
    echo "[$(date '+%H:%M:%S')] $msg" >> "$LOG_FILE"
}

step() {
    echo ""
    echo "  $1"
    log_only "--- $1"
}

ok()   { echo "    OK"; }
warn() { echo "    [WARN] $1"; log_only "[WARN] $1"; }
err()  { echo "    [ERREUR] $1"; log_only "[ERREUR] $1"; }

# ------------------------------------------------------------------
# Folder picker via osascript (native macOS dialog)
# Returns POSIX path, empty string on cancel
# ------------------------------------------------------------------
pick_folder() {
    local title="$1"
    local default_path="$2"
    local result
    result=$(osascript \
        -e "tell application \"Finder\" to activate" \
        -e "try" \
        -e "  set chosen to choose folder with prompt \"$title\" default location POSIX file \"$default_path\"" \
        -e "  return POSIX path of chosen" \
        -e "on error" \
        -e "  return \"\"" \
        -e "end try" 2>/dev/null || true)
    # Strip trailing slash
    echo "${result%/}"
}

# ------------------------------------------------------------------
echo ""
echo "  ========================================"
echo "    DUAL BOOT MIYOO MINI+ - macOS Installer"
echo "  ========================================"
echo ""

log "=== Bifrost macOS Installer ==="
log "Script: $SCRIPT_DIR"
log "User: $USER  macOS: $(sw_vers -productVersion)"

# --- Language selection ---
echo "  Choisissez la langue / Choose language / Elige idioma :"
echo "    1) Francais (FR)"
echo "    2) English  (EN)"
echo "    3) Espanol  (ES)"
echo ""
read -rp "  Entree / Enter / Entrada (1/2/3) [1]: " lang_choice
lang_choice="${lang_choice:-1}"
case "$lang_choice" in
    2) LANG_CODE="EN" ;;
    3) LANG_CODE="ES" ;;
    *) LANG_CODE="FR" ;;
esac
log "Langue: $LANG_CODE"
echo ""

# ------------------------------------------------------------------
# Select SD card
# ------------------------------------------------------------------
echo "  Selectionnez votre CARTE SD (le dossier monte dans /Volumes/)..."
log "Ouverture selecteur carte SD"
SD="$(pick_folder "Selectionnez votre carte SD (/Volumes/...)" "/Volumes")"
if [[ -z "$SD" ]]; then
    log "SD: annule" WARN
    echo "  Annule." && exit 1
fi
log "SD: $SD"
echo "  SD: $SD"
echo ""

# --- Validate SD path ---
if [[ ! -d "$SD" ]]; then
    err "Le chemin '$SD' n'est pas accessible !"
    log "SD inaccessible: $SD" ERROR
    exit 1
fi

# ------------------------------------------------------------------
# FAT32 / MS-DOS check
# ------------------------------------------------------------------
echo "  Verification du format de la carte..."
disk_info="$(diskutil info "$SD" 2>/dev/null || true)"
fs_name="$(echo "$disk_info" | grep "File System Personality:" | sed 's/.*: *//')"
fs_type="$(echo "$disk_info" | grep "Type (Bundle):" | awk '{print $NF}')"
disk_node="$(echo "$disk_info" | grep "Device Node:" | awk '{print $NF}')"
log "Volume: $(basename "$SD"), FS='$fs_name' ($fs_type), Node=$disk_node"
echo "  Format: $fs_name"

if [[ "$fs_name" != *"FAT32"* && "$fs_name" != *"MS-DOS"* ]]; then
    echo ""
    echo "  !! ATTENTION : La carte n'est pas en FAT32 !!"
    echo "  Le firmware Miyoo requiert FAT32 pour demarrer."
    echo "  Une carte exFAT ou NTFS ne bootera PAS."
    echo ""
    read -rp "  Formater en FAT32 maintenant ? (o/n) : " do_format
    if [[ "$do_format" =~ ^[oOyYsS]$ ]]; then
        log "Formatage FAT32: $disk_node"
        echo "  Formatage en cours (diskutil eraseDisk)..."
        # eraseDisk needs the disk identifier (e.g. disk2), not the partition
        disk_id="$(echo "$disk_node" | sed 's/s[0-9]*$//')"
        diskutil eraseDisk FAT32 MIYOOBOOT MBRFormat "$disk_id"
        # Re-detect mount point after format
        sleep 2
        SD="/Volumes/MIYOOBOOT"
        log "Nouveau point de montage: $SD"
        echo "  FAT32 OK — Nouveau point de montage: $SD"
    else
        log "Formatage refuse" WARN
        echo "  ARRET. Formate la carte en FAT32 avant de continuer."
        exit 1
    fi
else
    echo "  FAT32 detecte — parfait !"
fi
echo ""

# ------------------------------------------------------------------
# Select OnionOS
# ------------------------------------------------------------------
echo "  Selectionnez le dossier ONIONOS..."
log "Ouverture selecteur OnionOS"
SRC_ONION="$(pick_folder "Selectionnez le dossier OnionOS" "$SCRIPT_DIR")"
if [[ -z "$SRC_ONION" ]]; then
    log "OnionOS: annule" WARN; echo "  Annule."; exit 1
fi
log "OnionOS: $SRC_ONION"
echo "  OnionOS: $SRC_ONION"
echo ""

# ------------------------------------------------------------------
# Select TelmiOS
# ------------------------------------------------------------------
echo "  Selectionnez le dossier TELMIOS..."
log "Ouverture selecteur TelmiOS"
SRC_TELMIOS="$(pick_folder "Selectionnez le dossier TelmiOS" "$SCRIPT_DIR")"
if [[ -z "$SRC_TELMIOS" ]]; then
    log "TelmiOS: annule" WARN; echo "  Annule."; exit 1
fi
log "TelmiOS: $SRC_TELMIOS"
echo "  TelmiOS: $SRC_TELMIOS"
echo ""

# ------------------------------------------------------------------
# Validate bin/ path
# ------------------------------------------------------------------
SRC_ONION_BIN="$SRC_ONION/miyoo/app/.tmp_update/bin"
[[ -d "$SRC_ONION_BIN" ]] || SRC_ONION_BIN="$SRC_ONION/.tmp_update/bin"
if [[ ! -d "$SRC_ONION_BIN" ]]; then
    err "Dossier bin/ introuvable dans OnionOS : $SRC_ONION_BIN"
    log "bin/ introuvable: $SRC_ONION_BIN" ERROR
    exit 1
fi
log "bin/: $SRC_ONION_BIN"
echo "  bin/: $SRC_ONION_BIN"

SRC_DUALBOOT="$SCRIPT_DIR/DualBoot"
if [[ ! -d "$SRC_DUALBOOT" ]]; then
    err "Dossier DualBoot introuvable : $SRC_DUALBOOT"
    log "DualBoot introuvable: $SRC_DUALBOOT" ERROR
    exit 1
fi
echo ""

# ==================================================================
step "ETAPE 1/8 — Nettoyage de l'ancienne structure..."
for item in "$SD/DualBoot" "$SD/.tmp_update"; do
    if [[ -d "$item" ]]; then
        rm -rf "$item"
        log_only "del: $item"
        echo "    del: $item"
    fi
done
for f in bootmenu_onion.png bootmenu_telmios.png generate_bootmenu.py system.json cachefile autorun.inf; do
    [[ -f "$SD/$f" ]] && { rm -f "$SD/$f"; log_only "del: $SD/$f"; }
done
ok

# ==================================================================
step "ETAPE 2/8 — Installation du bootloader Bifrost..."
EXISTING_CFG="$SD/.tmp_update/config/dualboot.cfg"
SAVED_CFG=""
if [[ -f "$EXISTING_CFG" ]]; then
    SAVED_CFG="$(cat "$EXISTING_CFG")"
    log_only "Config existante sauvegardee"
    echo "    Config existante sauvegardee"
fi

rsync -a "$SRC_DUALBOOT/.tmp_update/" "$SD/.tmp_update/"
log_only "DualBoot/.tmp_update -> $SD/.tmp_update"
echo "    DualBoot/.tmp_update/ -> $SD/.tmp_update/"

if [[ -n "$SAVED_CFG" ]]; then
    printf '%s' "$SAVED_CFG" > "$EXISTING_CFG"
    echo "    Config precedente restauree"
    log_only "Config restauree"
else
    # sed -i on macOS requires '' for in-place with no backup
    sed -i '' "s/^LANG=.*/LANG=$LANG_CODE/" "$EXISTING_CFG"
    echo "    LANG=$LANG_CODE defini dans dualboot.cfg"
    log_only "LANG=$LANG_CODE ecrit"
fi

[[ -f "$SRC_DUALBOOT/autorun.inf" ]] && cp "$SRC_DUALBOOT/autorun.inf" "$SD/autorun.inf"
log_only "autorun.inf copie"
ok

# ==================================================================
step "ETAPE 3/8 — Copie du fichier 'updater'..."
UPDATER_SRC="$SRC_ONION/.tmp_update/updater"
if [[ -f "$UPDATER_SRC" ]]; then
    cp "$UPDATER_SRC" "$SD/.tmp_update/updater"
    echo "    updater copie"
    log_only "updater copie"
else
    warn "updater non trouve: $UPDATER_SRC"
fi
ok

# ==================================================================
step "ETAPE 4/8 — Copie des binaires (bin/)  [peut prendre 1-2 min]..."
mkdir -p "$SD/.tmp_update/bin"
rsync -a "$SRC_ONION_BIN/" "$SD/.tmp_update/bin/"
bin_count=$(find "$SD/.tmp_update/bin" -type f | wc -l | tr -d ' ')
log_only "bin/ copie: $bin_count fichiers"
echo "    $bin_count fichiers"
ok

# ==================================================================
step "ETAPE 5/8 — Copie des librairies (lib/)  [peut prendre 1-2 min]..."
LIB_SRC="$SRC_TELMIOS/.tmp_update/lib"
if [[ ! -d "$LIB_SRC" ]]; then
    warn "lib/ non trouve: $LIB_SRC"
else
    mkdir -p "$SD/.tmp_update/lib"
    rsync -a "$LIB_SRC/" "$SD/.tmp_update/lib/"
    lib_count=$(find "$SD/.tmp_update/lib" -type f | wc -l | tr -d ' ')
    log_only "lib/ copie: $lib_count fichiers"
    echo "    $lib_count fichiers"
fi
ok

# ==================================================================
step "ETAPE 6/8 — Installation de TelmiOS  [peut prendre quelques minutes]..."
for t in "$SD/Telmios" "$SD/telmios"; do
    [[ -d "$t" ]] && { rm -rf "$t"; log_only "del: $t"; }
done
rsync -a "$SRC_TELMIOS/" "$SD/telmios/"
telmi_count=$(find "$SD/telmios" -type f | wc -l | tr -d ' ')
log_only "TelmiOS copie: $telmi_count fichiers"
echo "    TelmiOS -> telmios/  ($telmi_count fichiers)"
ok

# Telmi-Sync : Stories / Saves / Music -> racine SD
echo ""
echo "    [Telmi-Sync] Placement des donnees a la racine..."
for datadir in Stories Saves Music; do
    src_dir="$SD/telmios/$datadir"
    dst_dir="$SD/$datadir"
    if [[ -d "$src_dir" ]]; then
        if [[ -d "$dst_dir" ]]; then
            rm -rf "$src_dir"
            log_only "telmios/$datadir supprime (racine conservee)"
        else
            mv "$src_dir" "$dst_dir"
            log_only "Deplace telmios/$datadir -> $dst_dir"
            echo "    [Telmi-Sync] telmios/$datadir -> /$datadir"
        fi
    fi
done
mkdir -p "$SD/Saves"
if [[ ! -f "$SD/Saves/.parameters" ]]; then
    echo '{}' > "$SD/Saves/.parameters"
    log_only "Saves/.parameters cree"
    echo "    [Telmi-Sync] Saves/.parameters cree"
fi

# ==================================================================
step "ETAPE 7/8 — Installation de OnionOS  [peut prendre quelques minutes]..."
[[ -d "$SD/onion" ]] && { rm -rf "$SD/onion"; log_only "del: $SD/onion"; }
rsync -a "$SRC_ONION/" "$SD/onion/"
onion_count=$(find "$SD/onion" -type f | wc -l | tr -d ' ')
log_only "OnionOS copie: $onion_count fichiers"
echo "    OnionOS -> onion/  ($onion_count fichiers)"
ok

# ==================================================================
step "ETAPE 8/8 — Generation des images du menu de boot..."
PY_SCRIPT="$SCRIPT_DIR/generate_bootmenu.py"
if [[ ! -f "$PY_SCRIPT" ]]; then
    warn "generate_bootmenu.py non trouve: $PY_SCRIPT"
    echo "    [IGNORE] Lance generate_bootmenu.py manuellement avec la SD inseree"
else
    PYTHON_CMD=""
    for cmd in python3 python; do
        if command -v "$cmd" &>/dev/null; then
            PYTHON_CMD="$cmd"; break
        fi
    done

    if [[ -z "$PYTHON_CMD" ]]; then
        warn "Python non trouve"
        echo "    [IGNORE] Installe Python 3 (https://www.python.org) puis lance generate_bootmenu.py"
    else
        log_only "Python: $PYTHON_CMD"
        echo "    Python: $PYTHON_CMD"
        if ! "$PYTHON_CMD" -c "import PIL" 2>/dev/null; then
            echo "    Installation de Pillow..."
            "$PYTHON_CMD" -m pip install Pillow --quiet
        fi
        echo "    Generation des images RAW (FR/EN/ES)..."
        if "$PYTHON_CMD" "$PY_SCRIPT" "$SD" >> "$LOG_FILE" 2>&1; then
            log_only "Images generees avec succes"
            echo "    OK - Images generees"
        else
            warn "ERREUR lors de la generation des images"
            echo "    Lance generate_bootmenu.py manuellement si necessaire"
        fi
    fi
fi

# ==================================================================
echo ""
echo "  Verification de la structure finale..."
log_only "--- VERIFICATION FINALE ---"
errors=0

check_file() {
    local f="$1"
    if [[ -f "$f" ]]; then
        echo "    [OK] $f"
        log_only "OK: $f"
    else
        echo "    [MANQUANT] $f"
        log_only "MANQUANT: $f"
        ((errors++)) || true
    fi
}

check_file "$SD/.tmp_update/runtime.sh"
check_file "$SD/.tmp_update/updater"
check_file "$SD/.tmp_update/bin/prompt"
check_file "$SD/.tmp_update/lib/libSDL-1.2.so.0"
check_file "$SD/.tmp_update/config/dualboot.cfg"
check_file "$SD/telmios/.tmp_update/runtime.sh"

if [[ -f "$SD/onion/miyoo/app/.tmp_update/install.sh" || -f "$SD/onion/.tmp_update/runtime.sh" ]]; then
    echo "    [OK] onion/ pret"
    log_only "OK: onion/"
else
    echo "    [MANQUANT] onion/ incomplet"
    log_only "MANQUANT: onion/"
    ((errors++)) || true
fi

if [[ -f "$SD/.tmp_update/res/bootmenu_onion_FR.raw" || -f "$SD/.tmp_update/res/bootmenu_onion.raw" ]]; then
    echo "    [OK] Images .raw presentes"
else
    echo "    [AVERT] Images .raw manquantes — lance generate_bootmenu.py"
    log_only "[AVERT] images .raw manquantes"
fi

# Eject SD card
echo ""
if [[ "$SD" == /Volumes/* ]]; then
    if diskutil unmount "$SD" 2>/dev/null; then
        echo "  Carte SD ejectee en toute securite."
        log_only "Carte SD ejectee: $SD"
    fi
fi

# Final result
echo ""
echo "  ========================================"
if [[ $errors -eq 0 ]]; then
    log "=== INSTALLATION REUSSIE ==="
    echo "  INSTALLATION REUSSIE !"
    echo "  ========================================"
    echo ""
    echo "  Insere la carte SD dans le Miyoo Mini / Mini Plus."
    echo ""
    echo "  Au demarrage :"
    echo "    D-pad gauche/droite  = changer d'OS"
    echo "    A                    = confirmer"
    echo "    B                    = relancer le dernier OS"
    echo "    X (depuis le boot)   = menu de configuration"
else
    log "=== INSTALLATION INCOMPLETE ($errors erreur(s)) ===" WARN
    echo "  $errors fichier(s) manquant(s)"
    echo "  ========================================"
    echo "  Verifie les dossiers Onion* et Telmi* dans :"
    echo "  $SCRIPT_DIR"
fi

echo ""
log "Log complet: $LOG_FILE"
echo "  Log sauvegarde : $LOG_FILE"
echo ""
