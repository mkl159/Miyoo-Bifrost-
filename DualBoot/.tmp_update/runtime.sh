#!/bin/sh
# =============================================================
#  DUAL BOOT SELECTOR - Miyoo Mini / Mini Plus / Mini Flip
#  Affichage direct sur /dev/fb0 (bypass SDL = pas de segfault)
# =============================================================

sysdir=/mnt/SDCARD/.tmp_update
miyoodir=/mnt/SDCARD/miyoo
TELMIOS_DIR=/mnt/SDCARD/telmios
ONION_DIR=/mnt/SDCARD/onion
CHOICE_FILE=/mnt/SDCARD/.bootchoice
MODEL_MM=283
MODEL_MMP=354

mkdir -p "$sysdir/logs"
LOG="$sysdir/logs/dualboot.log"
rm -f "$LOG"
log() { echo "[$(date +%H:%M:%S)] $*" >> "$LOG"; sync; }
log "=== DualBoot start ==="

# =============================================================
#  Constantes keycodes (Linux input event codes)
# =============================================================
KEY_UP=103
KEY_DOWN=108
KEY_LEFT=105
KEY_RIGHT=106
KEY_A=28
KEY_B=14
KEY_X=42
KEY_Y=21
KEY_L1=310
KEY_R1=311
KEY_START=315
KEY_SELECT=314

# =============================================================
#  Chargement securise de la configuration
#  (parse ligne par ligne, valide chaque valeur)
# =============================================================
LANG="FR"
VIBRATION_POWER=25
VIBRATION_SELECT=60
VIBRATION_CONFIRM=100
PASSWORD_PROTECT="none"
PASSWORD_SEQUENCE=""
CONFIG_SEQUENCE="UP UP DOWN DOWN"

_is_num() { case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

_is_valid_btn_seq() {
    for _b in $1; do
        case "$_b" in
            UP|DOWN|LEFT|RIGHT|A|B|X|Y|L|L1|R|R1|START|SELECT) ;;
            *) return 1 ;;
        esac
    done
    return 0
}

_safe_read_cfg() {
    local _cfg="$1"
    [ -f "$_cfg" ] || return
    while IFS='=' read -r _key _val; do
        # Ignorer commentaires et lignes vides
        case "$_key" in \#*|"") continue ;; esac
        # Retirer guillemets autour de la valeur
        _val=$(echo "$_val" | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")
        # Retirer commentaire inline
        _val=$(echo "$_val" | sed 's/ *#.*//')
        case "$_key" in
            LANG)
                case "$_val" in FR|EN|ES) LANG="$_val" ;; esac ;;
            VIBRATION_POWER)
                _is_num "$_val" && [ "$_val" -ge 0 ] && [ "$_val" -le 100 ] && VIBRATION_POWER="$_val" ;;
            VIBRATION_SELECT)
                _is_num "$_val" && [ "$_val" -ge 0 ] && [ "$_val" -le 500 ] && VIBRATION_SELECT="$_val" ;;
            VIBRATION_CONFIRM)
                _is_num "$_val" && [ "$_val" -ge 0 ] && [ "$_val" -le 500 ] && VIBRATION_CONFIRM="$_val" ;;
            PASSWORD_PROTECT)
                case "$_val" in none|onion|telmios|both) PASSWORD_PROTECT="$_val" ;; esac ;;
            PASSWORD_SEQUENCE)
                _is_valid_btn_seq "$_val" && PASSWORD_SEQUENCE="$_val" ;;
            CONFIG_SEQUENCE)
                _is_valid_btn_seq "$_val" && CONFIG_SEQUENCE="$_val" ;;
        esac
    done < "$_cfg"
}

CONFIG="$sysdir/config/dualboot.cfg"
_safe_read_cfg "$CONFIG"
log "Config: LANG=$LANG VP=$VIBRATION_POWER VS=$VIBRATION_SELECT VC=$VIBRATION_CONFIRM PP=$PASSWORD_PROTECT"

# ---- Detecter modele ----
axp 0 > /dev/null 2>&1
[ $? -eq 0 ] && DEVICE_ID=$MODEL_MMP || DEVICE_ID=$MODEL_MM
export DEVICE_ID
echo -n "$DEVICE_ID" > /tmp/deviceModel
log "DEVICE_ID=$DEVICE_ID"

touch /tmp/is_booting

# ---- Monter Onion miyoo (pour bin/ et lib/) ----
mkdir -p $miyoodir
mount --bind "$ONION_DIR/miyoo" $miyoodir 2>/dev/null
log "Onion miyoo mounted"

