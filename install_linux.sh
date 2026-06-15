#!/usr/bin/env bash
# =====================================================================
#  Miyoo Bifrost - Linux / Pop!_OS Installer (compatible Ubuntu/Debian)
#  Configure une carte SD pour le dual-boot Miyoo Mini / Mini Plus
#
#  Usage : bash install_linux.sh
#  Requis : Linux, zenity, rsync, dosfstools, python3, python3-pil
# =====================================================================
set -euo pipefail

# --- Check Linux ---
if [[ "$(uname)" != "Linux" ]]; then
    echo "Ce script est configuré pour Linux (Pop!_OS / Ubuntu / Debian)."
    echo "This script is configured for Linux."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Le Bureau n'existe pas toujours sous Linux : on bascule sur $HOME si besoin
if [[ -d "$HOME/Desktop" ]]; then
    LOG_FILE="$HOME/Desktop/bifrost_install.log"
else
    LOG_FILE="$HOME/bifrost_install.log"
fi
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
# Verification des dependances (zenity, rsync, dosfstools, python3, Pillow)
# Si une dependance manque : on propose de l'installer via sudo apt,
# sinon on affiche la commande exacte a lancer.
# ------------------------------------------------------------------
check_dependencies() {
    local -a missing_pkgs=()

    command -v zenity    &>/dev/null || missing_pkgs+=("zenity")
    command -v rsync     &>/dev/null || missing_pkgs+=("rsync")
    command -v mkfs.vfat &>/dev/null || missing_pkgs+=("dosfstools")
    if command -v python3 &>/dev/null; then
        python3 -c "import PIL" &>/dev/null || missing_pkgs+=("python3-pil")
    else
        missing_pkgs+=("python3" "python3-pil")
    fi

    if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
        echo "  Dependances OK : zenity, rsync, dosfstools, python3, python3-pil"
        log_only "Dependances OK"
        echo ""
        return 0
    fi

    echo ""
    echo "  Dependances manquantes / Missing dependencies :"
    echo "    ${missing_pkgs[*]}"
    echo ""
    echo "  Commande d'installation / Install command :"
    echo "    sudo apt update && sudo apt install -y ${missing_pkgs[*]}"
    echo ""
    log "Dependances manquantes: ${missing_pkgs[*]}" WARN

    read -rp "  Installer maintenant avec sudo ? / Install now with sudo? (o/n) [o] : " do_install
    do_install="${do_install:-o}"
    if [[ "$do_install" =~ ^[oOyYsS]$ ]]; then
        echo "  Installation via sudo apt (mot de passe sudo requis)..."
        if sudo apt update && sudo apt install -y "${missing_pkgs[@]}"; then
            echo "  Dependances installees avec succes."
            log_only "Dependances installees: ${missing_pkgs[*]}"
        else
            err "Echec de l'installation des dependances."
            echo "  Installe-les manuellement avec la commande ci-dessus, puis relance le script."
            exit 1
        fi
    else
        echo "  Installe les dependances ci-dessus, puis relance le script."
        log_only "Installation des dependances refusee"
        exit 1
    fi
    echo ""
}

# ------------------------------------------------------------------
# Folder picker via Zenity (Native GNOME dialog)
# Returns POSIX path, empty string on cancel
# ------------------------------------------------------------------
pick_folder() {
    local title="$1"
    local default_path="$2"
    local result

    if command -v zenity &>/dev/null; then
        result=$(zenity --file-selection --directory --title="$title" --filename="$default_path/" 2>/dev/null || true)
    else
        # Fallback au terminal si zenity n'est pas installé
        read -rp "  $title (chemin complet) : " result
    fi
    # Strip trailing slash
    echo "${result%/}"
}

# ------------------------------------------------------------------
echo ""
echo "  ========================================"
echo "    DUAL BOOT MIYOO MINI+ - Linux Installer"
echo "  ========================================"
echo ""

log "=== Bifrost Linux Installer ==="
log "Script: $SCRIPT_DIR"
log "User: $USER  OS: $(cat /etc/os-release | grep '^PRETTY_NAME=' | cut -d= -f2 | tr -d '\"')"

# --- Verification des dependances ---
check_dependencies

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

