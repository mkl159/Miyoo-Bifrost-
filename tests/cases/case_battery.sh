#!/bin/sh
# Tests de la jauge de batterie.
#
# Source du niveau, identique a celle qu'utilise batmon dans les deux OS :
#   Mini Plus -> /customer/app/axp_test rend
#                {"battery":75, "voltage":4100, "charging":0}
#   Mini      -> lecture via /dev/sar et un ioctl, hors de portee du shell,
#                le niveau reste donc inconnu.
. "$(dirname "$0")/../helpers.sh"

LIB=/tmp/bifrost_test_bat_lib.sh
extract_functions "_is_num _json_int _bat_bucket" "$LIB"
. "$LIB"

echo "  -- lecture du JSON rendu par axp_test --"
J='{"battery":75, "voltage":4100, "charging":0}'
eq "niveau"          "75"   "$(_json_int "$J" battery)"
eq "etat de charge"  "0"    "$(_json_int "$J" charging)"
eq "tension"         "4100" "$(_json_int "$J" voltage)"

JC='{"battery":8, "voltage":3500, "charging":1}'
eq "niveau en charge"      "8" "$(_json_int "$JC" battery)"
eq "indicateur de charge"  "1" "$(_json_int "$JC" charging)"

echo "  -- sortie inattendue : aucun champ invente --"
eq "sortie vide"       "" "$(_json_int "" battery)"
eq "sortie non JSON"   "" "$(_json_int "erreur i2c" battery)"
eq "champ absent"      "" "$(_json_int '{"voltage":4100}' battery)"

echo "  -- paliers d'affichage --"
# Les bornes exactes comptent : c'est ce qui decide de l'image affichee.
eq "0 pourcent"    "0"   "$(_bat_bucket 0)"
eq "9 pourcent"    "0"   "$(_bat_bucket 9)"
eq "10 pourcent"   "25"  "$(_bat_bucket 10)"
eq "34 pourcent"   "25"  "$(_bat_bucket 34)"
eq "35 pourcent"   "50"  "$(_bat_bucket 35)"
eq "59 pourcent"   "50"  "$(_bat_bucket 59)"
eq "60 pourcent"   "75"  "$(_bat_bucket 60)"
eq "84 pourcent"   "75"  "$(_bat_bucket 84)"
eq "85 pourcent"   "100" "$(_bat_bucket 85)"
eq "100 pourcent"  "100" "$(_bat_bucket 100)"

echo "  -- valeurs aberrantes : tiret plutot qu'un chiffre faux --"
for bad in 101 999 "" abc "-5" "12.5"; do
    eq "valeur '$bad' rejetee" "unknown" "$(_bat_bucket "$bad")"
done

echo "  -- chaque palier a bien son image, dans les deux resolutions --"
RES="$(dirname "$RUNTIME")/res"
missing=0
for bucket in 0 25 50 75 100 unknown; do
    for chg in "" "_chg"; do
        for variant in "" "_flip"; do
            f="$RES/bootmenu_battery_${bucket}${chg}${variant}.raw"
            [ -f "$f" ] || { missing=$((missing + 1)); echo "    manquante : $(basename "$f")"; }
        done
    done
done
eq "bandeaux manquants" "0" "$missing"

echo "  -- taille des bandeaux : hauteur barre de titre + 6 lignes --"
# 640x480 -> 72 + 6 = 78 lignes ; 752x560 -> 84 + 6 = 90 lignes.
eq "bandeau 640x480" "199680" "$(wc -c < "$RES/bootmenu_battery_50.raw" | tr -d ' ')"
eq "bandeau 752x560" "270720" "$(wc -c < "$RES/bootmenu_battery_50_flip.raw" | tr -d ' ')"

rm -f "$LIB"
report "Jauge de batterie"