export LD_LIBRARY_PATH="/lib:/config/lib:$miyoodir/lib:$sysdir/lib"
export PATH="$ONION_DIR/.tmp_update/bin:$sysdir/bin:$PATH"
export SDL_VIDEODRIVER=mmiyoo
export SDL_AUDIODRIVER=mmiyoo
export EGL_VIDEODRIVER=mmiyoo

# ---- load_settings ----
load_settings() {
    s="$sysdir/res/miyoo${DEVICE_ID}_system.json"
    [ -f "$s" ] && cp -f "$s" /mnt/SDCARD/system.json
    rm -f /appconfigs/system.json
    ln -s /mnt/SDCARD/system.json /appconfigs/system.json
    if [ $DEVICE_ID -eq $MODEL_MM ]; then
        if [ ! -f /sys/devices/gpiochip0/gpio/gpio59/direction ]; then
            echo 59 > /sys/class/gpio/export 2>/dev/null
            echo in > /sys/devices/gpiochip0/gpio/gpio59/direction 2>/dev/null
        fi
    fi
}

# ---- init_system ----
init_system() {
    load_settings
    # Activer le controleur d'ecran (obligatoire avant tout acces a /dev/fb0)
    cat /proc/ls 2>/dev/null
    brightness=$(/customer/app/jsonval brightness 2>/dev/null || echo 7)
    brightness_raw=$(awk "BEGIN { print int(3 * exp(0.350656 * $brightness) + 0.5) }" 2>/dev/null || echo 8)
    echo 800 > /sys/class/pwm/pwmchip0/pwm0/period 2>/dev/null
    echo "$brightness_raw" > /sys/class/pwm/pwmchip0/pwm0/duty_cycle 2>/dev/null
    echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable 2>/dev/null
    log "init_system done"
}

init_system

# ---- Vibration (GPIO 48, logique inversee : 0=ON 1=OFF) ----
echo 48 > /sys/class/gpio/export 2>/dev/null
echo out > /sys/class/gpio/gpio48/direction 2>/dev/null
echo 1 > /sys/class/gpio/gpio48/value 2>/dev/null

# ---- Check charge ----
if [ $DEVICE_ID -eq $MODEL_MMP ]; then
    axp_status="0x$(axp 0 | cut -d':' -f2)"
    is_charging=$([ $(($axp_status & 0x4)) -eq 4 ] && echo 1 || echo 0)
else
    is_charging=$(cat /sys/devices/gpiochip0/gpio/gpio59/value 2>/dev/null || echo 0)
fi
log "charging=$is_charging"
[ "$is_charging" = "1" ] && cd "$sysdir" && chargingState

# ---- Vibration (puissance 1-100) ----
vibrate() {
    local ms="${1:-100}"
    [ "$VIBRATION_POWER" -eq 0 ] 2>/dev/null && return
    local effective=$(awk "BEGIN { v=int($ms * $VIBRATION_POWER / 100); print (v<5?5:v) }" 2>/dev/null)
    echo 0 > /sys/class/gpio/gpio48/value 2>/dev/null
    sleep $(awk "BEGIN { printf \"%.3f\", $effective / 1000 }" 2>/dev/null)
    echo 1 > /sys/class/gpio/gpio48/value 2>/dev/null
}

# =============================================================
#  Conversion noms de boutons <-> keycodes
# =============================================================

# Convertit un nom de bouton en keycode
_btn_to_code() {
    case "$1" in
        UP)     echo $KEY_UP     ;; DOWN)   echo $KEY_DOWN   ;;
        LEFT)   echo $KEY_LEFT   ;; RIGHT)  echo $KEY_RIGHT  ;;
        A)      echo $KEY_A      ;; B)      echo $KEY_B      ;;
        X)      echo $KEY_X      ;; Y)      echo $KEY_Y      ;;
        L|L1)   echo $KEY_L1     ;; R|R1)   echo $KEY_R1     ;;
        START)  echo $KEY_START  ;; SELECT) echo $KEY_SELECT ;;
    esac
}

# Convertit un keycode en nom de bouton
_code_to_btn() {
    case "$1" in
        $KEY_UP)     echo "UP"     ;; $KEY_DOWN)   echo "DOWN"   ;;
        $KEY_LEFT)   echo "LEFT"   ;; $KEY_RIGHT)  echo "RIGHT"  ;;
        $KEY_A)      echo "A"      ;; $KEY_B)      echo "B"      ;;
        $KEY_X)      echo "X"      ;; $KEY_Y)      echo "Y"      ;;
        $KEY_L1)     echo "L1"     ;; $KEY_R1)     echo "R1"     ;;
        $KEY_START)  echo "START"  ;; $KEY_SELECT) echo "SELECT" ;;
    esac
}

