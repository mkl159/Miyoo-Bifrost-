#!/bin/sh
# Verifie le jeu d'images embarquees sur la carte.
# Une image manquante ou d'une taille inattendue donne un ecran noir ou
# des couleurs decalees sur la console, sans message d'erreur.
. "$(dirname "$0")/../helpers.sh"

RES="$(dirname "$RUNTIME")/res"

# Ecrans attendus, dans chaque langue.
SCREENS="onion telmios locked_onion locked_telmios config_access config_saved
config_pw_entry config_cfg_entry config_konami_entry
config_main_0 config_main_1 config_main_2 config_main_3
config_main_4 config_main_5 config_main_6 config_main_7
config_protect_0 config_protect_1 config_protect_2 config_protect_3
config_vib_0 config_vib_1 config_vib_2 config_vib_3
config_bootmode_0 config_bootmode_1 config_bootmode_2"

SIZE_STD=1228800    # 640 x 480 x 4 octets (Mini et Mini Plus)
SIZE_FLIP=1684480   # 752 x 560 x 4 octets (Mini Flip)

echo "  -- presence et taille de chaque image --"
missing=0
badsize=0
count=0
for lang in FR EN ES; do
    for screen in $SCREENS; do
        for variant in "" "_flip"; do
            f="$RES/bootmenu_${screen}_${lang}${variant}.raw"
            count=$((count + 1))
            if [ ! -f "$f" ]; then
                missing=$((missing + 1))
                [ "$missing" -le 5 ] && echo "    manquante : $(basename "$f")"
                continue
            fi
            [ -z "$variant" ] && expected=$SIZE_STD || expected=$SIZE_FLIP
            actual=$(wc -c < "$f" | tr -d ' ')
            if [ "$actual" != "$expected" ]; then
                badsize=$((badsize + 1))
                [ "$badsize" -le 5 ] && echo "    taille incorrecte : $(basename "$f") ($actual au lieu de $expected)"
            fi
        done
    done
done
eq "images attendues"          "168" "$count"
eq "images manquantes"         "0"   "$missing"
eq "images de taille incorrecte" "0" "$badsize"

echo "  -- ecrans d'erreur --"
# Sans eux, un systeme introuvable donne un ecran noir puis un redemarrage.
err_missing=0
for lang in FR EN ES; do
    for variant in "" "_flip"; do
        for os_name in onion telmios; do
            f="$RES/bootmenu_error_missing_${os_name}_${lang}${variant}.raw"
            [ -f "$f" ] || { err_missing=$((err_missing + 1)); echo "    manquante : $(basename "$f")"; }
        done
        f="$RES/bootmenu_error_mount_${lang}${variant}.raw"
        [ -f "$f" ] || { err_missing=$((err_missing + 1)); echo "    manquante : $(basename "$f")"; }
    done
done
eq "ecrans d'erreur manquants" "0" "$err_missing"

echo "  -- aucun fichier RAW orphelin --"
# Une image presente mais jamais affichee est du poids mort sur la carte.
#   168 ecrans de menu + 18 ecrans d'erreur + 24 bandeaux de batterie
total=$(find "$RES" -name '*.raw' | wc -l | tr -d ' ')
eq "nombre total de fichiers RAW" "210" "$total"

echo "  -- aucune image uniformement vide --"
# Un rendu rate (police absente, erreur de dessin) produit typiquement une
# image d'une seule couleur : on echantillonne quelques octets.
blank=0
for f in "$RES"/bootmenu_onion_FR.raw "$RES"/bootmenu_config_main_0_FR.raw \
         "$RES"/bootmenu_locked_telmios_EN.raw "$RES"/bootmenu_config_saved_ES_flip.raw; do
    [ -f "$f" ] || continue
    distinct=$(od -An -tu1 -N 40000 "$f" | tr ' ' '\n' | grep -v '^$' | sort -u | wc -l)
    [ "$distinct" -lt 4 ] && { blank=$((blank + 1)); echo "    image quasi uniforme : $(basename "$f")"; }
done
eq "images vides" "0" "$blank"

report "Images du menu"
