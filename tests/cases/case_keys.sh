#!/bin/sh
# Tests de la file d'attente des touches.
. "$(dirname "$0")/../helpers.sh"

LIB=/tmp/bifrost_test_keys_lib.sh
extract_functions "_reset_keys _drain_keys _pop_key _wait_key" "$LIB"
. "$LIB"

SRC=/tmp/bifrost_test_key
_KEY_SRC="$SRC"

reset() { rm -f "$SRC" "$SRC.rd"; _KQ=""; _KEY=""; }

echo "  -- aucun appui perdu sur une salve rapide --"
reset
# Six boutons arrivent dans le meme cycle de lecture : l'ancienne
# implementation (tail -1 puis troncature) n'en gardait qu'un seul.
printf '103\n103\n108\n108\n105\n106\n' > "$SRC"
got=""
while _wait_key 2; do got="$got $_KEY"; done
eq "les 6 appuis sont restitues dans l'ordre" "103 103 108 108 105 106" "$(echo $got)"

echo "  -- appuis arrivant en plusieurs salves --"
reset
printf '28\n' > "$SRC";      _wait_key 2; a="$_KEY"
printf '14\n21\n' > "$SRC";  _wait_key 2; b="$_KEY"
                             _wait_key 2; c="$_KEY"
eq "salve 1"          "28" "$a"
eq "salve 2, 1er"     "14" "$b"
eq "salve 2, 2e"      "21" "$c"

echo "  -- expiration quand rien n'arrive --"
reset
ko_cmd _wait_key 2
eq "_KEY vide apres expiration" "" "$_KEY"

echo "  -- purge memoire et fichier --"
reset
printf '103\n108\n' > "$SRC"
_drain_keys
_reset_keys
ko_cmd _pop_key
eq "fichier vide apres purge" "0" "$(wc -c < "$SRC" | tr -d ' ')"

echo "  -- lignes vides et blancs ignores --"
reset
printf '\n103\n\n \n108\n' > "$SRC"
got=""
while _wait_key 2; do got="$got $_KEY"; done
eq "seuls les keycodes sont retenus" "103 108" "$(echo $got)"

rm -f "$LIB" "$SRC" "$SRC.rd"
report "File d'attente des touches"