# Convertit une sequence de noms en codes (espace-separated)
_seq_to_codes() {
    local _r=""
    for _b in $@; do
        local _c=$(_btn_to_code "$_b")
        [ -n "$_c" ] && _r="$_r $_c"
    done
    echo $_r
}

# Convertit une suite de codes en noms de boutons
_codes_to_names() {
    local _r=""
    for _c in $@; do
        local _n=$(_code_to_btn "$_c")
        [ -n "$_n" ] && _r="$_r $_n"
    done
    echo $_r
}

# Normalise un keycode (variantes hardware -> code canonique)
_norm_key() {
    case "$1" in
        57|97|305|$KEY_START) echo $KEY_A  ;;  # A et toutes ses variantes
        *)                    echo "$1"    ;;
    esac
}

# Normalise un keycode pour le mode password (L1/R1 -> LEFT/RIGHT en plus)
_norm_key_pw() {
    case "$1" in
        57|97|305|$KEY_START) echo $KEY_A     ;;
        $KEY_L1)              echo $KEY_LEFT  ;;
        $KEY_R1)              echo $KEY_RIGHT ;;
        *)                    echo "$1"       ;;
    esac
}

# =============================================================
#  Lecteurs d'input (start/stop factorise)
# =============================================================
KEY_FILE=/tmp/dualboot_key

# Demarre les lecteurs sur tous les /dev/input/event* disponibles
# $1 = fichier destination (defaut: KEY_FILE)
# $2 = "pw" pour normalisation password, sinon raw
# Retourne les PIDs dans _STARTED_PIDS
_start_readers() {
    local _dest="${1:-$KEY_FILE}"
    local _mode="${2:-raw}"
    _STARTED_PIDS=""
    rm -f "$_dest"
    for _ev in /dev/input/event0 /dev/input/event1 /dev/input/event2 /dev/input/event3; do
        if [ -c "$_ev" ]; then
            if [ "$_mode" = "pw" ]; then
                (
                    while true; do
                        evt=$(dd if="$_ev" bs=16 count=1 2>/dev/null | od -An -tu2 -v)
                        set -- $evt
                        if [ $# -ge 7 ] && [ "$5" = "1" ] && [ "$7" = "1" ]; then
                            _nk=$(_norm_key_pw "$6")
                            echo "$_nk" >> "$_dest"
                        fi
                    done
                ) &
            else
                (
                    while true; do
                        evt=$(dd if="$_ev" bs=16 count=1 2>/dev/null | od -An -tu2 -v)
                        set -- $evt
                        if [ $# -ge 7 ] && [ "$5" = "1" ] && [ "$7" = "1" ]; then
                            echo "$6" >> "$_dest"
                            log "KEY=$6 from $_ev"
                        fi
                    done
                ) &
            fi
            _STARTED_PIDS="$_STARTED_PIDS $!"
        fi
    done
    log "Readers started [$_mode] -> $_dest (PIDs:$_STARTED_PIDS)"
}

# Arrete une liste de PIDs de lecteurs et nettoie les sous-processus
# $1 = liste de PIDs
_stop_readers() {
    local _pids="$1"
    for _p in $_pids; do
        kill "$_p" 2>/dev/null
    done
    sleep 0.2
    # dd bloquant sur /dev/input/event* survit au kill du subshell parent
    # et consomme les evenements clavier destines aux nouveaux readers
    killall dd 2>/dev/null
    killall od 2>/dev/null
    for _p in $_pids; do
        kill -9 "$_p" 2>/dev/null
    done
    sleep 0.1
}

# =============================================================
#  Presets vibration (factorises)
# =============================================================
_apply_vib_preset() {
    case "$1" in
        0) VIBRATION_POWER=0;  VIBRATION_SELECT=0;   VIBRATION_CONFIRM=0   ;;
        1) VIBRATION_POWER=15; VIBRATION_SELECT=40;  VIBRATION_CONFIRM=80  ;;
        2) VIBRATION_POWER=25; VIBRATION_SELECT=60;  VIBRATION_CONFIRM=100 ;;
        3) VIBRATION_POWER=50; VIBRATION_SELECT=100; VIBRATION_CONFIRM=200 ;;
    esac
}

# =============================================================
#  MENU DE CONFIGURATION (acces par X dans le menu boot)
# =============================================================