# ------------------------------------------------------------------
# Localized messages
# ------------------------------------------------------------------
case "$LANG_CODE" in
    EN)
        MSG_SELECT_SD="Select your SD CARD (mounted folder in /media/$USER/)..."
        MSG_SELECT_ONION="Select the ONIONOS folder..."
        MSG_SELECT_TELMI="Select the TELMIOS folder..."
        MSG_CANCEL="Cancelled."
        MSG_FAT32_WARN="!! WARNING: The card is not FAT32 !!"
        MSG_FAT32_REQ="The Miyoo firmware requires FAT32 to boot."
        MSG_FAT32_EXFAT="An exFAT or NTFS card will NOT boot."
        MSG_FAT32_ASK="Format to FAT32 now? Requires sudo password. (y/n) : "
        MSG_FAT32_STOP="STOPPED. Format the card to FAT32 before continuing."
        MSG_FAT32_OK="FAT32 detected — perfect!"
        MSG_FAT32_DONE="Format successful! Please eject and re-insert your SD card, then run this script again."
        MSG_SUCCESS="INSTALLATION SUCCESSFUL!"
        MSG_MISSING="missing file(s)"
        MSG_EJECT="Insert the SD card into your Miyoo Mini / Mini Plus."
        MSG_BOOT_TITLE="At startup:"
        MSG_BOOT_LR="D-pad left/right  = switch OS"
        MSG_BOOT_A="A                = confirm"
        MSG_BOOT_B="B                = relaunch last OS"
        MSG_BOOT_X="X (from boot)    = configuration menu"
        MSG_CHECK="Make sure the Onion* and Telmi* folders are in:"
        MSG_LOG="Log saved:"
        ;;
    ES)
        MSG_SELECT_SD="Selecciona tu TARJETA SD (carpeta montada en /media/$USER/)..."
        MSG_SELECT_ONION="Selecciona la carpeta ONIONOS..."
        MSG_SELECT_TELMI="Selecciona la carpeta TELMIOS..."
        MSG_CANCEL="Cancelado."
        MSG_FAT32_WARN="!! ATENCION: La tarjeta no esta en FAT32 !!"
        MSG_FAT32_REQ="El firmware Miyoo requiere FAT32 para arrancar."
        MSG_FAT32_EXFAT="Una tarjeta exFAT o NTFS NO arrancara."
        MSG_FAT32_ASK="Formatear a FAT32 ahora? Requiere contraseña sudo. (s/n) : "
        MSG_FAT32_STOP="DETENIDO. Formatea la tarjeta en FAT32 antes de continuar."
        MSG_FAT32_OK="FAT32 detectado — perfecto!"
        MSG_FAT32_DONE="Formato exitoso. Por favor, expulsa y vuelve a insertar tu tarjeta SD, y luego ejecuta este script nuevamente."
        MSG_SUCCESS="INSTALACION EXITOSA!"
        MSG_MISSING="archivo(s) faltante(s)"
        MSG_EJECT="Inserta la tarjeta SD en tu Miyoo Mini / Mini Plus."
        MSG_BOOT_TITLE="Al encender:"
        MSG_BOOT_LR="D-pad izq/der    = cambiar OS"
        MSG_BOOT_A="A                = confirmar"
        MSG_BOOT_B="B                = relanzar ultimo OS"
        MSG_BOOT_X="X (desde el boot)= menu de configuracion"
        MSG_CHECK="Verifica que las carpetas Onion* y Telmi* esten en:"
        MSG_LOG="Log guardado:"
        ;;
    *)
        MSG_SELECT_SD="Selectionnez votre CARTE SD (dossier monte dans /media/$USER/)..."
        MSG_SELECT_ONION="Selectionnez le dossier ONIONOS..."
        MSG_SELECT_TELMI="Selectionnez le dossier TELMIOS..."
        MSG_CANCEL="Annule."
        MSG_FAT32_WARN="!! ATTENTION : La carte n'est pas en FAT32 !!"
        MSG_FAT32_REQ="Le firmware Miyoo requiert FAT32 pour demarrer."
        MSG_FAT32_EXFAT="Une carte exFAT ou NTFS ne bootera PAS."
        MSG_FAT32_ASK="Formater en FAT32 maintenant ? Requier le mot de passe sudo. (o/n) : "
        MSG_FAT32_STOP="ARRET. Formate la carte en FAT32 avant de continuer."
        MSG_FAT32_OK="FAT32 detecte — parfait !"
        MSG_FAT32_DONE="Formatage réussi ! Veuillez retirer et réinsérer votre carte SD pour la monter correctement, puis relancez ce script."
        MSG_SUCCESS="INSTALLATION REUSSIE !"
        MSG_MISSING="fichier(s) manquant(s)"
        MSG_EJECT="Insere la carte SD dans le Miyoo Mini / Mini Plus."
        MSG_BOOT_TITLE="Au demarrage :"
        MSG_BOOT_LR="D-pad gauche/droite  = changer d'OS"
        MSG_BOOT_A="A                    = confirmer"
        MSG_BOOT_B="B                    = relancer le dernier OS"
        MSG_BOOT_X="X (depuis le boot)   = menu de configuration"
        MSG_CHECK="Verifie les dossiers Onion* et Telmi* dans :"
        MSG_LOG="Log sauvegarde :"
        ;;
