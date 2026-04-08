#!/bin/sh
# =============================================================
#  DUAL BOOT SELECTOR - Miyoo Mini / Mini Plus
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

# ---- Charger configuration ----
LANG="FR"
VIBRATION_POWER=25
VIBRATION_SELECT=60
VIBRATION_CONFIRM=200
PASSWORD_PROTECT="none"
PASSWORD_SEQUENCE=""

CONFIG="$sysdir/config/dualboot.cfg"
if [ -f "$CONFIG" ]; then
    . "$CONFIG"
    log "Config: LANG=$LANG VP=$VIBRATION_POWER VS=$VIBRATION_SELECT VC=$VIBRATION_CONFIRM PP=$PASSWORD_PROTECT"
else
    log "Config manquant ($CONFIG) - valeurs par defaut"
fi

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
    local effective=$(awk "BEGIN { v=int($ms * $VIBRATION_POWER / 100); print (v<5?5:v) }" 2>/dev/null)
    echo 0 > /sys/class/gpio/gpio48/value 2>/dev/null
    sleep $(awk "BEGIN { printf \"%.3f\", $effective / 1000 }" 2>/dev/null)
    echo 1 > /sys/class/gpio/gpio48/value 2>/dev/null
}

# ---- Choix initial ----
SELECTION="onion"
[ -f "$CHOICE_FILE" ] && {
    _s=$(cat "$CHOICE_FILE")
    case "$_s" in onion|telmios) SELECTION="$_s" ;; esac
}
log "selection=$SELECTION"

# ---- show_menu : ecriture directe sur /dev/fb0 (SANS SDL) ----
# Les fichiers .raw sont des images BGRA 640x480x4 = 1228800 bytes
# Nom : bootmenu_<name>_<LANG>.raw  (fallback : bootmenu_<name>.raw)
show_menu() {
    local name="$1"
    local img_lang="$sysdir/res/bootmenu_${name}_${LANG}.raw"
    local img_default="$sysdir/res/bootmenu_${name}.raw"
    if [ -f "$img_lang" ]; then
        dd if="$img_lang" of=/dev/fb0 bs=4096 2>/dev/null && sync
        log "show_menu $name [$LANG]: OK"
    elif [ -f "$img_default" ]; then
        dd if="$img_default" of=/dev/fb0 bs=4096 2>/dev/null && sync
        log "show_menu $name [fallback]: OK"
    else
        log "show_menu $name: MISSING ($img_lang)"
    fi
}

log "fb0 bits=$(cat /sys/class/graphics/fb0/bits_per_pixel 2>/dev/null)"

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

KEY_FILE=/tmp/dualboot_key
rm -f "$KEY_FILE"