# Sauvegarde la configuration courante dans dualboot.cfg
do_save_config() {
    {
        echo "# DualBoot Configuration - sauvegardee par le menu Bifrost"
        echo "LANG=$LANG"
        echo "VIBRATION_POWER=$VIBRATION_POWER"
        echo "VIBRATION_SELECT=$VIBRATION_SELECT"
        echo "VIBRATION_CONFIRM=$VIBRATION_CONFIRM"
        echo "PASSWORD_PROTECT=$PASSWORD_PROTECT"
        echo "PASSWORD_SEQUENCE=\"$PASSWORD_SEQUENCE\""
        echo "CONFIG_SEQUENCE=\"$CONFIG_SEQUENCE\""
    } > "$CONFIG"
    sync
    log "Config saved: PP=$PASSWORD_PROTECT VP=$VIBRATION_POWER PW='$PASSWORD_SEQUENCE' CS='$CONFIG_SEQUENCE'"
}

# Rechargement securise de la config (pour annulation)
_reload_config() {
    _safe_read_cfg "$CONFIG"
}

# Attend une touche dans KEY_FILE
# $1 = timeout en unites de 0.1s (defaut 300 = 30s)
_wait_cfg_key() {
    local _t=0 _max="${1:-300}"
    while [ $_t -lt $_max ]; do
        if [ -s "$KEY_FILE" ]; then
            tail -1 "$KEY_FILE" 2>/dev/null
            > "$KEY_FILE"
            return 0
        fi
        sleep 0.1
        _t=$((_t+1))
    done
    return 1
}

# Affiche config_access, attend la sequence admin
# Retourne 0 si correct, 1 sinon/timeout/annule
check_config_access() {
    show_menu "config_access"
    > "$KEY_FILE"

    local _expected
    _expected=$(_seq_to_codes $CONFIG_SEQUENCE)
    local _elen
    _elen=$(echo $_expected | wc -w)

    [ "$_elen" -eq 0 ] && { vibrate 80; return 0; }

    local _pressed="" _pcount=0 _idle=0

    while [ $_pcount -lt $_elen ] && [ $_idle -lt 300 ]; do
        local _raw
        _raw=$(_wait_cfg_key 1)
        if [ -z "$_raw" ]; then
            _idle=$((_idle+1))
            continue
        fi
        _idle=0
        local _k
        _k=$(_norm_key "$_raw")
        case "$_k" in
            $KEY_SELECT) log "Config access: annule (SELECT)"; vibrate 100; return 1 ;;
            $KEY_A) break ;;
            *)  _pressed="$_pressed $_k"
                _pcount=$((_pcount+1))
                vibrate 25
                log "Config access: $_pcount/$_elen k=$_k" ;;
        esac
    done

    _pressed=$(echo $_pressed)
    log "Config access: pressed='$_pressed' expected='$_expected'"

    if [ "$_pressed" = "$_expected" ]; then
        vibrate 150; return 0
    else
        vibrate 200; sleep 0.12; vibrate 200; return 1
    fi
}

# Sous-menu : choix du mode de verrouillage (modifie PASSWORD_PROTECT)
cfg_set_protect() {
    local _idx=0
    case "$PASSWORD_PROTECT" in
        none)    _idx=0 ;; onion)   _idx=1 ;;
        telmios) _idx=2 ;; both)    _idx=3 ;;
    esac

    show_menu "config_protect_${_idx}"
    > "$KEY_FILE"

    while true; do
        local _raw _k
        _raw=$(_wait_cfg_key 1) || continue
        _k=$(_norm_key "$_raw")
        case "$_k" in
            $KEY_LEFT)
                _idx=$(( (_idx-1+4) % 4 ))
                show_menu "config_protect_${_idx}"
                vibrate "$VIBRATION_SELECT" ;;
            $KEY_RIGHT)
                _idx=$(( (_idx+1) % 4 ))
                show_menu "config_protect_${_idx}"
                vibrate "$VIBRATION_SELECT" ;;
            $KEY_A)
                case $_idx in
                    0) PASSWORD_PROTECT="none"    ;;
                    1) PASSWORD_PROTECT="onion"   ;;
                    2) PASSWORD_PROTECT="telmios" ;;
                    3) PASSWORD_PROTECT="both"    ;;
                esac
                vibrate "$VIBRATION_CONFIRM"
                log "Config: protect=$PASSWORD_PROTECT"; return ;;
            $KEY_SELECT)  return ;;
        esac
    done
}