esac
echo ""

# ------------------------------------------------------------------
# Select SD card
# ------------------------------------------------------------------
echo "  $MSG_SELECT_SD"
log "Ouverture selecteur carte SD"
SD="$(pick_folder "$MSG_SELECT_SD" "/media/$USER")"
if [[ -z "$SD" ]]; then
    log "SD: annule" WARN
    echo "  $MSG_CANCEL" && exit 1
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
disk_node=$(df "$SD" | tail -1 | awk '{print $1}')
fs_name=$(lsblk -no FSTYPE "$disk_node" 2>/dev/null || echo "Inconnu")

log "Volume: $(basename "$SD"), FS='$fs_name', Node=$disk_node"
echo "  Format: $fs_name"

if [[ "${fs_name,,}" != *"fat"* && "${fs_name,,}" != *"vfat"* ]]; then
    echo ""
    echo "  $MSG_FAT32_WARN"
    echo "  $MSG_FAT32_REQ"
    echo "  $MSG_FAT32_EXFAT"
    echo ""
    read -rp "  $MSG_FAT32_ASK" do_format
    if [[ "$do_format" =~ ^[oOyYsS]$ ]]; then
        log "Formatage FAT32: $disk_node"
        echo "  Formatage en cours (sudo mkfs.vfat)..."

        # Demonte avant formatage
        sudo umount "$disk_node" || true
        sudo mkfs.vfat -F 32 -n MIYOOBOOT "$disk_node"

        echo "  $MSG_FAT32_DONE"
        exit 0
    else
        log "Formatage refuse" WARN
        echo "  $MSG_FAT32_STOP"
        exit 1
    fi
else
    echo "  $MSG_FAT32_OK"
fi
echo ""

# ------------------------------------------------------------------
# Select OnionOS
# ------------------------------------------------------------------
echo "  $MSG_SELECT_ONION"
log "Ouverture selecteur OnionOS"
SRC_ONION="$(pick_folder "$MSG_SELECT_ONION" "$SCRIPT_DIR")"
if [[ -z "$SRC_ONION" ]]; then
    log "OnionOS: annule" WARN; echo "  $MSG_CANCEL"; exit 1
fi
log "OnionOS: $SRC_ONION"
echo "  OnionOS: $SRC_ONION"
echo ""

# ------------------------------------------------------------------
# Select TelmiOS
# ------------------------------------------------------------------
echo "  $MSG_SELECT_TELMI"
log "Ouverture selecteur TelmiOS"
SRC_TELMIOS="$(pick_folder "$MSG_SELECT_TELMI" "$SCRIPT_DIR")"
if [[ -z "$SRC_TELMIOS" ]]; then
    log "TelmiOS: annule" WARN; echo "  $MSG_CANCEL"; exit 1
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
    # sed -i sur Linux (GNU sed) ne requiert pas le '' vide
    sed -i "s/^LANG=.*/LANG=$LANG_CODE/" "$EXISTING_CFG"
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
if [[ -f "$SD/.tmp_update/res/bootmenu_onion_FR.raw" ]]; then
    log_only "Images .raw deja presentes (bundlees) - generation Python ignoree"
    echo "    OK - Images deja presentes (bundlees)"
    ok
else
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
        echo "    [IGNORE] Installe Python 3 (sudo apt install python3) puis lance generate_bootmenu.py"
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

# Eject SD card (Linux method)
echo ""
if command -v udisksctl &>/dev/null; then
    if udisksctl unmount -b "$disk_node" 2>/dev/null; then
        echo "  Carte SD éjectée en toute sécurité."
        log_only "Carte SD ejectee: $disk_node"
    fi
else
    if umount "$disk_node" 2>/dev/null; then
        echo "  Carte SD éjectée en toute sécurité."
        log_only "Carte SD ejectee: $disk_node"
    fi
fi

# Final result
echo ""
echo "  ========================================"
if [[ $errors -eq 0 ]]; then
    log "=== INSTALLATION REUSSIE ==="
    echo "  $MSG_SUCCESS"
    echo "  ========================================"
    echo ""
    echo "  $MSG_EJECT"
    echo ""
    echo "  $MSG_BOOT_TITLE"
    echo "    $MSG_BOOT_LR"
    echo "    $MSG_BOOT_A"
    echo "    $MSG_BOOT_B"
    echo "    $MSG_BOOT_X"
else
    log "=== INSTALLATION INCOMPLETE ($errors erreur(s)) ===" WARN
    echo "  $errors $MSG_MISSING"
    echo "  ========================================"
    echo "  $MSG_CHECK"
    echo "  $SCRIPT_DIR"
fi

echo ""
log "Log complet: $LOG_FILE"
echo "  $MSG_LOG $LOG_FILE"
echo ""
