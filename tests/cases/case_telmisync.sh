#!/bin/sh
# Tests de la validation Telmi-Sync executee a chaque demarrage.
#
# Contrat verifie, tire du code source de Telmi-Sync :
#   public/MainEvents/Helpers/InfFiles.js -> lit /autorun.inf et exige un
#     libelle "TelmiOS-vX.Y.Z" dont le numero majeur est superieur ou egal a 1
#   public/MainEvents/Helpers/TelmiOS.js  -> lit /Saves/.parameters et le
#     parse en JSON SANS verifier son existence : un fichier absent ou
#     corrompu fait echouer toute la detection de la carte.
. "$(dirname "$0")/../helpers.sh"

LIB=/tmp/bifrost_test_tsv_lib.sh
extract_functions "telmi_sync_validate" "$LIB"

CARD=/tmp/bifrost_test_card

# Reconstruit une carte Bifrost saine.
make_card() {
    rm -rf "$CARD"
    mkdir -p "$CARD/telmios/.tmp_update/telmiVersion" "$CARD/telmios/Saves" \
             "$CARD/Saves" "$CARD/Stories" "$CARD/Music"
    printf 'v1.10.3' > "$CARD/telmios/.tmp_update/telmiVersion/version.txt"
    printf '{"audioVolumeStartup":0.2,"screenBrightnessMax":0.6}' \
        > "$CARD/telmios/Saves/.parameters"
    cp "$CARD/telmios/Saves/.parameters" "$CARD/Saves/.parameters"
    printf '[autorun]\r\nicon  = .tmp_update/res/sdcard.ico\r\nlabel = TelmiOS-v1.10.3\r\n' \
        > "$CARD/autorun.inf"
}

# Execute la vraie fonction de runtime.sh sur la carte simulee.
validate() {
    SD_ROOT="$CARD" \
    TELMIOS_DIR="$CARD/telmios" \
    AUTORUN_FILE="$CARD/autorun.inf" \
    PARAMS_FILE="$CARD/Saves/.parameters" \
    sh -c '
        SD_ROOT="$1"; TELMIOS_DIR="$2"; AUTORUN_FILE="$3"; PARAMS_FILE="$4"
        log() { :; }
        sync() { :; }
        . "$5"
        telmi_sync_validate
    ' _ "$CARD" "$CARD/telmios" "$CARD/autorun.inf" "$CARD/Saves/.parameters" "$LIB"
}

# Reproduit la detection de Telmi-Sync : renvoie la version reconnue,
# ou une chaine d'erreur.
detect() {
    [ -f "$CARD/autorun.inf" ] || { echo "ECHEC:pas-de-autorun"; return; }
    _label=$(sed -n 's/^[[:space:]]*[Ll]abel[[:space:]]*=[[:space:]]*//p' \
             "$CARD/autorun.inf" | head -1 | tr -d '\r')
    case "$_label" in
        TelmiOS-v*) ;;
        *) echo "ECHEC:libelle-invalide"; return ;;
    esac
    _v=${_label##*-v}
    case "$_v" in
        [1-9]*.*.*) ;;
        *) echo "ECHEC:version-invalide"; return ;;
    esac
    [ -s "$CARD/Saves/.parameters" ] || { echo "ECHEC:parametres-absents"; return; }
    [ "$(head -c 1 "$CARD/Saves/.parameters")" = "{" ] || { echo "ECHEC:parametres-non-json"; return; }
    echo "$_v"
}

echo "  -- carte saine : reconnue, et aucune reecriture inutile --"
make_card
before=$(cat "$CARD/autorun.inf")
validate
eq "carte reconnue"        "1.10.3" "$(detect)"
eq "autorun.inf inchange"  "$before" "$(cat "$CARD/autorun.inf")"

echo "  -- .parameters absent : restaure --"
make_card; rm -f "$CARD/Saves/.parameters"
validate
eq "carte reconnue apres reparation" "1.10.3" "$(detect)"

echo "  -- .parameters corrompu : remplace --"
make_card; echo "ceci n'est pas du json" > "$CARD/Saves/.parameters"
validate
eq "carte reconnue apres reparation" "1.10.3" "$(detect)"

echo "  -- autorun.inf absent : recree --"
make_card; rm -f "$CARD/autorun.inf"
validate
eq "carte reconnue apres reparation" "1.10.3" "$(detect)"

echo "  -- TelmiOS mis a jour : le libelle suit --"
# Sans cela, Telmi-Sync proposerait une mise a jour de TelmiOS qui se
# decompresse a la racine et remplacerait le bootloader Bifrost.
make_card; printf 'v1.11.0' > "$CARD/telmios/.tmp_update/telmiVersion/version.txt"
validate
eq "libelle aligne sur la version installee" "1.11.0" "$(detect)"

echo "  -- dossiers de donnees effaces : recrees --"
make_card; rm -rf "$CARD/Stories" "$CARD/Music"
validate
ok_cmd test -d "$CARD/Stories"
ok_cmd test -d "$CARD/Music"

echo "  -- version indeterminee : libelle laisse intact --"
for bad in "" "bidon" "1.10" "1.10.3.4" "v1.2.3-beta"; do
    make_card
    printf '%s' "$bad" > "$CARD/telmios/.tmp_update/telmiVersion/version.txt"
    validate
    eq "libelle preserve pour version '$bad'" "1.10.3" "$(detect)"
done

echo "  -- carte en lecture seule : aucun plantage --"
make_card; rm -f "$CARD/Saves/.parameters"; chmod -w "$CARD/Saves" 2>/dev/null
ok_cmd validate
chmod +w "$CARD/Saves" 2>/dev/null

rm -rf "$CARD" "$LIB"
report "Validation Telmi-Sync au demarrage"