# Sous-menu : intensite des vibrations (modifie VIBRATION_POWER/SELECT/CONFIRM)
cfg_set_vibration() {
    local _idx=2
    if [ "$VIBRATION_POWER" -eq 0 ] 2>/dev/null; then
        _idx=0
    elif [ "$VIBRATION_POWER" -le 20 ] 2>/dev/null; then
        _idx=1
    elif [ "$VIBRATION_POWER" -le 35 ] 2>/dev/null; then
        _idx=2
    else
        _idx=3
    fi

    local _op="$VIBRATION_POWER" _os="$VIBRATION_SELECT" _oc="$VIBRATION_CONFIRM"

    show_menu "config_vib_${_idx}"
    > "$KEY_FILE"

    while true; do
        local _raw _k
        _raw=$(_wait_cfg_key 1) || continue
        _k=$(_norm_key "$_raw")
        case "$_k" in
            $KEY_LEFT)
                _idx=$(( (_idx-1+4) % 4 ))
                show_menu "config_vib_${_idx}"
                _apply_vib_preset $_idx
                [ "$VIBRATION_POWER" -gt 0 ] && vibrate "$VIBRATION_SELECT" ;;
            $KEY_RIGHT)
                _idx=$(( (_idx+1) % 4 ))
                show_menu "config_vib_${_idx}"
                _apply_vib_preset $_idx
                [ "$VIBRATION_POWER" -gt 0 ] && vibrate "$VIBRATION_SELECT" ;;
            $KEY_A)
                _apply_vib_preset $_idx
                [ "$VIBRATION_POWER" -gt 0 ] && vibrate "$VIBRATION_CONFIRM"
                log "Config: vib preset=$_idx power=$VIBRATION_POWER"; return ;;
            $KEY_SELECT)
                VIBRATION_POWER="$_op"; VIBRATION_SELECT="$_os"; VIBRATION_CONFIRM="$_oc"
                return ;;
        esac
    done
}

# Saisie d'une nouvelle sequence de boutons
# $1 : nom de l'image a afficher
# Ecrit le resultat dans NEW_CFG_SEQUENCE (noms boutons)
# Retourne 0 si valide, 1 si annule/vide
cfg_enter_sequence() {
    show_menu "$1"
    > "$KEY_FILE"
    NEW_CFG_SEQUENCE=""

    local _codes="" _count=0

    while [ $_count -lt 8 ]; do
        local _raw _k
        _raw=$(_wait_cfg_key 1) || continue
        _k=$(_norm_key "$_raw")
        case "$_k" in
            $KEY_SELECT)  return 1 ;;
            $KEY_A)       break    ;;
            $KEY_UP|$KEY_DOWN|$KEY_LEFT|$KEY_RIGHT|$KEY_L1|$KEY_R1|$KEY_X|$KEY_Y|$KEY_SELECT|$KEY_START)
                _codes="$_codes $_k"
                _count=$((_count+1))
                vibrate 25 ;;
        esac
    done

    [ $_count -eq 0 ] && return 1
    NEW_CFG_SEQUENCE=$(_codes_to_names $_codes)
    log "New sequence entered: '$NEW_CFG_SEQUENCE' (${_count} boutons)"
    return 0
}

# Menu de configuration principal (6 items)
run_config_menu() {
    log "=== Config menu ==="
    local _item=0 _max=6 _modified=0

    show_menu "config_main_${_item}"
    > "$KEY_FILE"

    while true; do
        local _raw _k
        _raw=$(_wait_cfg_key 1) || continue
        _k=$(_norm_key "$_raw")

        case "$_k" in
            $KEY_UP)
                _item=$(( (_item-1+_max) % _max ))
                show_menu "config_main_${_item}"
                vibrate "$VIBRATION_SELECT" ;;
            $KEY_DOWN)
                _item=$(( (_item+1) % _max ))
                show_menu "config_main_${_item}"
                vibrate "$VIBRATION_SELECT" ;;
            $KEY_A)
                case $_item in
                    0)  cfg_set_protect
                        _modified=1 ;;
                    1)  if cfg_enter_sequence "config_pw_entry" && [ -n "$NEW_CFG_SEQUENCE" ]; then
                            PASSWORD_SEQUENCE="$NEW_CFG_SEQUENCE"
                            _modified=1
                            vibrate "$VIBRATION_CONFIRM"
                            log "Config: PASSWORD_SEQUENCE='$PASSWORD_SEQUENCE'"
                        fi ;;
                    2)  if cfg_enter_sequence "config_cfg_entry" && [ -n "$NEW_CFG_SEQUENCE" ]; then
                            CONFIG_SEQUENCE="$NEW_CFG_SEQUENCE"
                            _modified=1
                            vibrate "$VIBRATION_CONFIRM"
                            log "Config: CONFIG_SEQUENCE='$CONFIG_SEQUENCE'"
                        fi ;;
                    3)  cfg_set_vibration
                        _modified=1 ;;
                    4)  # Sauvegarder et quitter
                        do_save_config
                        show_menu "config_saved"
                        sleep 2
                        log "Config: sauvegarde et sortie"
                        return ;;
                    5)  # Quitter sans sauvegarder
                        [ "$_modified" -eq 1 ] && _reload_config
                        log "Config: sortie sans sauvegarde"
                        return ;;
                esac
                show_menu "config_main_${_item}" ;;
            $KEY_SELECT)
                [ "$_modified" -eq 1 ] && _reload_config
                log "Config: SELECT - sortie sans sauvegarde"
                return ;;
        esac
    done
}