READER_PIDS=""
for evt_dev in /dev/input/event0 /dev/input/event1 /dev/input/event2 /dev/input/event3; do
    if [ -c "$evt_dev" ]; then
        log "Reading from $evt_dev"
        (
            while true; do
                evt=$(dd if="$evt_dev" bs=16 count=1 2>/dev/null | od -An -tu2 -v)
                set -- $evt
                if [ $# -ge 7 ] && [ "$5" = "1" ] && [ "$7" = "1" ]; then
                    echo "$6" >> "$KEY_FILE"
                    log "KEY=$6 from $evt_dev"
                fi
            done
        ) &
        READER_PIDS="$READER_PIDS $!"
    fi
done
log "Input readers started (PIDs:$READER_PIDS). Waiting for keys..."

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
            105|310) SELECTION="onion" ;;          # LEFT / L1
            106|311) SELECTION="telmios" ;;        # RIGHT / R1
            28|57|97|305|315)                      # A/ENTER/SPACE/RCTRL/START
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
                for _rp in $READER_PIDS; do kill "$_rp" 2>/dev/null; done
                sleep 0.2; killall dd 2>/dev/null; killall od 2>/dev/null; sleep 0.1
                > "$KEY_FILE"

                # Afficher ecran verrouille
                show_menu "locked_${SELECTION}"

                # Construire sequence attendue (noms boutons -> codes)
                _expected=""
                for _btn in $PASSWORD_SEQUENCE; do
                    case "$_btn" in
                        UP)     _expected="$_expected 103" ;;
                        DOWN)   _expected="$_expected 108" ;;
                        LEFT)   _expected="$_expected 105" ;;
                        RIGHT)  _expected="$_expected 106" ;;
                        A)      _expected="$_expected 28"  ;;
                        B)      _expected="$_expected 14"  ;;
                        X)      _expected="$_expected 33"  ;;
                        Y)      _expected="$_expected 21"  ;;
                        L|L1)   _expected="$_expected 310" ;;
                        R|R1)   _expected="$_expected 311" ;;
                        START)  _expected="$_expected 315" ;;
                        SELECT) _expected="$_expected 314" ;;
                    esac
                done
                _expected=$(echo $_expected)
                _seq_len=$(echo "$_expected" | wc -w)

                # Demarrer lecteurs password (fichier separe)
                PW_KEY=/tmp/dualboot_pwkey
                rm -f "$PW_KEY"
                PW_PIDS=""
                for _ev in /dev/input/event0 /dev/input/event1 /dev/input/event2 /dev/input/event3; do
                    if [ -c "$_ev" ]; then
                        (
                            while true; do
                                evt=$(dd if="$_ev" bs=16 count=1 2>/dev/null | od -An -tu2 -v)
                                set -- $evt
                                if [ $# -ge 7 ] && [ "$5" = "1" ] && [ "$7" = "1" ]; then
                                    # Normaliser les keycodes (variantes -> code canonique)
                                    _nk="$6"
                                    case "$_nk" in
                                        57|97|305|315) _nk=28  ;;  # A (toutes variantes)
                                        1|304)         _nk=14  ;;  # B (toutes variantes)
                                        310)           _nk=105 ;;  # L1 -> LEFT
                                        311)           _nk=106 ;;  # R1 -> RIGHT
                                    esac
                                    echo "$_nk" >> "$PW_KEY"
                                fi
                            done
                        ) &
                        PW_PIDS="$PW_PIDS $!"
                    fi
                done

                # Attendre la sequence (30s max)
                _pressed=""
                _pcount=0
                _pw_cancel=0
                _pw_t=0
                while [ $_pw_t -lt 300 ] && [ $_pcount -lt $_seq_len ]; do
                    if [ -s "$PW_KEY" ]; then
                        _k=$(tail -1 "$PW_KEY" 2>/dev/null)
                        > "$PW_KEY"
                        # 14 = B normalise = annuler
                        if [ "$_k" = "14" ]; then
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
                for _p in $PW_PIDS; do kill "$_p" 2>/dev/null; done
                sleep 0.2; killall dd 2>/dev/null; killall od 2>/dev/null; sleep 0.1
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
                    READER_PIDS=""
                    for evt_dev in /dev/input/event0 /dev/input/event1 /dev/input/event2 /dev/input/event3; do
                        if [ -c "$evt_dev" ]; then
                            (
                                while true; do
                                    evt=$(dd if="$evt_dev" bs=16 count=1 2>/dev/null | od -An -tu2 -v)
                                    set -- $evt
                                    if [ $# -ge 7 ] && [ "$5" = "1" ] && [ "$7" = "1" ]; then
                                        echo "$6" >> "$KEY_FILE"
                                        log "KEY=$6 from $evt_dev"
                                    fi
                                done
                            ) &
                            READER_PIDS="$READER_PIDS $!"
                        fi
                    done
                    log "Lecteurs menu redemarres (PW echec)"
                fi
                ;;
            14|1|304)                              # B/BACKSPACE/ESC
                _s=$(cat "$CHOICE_FILE" 2>/dev/null || echo "onion")
                case "$_s" in onion|telmios) SELECTION="$_s" ;; *) SELECTION="onion" ;; esac
                CONFIRM_METHOD="last"
                log "B: last=$SELECTION"; break
                ;;
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
for _rpid in $READER_PIDS; do kill "$_rpid" 2>/dev/null; done
sleep 0.3
killall dd 2>/dev/null
killall od 2>/dev/null
sleep 0.1
rm -f "$KEY_FILE"

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
    log "ERREUR: exec echoue! Reboot dans 5s..."
    sleep 5
    reboot
fi
