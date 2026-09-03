#!/bin/sh
# =============================================================
#  Bifrost - fonctions communes aux tests
# =============================================================
#  Les tests n'executent PAS une copie de la logique : ils
#  extraient les fonctions reelles de runtime.sh et les appellent
#  telles quelles. Une modification du bootloader est donc
#  immediatement couverte, sans duplication a maintenir.
# =============================================================

# Racine du depot : on remonte depuis le script appelant jusqu'a trouver le
# runtime. Les tests fonctionnent donc quel que soit le repertoire courant et
# quelle que soit la profondeur du fichier de test.
_find_runtime() {
    _d="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
    while [ -n "$_d" ] && [ "$_d" != "/" ]; do
        if [ -f "$_d/DualBoot/.tmp_update/runtime.sh" ]; then
            echo "$_d/DualBoot/.tmp_update/runtime.sh"
            return 0
        fi
        _d="$(dirname "$_d")"
    done
    return 1
}

RUNTIME="${RUNTIME:-$(_find_runtime)}"
if [ ! -f "$RUNTIME" ]; then
    echo "ERREUR : runtime.sh introuvable depuis $(dirname "$0")" >&2
    exit 90
fi

PASS=0
FAIL=0

# Extrait les fonctions nommees (et les constantes de keycodes) de
# runtime.sh vers le fichier $2, pret a etre source par un test.
#   $1 = liste de noms de fonctions, separes par des espaces
#   $2 = fichier de sortie
extract_functions() {
    _want="$1"
    _out="$2"
    : > "$_out"

    # Constantes de keycodes (KEY_UP=103, ...)
    grep -E '^KEY_[A-Z0-9]+=[0-9]+$' "$RUNTIME" >> "$_out"

    # Etat de la file d'attente des touches
    {
        echo 'KEY_FILE=/tmp/bifrost_test_key'
        echo 'PW_KEY=/tmp/bifrost_test_pwkey'
        echo '_KEY_SRC="$KEY_FILE"'
        echo '_KQ=""'
        echo '_KEY=""'
        echo 'log() { :; }'
    } >> "$_out"

    awk -v want="$_want" '
        BEGIN { n = split(want, a, " "); for (i = 1; i <= n; i++) wanted[a[i]] = 1 }
        /^[A-Za-z_][A-Za-z0-9_]*\(\) \{/ {
            name = $0; sub(/\(\).*/, "", name)
            if (name in wanted) {
                seen[name] = 1
                if ($0 ~ /\}[ \t]*$/) { print; next }   # fonction sur une ligne
                inside = 1
            }
        }
        inside { print }
        inside && /^\}$/ { inside = 0 }
        END {
            n = split(want, a, " ")
            for (i = 1; i <= n; i++)
                if (!(a[i] in seen))
                    printf "echo \"EXTRACTION MANQUEE: %s\" >&2; exit 90\n", a[i]
        }
    ' "$RUNTIME" >> "$_out"
}

# Compare une valeur attendue a une valeur obtenue.
#   $1 = libelle   $2 = attendu   $3 = obtenu
eq() {
    if [ "$2" = "$3" ]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        echo "    ECHEC : $1"
        echo "            attendu = '$2'"
        echo "            obtenu  = '$3'"
    fi
}

# Verifie qu'une commande reussit / echoue.
ok_cmd() { if "$@"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "    ECHEC : '$*' aurait du reussir"; fi; }
ko_cmd() { if "$@"; then FAIL=$((FAIL + 1)); echo "    ECHEC : '$*' aurait du echouer"; else PASS=$((PASS + 1)); fi; }

report() {
    echo ""
    echo "  $1 : $PASS reussis, $FAIL echecs"
    [ "$FAIL" -eq 0 ]
}