# Point d'entree : verif code puis menu config
enter_config_mode() {
    > "$KEY_FILE"
    if check_config_access; then
        run_config_menu
    else
        log "Config: acces refuse (mauvais code)"
    fi
    show_menu "$SELECTION"
    > "$KEY_FILE"
    log "Config mode termine"
}

# ---- Choix initial ----
SELECTION="onion"
[ -f "$CHOICE_FILE" ] && {
    _s=$(cat "$CHOICE_FILE")
    case "$_s" in onion|telmios) SELECTION="$_s" ;; esac
}
log "selection=$SELECTION"

# =============================================================
#  MODE AUTOBOOT (declenche par le plugin SwitchToTelmiOS)
#  Si /mnt/SDCARD/.autoboot existe, le menu est ignore et
#  l'OS dans .bootchoice est lance instantanement.
# =============================================================
AUTOBOOT_FILE=/mnt/SDCARD/.autoboot
AUTOBOOT=0
if [ -f "$AUTOBOOT_FILE" ]; then
    rm -f "$AUTOBOOT_FILE" 2>/dev/null
    sync
    log "AUTOBOOT: skip menu -> $SELECTION"
    AUTOBOOT=1
    CONFIRM_METHOD="autoboot"
fi

# ---- show_menu : ecriture directe sur /dev/fb0 (SANS SDL) ----
# Les fichiers .raw sont des images BGRA 640x480x4 ou 752x560x4 selon le modele.
# Nom : bootmenu_<name>_<LANG>[_flip].raw  (fallback progressif sans suffix)
show_menu() {
    local name="$1"
    local img_lang="$sysdir/res/bootmenu_${name}_${LANG}${RES_SUFFIX}.raw"
    local img_default="$sysdir/res/bootmenu_${name}${RES_SUFFIX}.raw"
    local img_lang_base="$sysdir/res/bootmenu_${name}_${LANG}.raw"
    local img_default_base="$sysdir/res/bootmenu_${name}.raw"
    if [ -f "$img_lang" ]; then
        dd if="$img_lang" of=/dev/fb0 bs=4096 2>/dev/null && sync
        log "show_menu $name [$LANG]${RES_SUFFIX}: OK"
    elif [ -f "$img_default" ]; then
        dd if="$img_default" of=/dev/fb0 bs=4096 2>/dev/null && sync
        log "show_menu $name [fallback]${RES_SUFFIX}: OK"
    elif [ -f "$img_lang_base" ]; then
        dd if="$img_lang_base" of=/dev/fb0 bs=4096 2>/dev/null && sync
        log "show_menu $name [$LANG] (no-flip fallback): OK"
    elif [ -f "$img_default_base" ]; then
        dd if="$img_default_base" of=/dev/fb0 bs=4096 2>/dev/null && sync
        log "show_menu $name (bare fallback): OK"
    else
        log "show_menu $name: MISSING ($img_lang)"
    fi
}

log "fb0 bits=$(cat /sys/class/graphics/fb0/bits_per_pixel 2>/dev/null)"

# ---- Detecter resolution framebuffer (Miyoo MINI Flip = 752x560) ----
_fb_vsize=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "640,480")
FB_W=$(echo "$_fb_vsize" | cut -d',' -f1)
FB_H=$(echo "$_fb_vsize" | cut -d',' -f2)
if [ "$FB_W" = "752" ] && [ "$FB_H" = "560" ]; then
    RES_SUFFIX="_flip"
    log "Miyoo Mini Flip detecte (${FB_W}x${FB_H}) -> images _flip"
else
    RES_SUFFIX=""
    log "Resolution FB: ${FB_W}x${FB_H} -> images standard"
fi

if [ "$AUTOBOOT" = "0" ]; then

