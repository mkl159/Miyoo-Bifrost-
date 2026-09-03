#!/bin/sh
# Tests du chargement de dualboot.cfg.
. "$(dirname "$0")/../helpers.sh"

LIB=/tmp/bifrost_test_cfg_lib.sh
extract_functions "_set_defaults _is_num _is_valid_btn_seq _seq_contains _safe_read_cfg _apply_vib_preset _seq_count" "$LIB"
. "$LIB"

CFG=/tmp/bifrost_test.cfg

echo "  -- valeurs valides appliquees --"
cat > "$CFG" <<'CFGEOF'
# un commentaire
LANG=ES
VIBRATION_POWER=42
PASSWORD_PROTECT=both
PASSWORD_SEQUENCE="UP DOWN A"
CONFIG_SEQUENCE="LEFT RIGHT X"
BOOT_MODE=stealth_telmios
KONAMI_TIMEOUT=12
CFGEOF
_set_defaults; _safe_read_cfg "$CFG"
eq "langue"            "ES"              "$UI_LANG"
eq "puissance"         "42"              "$VIBRATION_POWER"
eq "protection"        "both"            "$PASSWORD_PROTECT"
eq "code"              "UP DOWN A"       "$PASSWORD_SEQUENCE"
eq "code admin"        "LEFT RIGHT X"    "$CONFIG_SEQUENCE"
eq "mode de demarrage" "stealth_telmios" "$BOOT_MODE"
eq "delai konami"      "12"              "$KONAMI_TIMEOUT"

echo "  -- valeurs invalides rejetees, defauts conserves --"
cat > "$CFG" <<'CFGEOF'
LANG=ZZ
VIBRATION_POWER=999
PASSWORD_PROTECT=; reboot
BOOT_MODE=stealth_evil
KONAMI_TIMEOUT=0
PASSWORD_SEQUENCE="UP $(reboot) DOWN"
CFGEOF
_set_defaults; _safe_read_cfg "$CFG"
eq "langue inconnue"        "FR"   "$UI_LANG"
eq "puissance hors bornes"  "25"   "$VIBRATION_POWER"
eq "protection injectee"    "none" "$PASSWORD_PROTECT"
eq "mode inconnu"           "menu" "$BOOT_MODE"
eq "delai hors bornes"      "5"    "$KONAMI_TIMEOUT"
eq "sequence injectee"      ""     "$PASSWORD_SEQUENCE"

echo "  -- boutons reserves refuses dans les sequences --"
# SELECT annule la saisie du mot de passe : l'accepter rendrait le code
# impossible a entrer, donc l'OS impossible a lancer.
printf 'PASSWORD_SEQUENCE="UP SELECT DOWN"\n' > "$CFG"
_set_defaults; _safe_read_cfg "$CFG"
eq "SELECT refuse dans le code" "" "$PASSWORD_SEQUENCE"

# A et START valident la saisie du code admin, SELECT l'annule.
for bad in A START SELECT; do
    printf 'CONFIG_SEQUENCE="UP %s"\n' "$bad" > "$CFG"
    _set_defaults; _safe_read_cfg "$CFG"
    eq "$bad refuse dans le code admin" "UP UP DOWN DOWN" "$CONFIG_SEQUENCE"
done

# Une sequence sans bouton reserve doit rester acceptee.
printf 'CONFIG_SEQUENCE="L1 R1 X Y"\n' > "$CFG"
_set_defaults; _safe_read_cfg "$CFG"
eq "sequence admin valide acceptee" "L1 R1 X Y" "$CONFIG_SEQUENCE"

echo "  -- annulation : retour complet aux defauts --"
# _safe_read_cfg n'ecrase que les cles presentes : sans remise a zero
# prealable, une cle absente laisserait la valeur modifiee dans le menu.
printf 'LANG=EN\n' > "$CFG"
PASSWORD_PROTECT="onion"; VIBRATION_POWER=99; BOOT_MODE="stealth_onion"
_set_defaults; _safe_read_cfg "$CFG"
eq "protection revenue au defaut" "none" "$PASSWORD_PROTECT"
eq "puissance revenue au defaut"  "25"   "$VIBRATION_POWER"
eq "mode revenu au defaut"        "menu" "$BOOT_MODE"
eq "cle presente appliquee"       "EN"   "$UI_LANG"

echo "  -- presets de vibration --"
_apply_vib_preset 0
eq "preset silencieux" "0-0-0"      "$VIBRATION_POWER-$VIBRATION_SELECT-$VIBRATION_CONFIRM"
_apply_vib_preset 3
eq "preset fort"       "50-100-200" "$VIBRATION_POWER-$VIBRATION_SELECT-$VIBRATION_CONFIRM"

echo "  -- validation des noms de boutons --"
ok_cmd _is_valid_btn_seq "UP DOWN A"
ko_cmd _is_valid_btn_seq "UP; rm -rf /"
ko_cmd _is_valid_btn_seq "UP FOO"
eq "comptage sequence vide"     "0" "$(_seq_count "")"
eq "comptage 5 boutons"         "5" "$(_seq_count "UP UP DOWN DOWN A")"
eq "comptage espaces multiples" "2" "$(_seq_count "  UP    DOWN  ")"

rm -f "$LIB" "$CFG"
report "Chargement de la configuration"
