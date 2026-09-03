#!/bin/sh
# Tests des conversions de boutons et de la reconnaissance du Code Konami.
. "$(dirname "$0")/../helpers.sh"

LIB=/tmp/bifrost_test_seq_lib.sh
extract_functions "_btn_to_code _code_to_btn _seq_to_codes_norm _codes_to_names _norm_key _norm_key_pw" "$LIB"
. "$LIB"

echo "  -- conversions noms / keycodes --"
eq "noms vers codes" "103 103 108 108 28"      "$(_seq_to_codes_norm menu UP UP DOWN DOWN A)"
eq "codes vers noms" "UP DOWN LEFT RIGHT B"    "$(_codes_to_names 103 108 105 106 14)"

echo "  -- normalisation des variantes materielles --"
# Le pilote remonte plusieurs codes pour le bouton A selon le modele.
for v in 57 97 305 315; do
    eq "variante $v vers A" "28" "$(_norm_key $v)"
done
eq "L1 inchange en mode menu"        "310" "$(_norm_key 310)"
eq "L1 vers LEFT en mode password"   "105" "$(_norm_key_pw 310)"
eq "R1 vers RIGHT en mode password"  "106" "$(_norm_key_pw 311)"

echo "  -- la sequence attendue subit la meme normalisation que la lecture --"
# Sans cela, un bouton normalise a la lecture ne pourrait jamais
# correspondre a ce qui est attendu : la sequence serait insaisissable
# et l'OS impossible a lancer.
eq "START attendu devient A"          "103 28"  "$(_seq_to_codes_norm menu UP START)"
eq "L1 attendu devient LEFT (mot de passe)"  "105 105" "$(_seq_to_codes_norm pw L1 LEFT)"
eq "R1 attendu devient RIGHT (mot de passe)" "106 106" "$(_seq_to_codes_norm pw R1 RIGHT)"
eq "L1 attendu reste L1 (menu)"       "310"     "$(_seq_to_codes_norm menu L1)"
eq "bouton inconnu ignore"            "103"     "$(_seq_to_codes_norm menu UP FOO)"

echo "  -- reconnaissance du Code Konami (fenetre glissante) --"
# Rejoue la logique de correspondance du mode furtif.
konami_try() {
    _expected="$1"; _input="$2"
    _konami=$(_seq_to_codes_norm menu $_expected); _konami=$(echo $_konami)
    _klen=$(echo "$_konami" | wc -w)
    _buffer=""; _bcount=0; _ok=0
    for _btn in $_input; do
        case "$_btn" in
            ''|*[!0-9]*) _c=$(_btn_to_code "$_btn") ;;
            *)           _c="$_btn" ;;
        esac
        [ -n "$_c" ] || continue
        _kn=$(_norm_key "$_c")
        _buffer="$_buffer $_kn"
        _bcount=$((_bcount + 1))
        if [ $_bcount -gt $_klen ]; then
            _buffer=$(echo "$_buffer" | awk -v n=$_klen '{ for (i = NF-n+1; i <= NF; i++) printf "%s ", $i }')
        fi
        [ "$(echo $_buffer)" = "$_konami" ] && { _ok=1; break; }
    done
    echo "$_ok"
}

K="UP UP DOWN DOWN LEFT RIGHT LEFT RIGHT B"
eq "sequence exacte"                 1 "$(konami_try "$K" "$K")"
eq "sequence incomplete"             0 "$(konami_try "$K" "UP UP DOWN DOWN LEFT RIGHT")"
eq "mauvaise sequence"               0 "$(konami_try "$K" "A A A A A A A A A")"
eq "bruit avant la sequence"         1 "$(konami_try "$K" "A B X Y $K")"
eq "bruit apres la sequence"         1 "$(konami_try "$K" "$K A B")"
eq "faux depart puis reprise"        1 "$(konami_try "$K" "UP DOWN $K")"
eq "sequence courte de 2 boutons"    1 "$(konami_try "UP A" "X Y UP A")"
eq "variante materielle acceptee"    1 "$(konami_try "UP A" "X Y UP 97")"

rm -f "$LIB"
report "Sequences et Code Konami"