# ---- Attendre que le backlight soit pret (PWM peut prendre jusqu'a 2s) ----
sleep 1.5

# ---- Afficher menu initial ----
show_menu "$SELECTION"
# Second affichage 0.5s plus tard au cas ou le backlight finit de s'initialiser
sleep 0.5
show_menu "$SELECTION"

# ---- Demarrer lecteurs de touches ----
log "Input devices:"
for d in /dev/input/event*; do
    [ -c "$d" ] && log "  found: $d"
done

rm -f "$KEY_FILE"
_start_readers "$KEY_FILE" "raw"
READER_PIDS="$_STARTED_PIDS"

# ---- Boucle menu (60s timeout) ----
TIMEOUT=600
COUNTER=0
CONFIRM_METHOD="timeout"

while [ $COUNTER -lt $TIMEOUT ]; do
    if [ -s "$KEY_FILE" ]; then
        KEY=$(tail -1 "$KEY_FILE" 2>/dev/null)
        > "$KEY_FILE"
        log "Processing key=$KEY"
        PREV="$SELECTION"

        case "$KEY" in
            $KEY_LEFT|$KEY_L1) SELECTION="onion" ;;
            $KEY_RIGHT|$KEY_R1) SELECTION="telmios" ;;
            $KEY_A|57|97|305|$KEY_START)
                # Verifier si protection active pour cet OS
                _need_pw=0
                case "$PASSWORD_PROTECT" in
                    both)                                    _need_pw=1 ;;
                    onion)   [ "$SELECTION" = "onion"   ] && _need_pw=1 ;;
                    telmios) [ "$SELECTION" = "telmios" ] && _need_pw=1 ;;
                esac

                if [ "$_need_pw" = "0" ]; then
                    CONFIRM_METHOD="confirm"
                    log "Confirm: $SELECTION"; break
                fi

                log "Password requis pour $SELECTION"

                # Suspendre lecteurs menu
                _stop_readers "$READER_PIDS"
                > "$KEY_FILE"

                # Afficher ecran verrouille
                show_menu "locked_${SELECTION}"

                # Construire sequence attendue
                _expected=$(_seq_to_codes $PASSWORD_SEQUENCE)
                _expected=$(echo $_expected)
                _seq_len=$(echo "$_expected" | wc -w)

                # Demarrer lecteurs password (fichier separe, normalisation pw)
                PW_KEY=/tmp/dualboot_pwkey
                _start_readers "$PW_KEY" "pw"
                PW_PIDS="$_STARTED_PIDS"

                # Attendre la sequence (30s max)
                _pressed=""
                _pcount=0
                _pw_cancel=0
                _pw_t=0
                while [ $_pw_t -lt 300 ] && [ $_pcount -lt $_seq_len ]; do
                    if [ -s "$PW_KEY" ]; then
                        _k=$(tail -1 "$PW_KEY" 2>/dev/null)
                        > "$PW_KEY"
                        # SELECT = annuler
                        if [ "$_k" = "$KEY_SELECT" ]; then
                            _pw_cancel=1; break
                        fi
                        _pressed="$_pressed $_k"
                        _pcount=$((_pcount+1))
                        vibrate 25
                        log "PW: $_pcount/$_seq_len key=$_k"
                    fi
                    sleep 0.1
                    _pw_t=$((_pw_t+1))
                done

                # Arreter lecteurs password
                _stop_readers "$PW_PIDS"
                rm -f "$PW_KEY"

                _pressed=$(echo $_pressed)
                log "PW: recu='$_pressed' attendu='$_expected' cancel=$_pw_cancel"

                if [ "$_pw_cancel" = "0" ] && [ "$_seq_len" -gt 0 ] && [ "$_pressed" = "$_expected" ]; then
                    log "Password OK - Confirm $SELECTION"
                    vibrate 150
                    CONFIRM_METHOD="confirm"
                    break
                else
                    log "Password echec/annule - retour menu"
                    vibrate 200; sleep 0.15; vibrate 200
                    show_menu "$SELECTION"
                    # Redemarrer lecteurs menu
                    _start_readers "$KEY_FILE" "raw"
                    READER_PIDS="$_STARTED_PIDS"
                    log "Lecteurs menu redemarres (PW echec)"
                fi
                ;;
            $KEY_X)
                log "X: mode config"
                enter_config_mode
                COUNTER=0 ;;
        esac

        if [ "$SELECTION" != "$PREV" ]; then
            log "Switch $PREV -> $SELECTION"
            vibrate "$VIBRATION_SELECT"
            show_menu "$SELECTION"
            COUNTER=0
        fi
    fi
    sleep 0.1
    COUNTER=$((COUNTER+1))
done

log "Loop done. COUNTER=$COUNTER method=$CONFIRM_METHOD selection=$SELECTION"

# ---- Cleanup readers ----
_stop_readers "$READER_PIDS"
rm -f "$KEY_FILE"

fi  # fin bloc AUTOBOOT=0 (menu interactif)

# ---- Sauvegarder le choix (sync pour eviter corruption) ----
echo "$SELECTION" > "$CHOICE_FILE"
sync
log "Saved: $SELECTION"

[ "$SELECTION" = "telmios" ] && OS_DIR="$TELMIOS_DIR" || OS_DIR="$ONION_DIR"

# ---- Rotation log OS ----
mkdir -p "$OS_DIR/.tmp_update/logs" 2>/dev/null
> "$OS_DIR/.tmp_update/logs/dualboot.log" 2>/dev/null

# ---- Vibration de confirmation ----
vibrate "$VIBRATION_CONFIRM"
sleep 0.1

# ---- Bind mounts ----
umount $miyoodir 2>/dev/null
mount --bind "$OS_DIR/.tmp_update" /mnt/SDCARD/.tmp_update && \
    log "mount .tmp_update OK" || log "mount .tmp_update FAILED"
mount --bind "$OS_DIR/miyoo" $miyoodir && \
    log "mount miyoo OK" || log "mount miyoo FAILED"
[ "$SELECTION" = "telmios" ] && [ -d "$OS_DIR/miyoo354" ] && \
    mount --bind "$OS_DIR/miyoo354" /mnt/SDCARD/miyoo354 2>/dev/null

for datadir in Saves Roms BIOS App Emu RetroArch Music Stories Themes Icons Media Screenshots; do
    [ -d "$OS_DIR/$datadir" ] && {
        mkdir -p /mnt/SDCARD/$datadir 2>/dev/null
        mount --bind "$OS_DIR/$datadir" /mnt/SDCARD/$datadir 2>/dev/null
        log "Mounted $datadir"
    }
done

rm -f /tmp/is_booting

# ---- Pre-monter le binaire MainUI pour Onion ----
if [ "$SELECTION" = "onion" ]; then
    _mainui_src="/mnt/SDCARD/.tmp_update/bin/MainUI-${DEVICE_ID}-clean"
    _mainui_tgt="/mnt/SDCARD/miyoo/app/MainUI"
    if [ -f "$_mainui_src" ] && [ -f "$_mainui_tgt" ]; then
        mount --bind "$_mainui_src" "$_mainui_tgt" 2>/dev/null && \
            log "Pre-mount MainUI-${DEVICE_ID}-clean OK" || \
            log "Pre-mount MainUI FAILED (mount_main_ui tentera)"
    else
        log "Pre-mount: src=$_mainui_src ou tgt=$_mainui_tgt manquant"
    fi
fi

# ---- Installation premiere de OnionOS si necessaire ----
if [ "$SELECTION" = "onion" ] && [ ! -f "/mnt/SDCARD/.tmp_update/runtime.sh" ] && [ -f "/mnt/SDCARD/.tmp_update/install.sh" ]; then
    log "OnionOS: runtime.sh absent, lancement install.sh..."
    export LD_LIBRARY_PATH="/lib:/config/lib:$miyoodir/lib:/mnt/SDCARD/.tmp_update/lib"
    export PATH="/mnt/SDCARD/.tmp_update/bin:$sysdir/bin:$PATH"
    unset SDL_VIDEODRIVER
    unset SDL_AUDIODRIVER
    unset EGL_VIDEODRIVER
    cd /mnt/SDCARD/.tmp_update
    exec ./install.sh
fi

# ---- Lancer l'OS cible ----
TARGET="/mnt/SDCARD/.tmp_update/runtime.sh"
if [ ! -f "$TARGET" ]; then
    log "ERREUR: $TARGET introuvable! Reboot dans 5s..."
    sleep 5
    reboot
else
    # Ne pas forcer SDL_VIDEODRIVER : SDL auto-detecte mmiyoo correctement
    unset SDL_VIDEODRIVER
    unset SDL_AUDIODRIVER
    unset EGL_VIDEODRIVER
    log "Exec $SELECTION: $TARGET"
    exec "$TARGET" > "$OS_DIR/.tmp_update/logs/os_debug.log" 2>&1
    # Si exec echoue (fichier non executable, etc.), reboot de secours
    log "ERREUR: exec echoue! Reboot dans 5s..."
    sleep 5
    reboot
fi
