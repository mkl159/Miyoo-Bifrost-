#!/bin/sh
# =============================================================
#  Bifrost - suite de tests
# =============================================================
#  Usage :  sh tests/run_tests.sh
#
#  Les tests extraient les fonctions reelles de runtime.sh et les
#  executent : aucune logique n'est dupliquee. Ils tournent sous
#  chaque shell POSIX disponible, busybox ash en priorite puisque
#  c'est celui de la console.
# =============================================================

cd "$(dirname "$0")/.." || exit 1
TESTS_DIR=tests/cases
RUNTIME=DualBoot/.tmp_update/runtime.sh

TOTAL_FAIL=0
note_fail() { TOTAL_FAIL=$((TOTAL_FAIL + 1)); }

echo "============================================================"
echo "  Bifrost - suite de tests"
echo "============================================================"

# ---- 1. Verification syntaxique -----------------------------
echo ""
echo "[1] Syntaxe"
for shell_bin in "sh" "dash" "busybox sh"; do
    command -v ${shell_bin%% *} > /dev/null 2>&1 || continue
    if $shell_bin -n "$RUNTIME" 2>/dev/null; then
        echo "    runtime.sh : OK sous $shell_bin"
    else
        echo "    runtime.sh : ERREUR DE SYNTAXE sous $shell_bin"
        note_fail
    fi
done
if bash -n install_macos.sh 2>/dev/null; then
    echo "    install_macos.sh : OK"
else
    echo "    install_macos.sh : ERREUR DE SYNTAXE"
    note_fail
fi
if command -v python3 > /dev/null 2>&1; then
    if python3 -c 'import ast,io,sys; ast.parse(io.open("generate_bootmenu.py",encoding="utf-8").read())' 2>/dev/null; then
        echo "    generate_bootmenu.py : OK"
    else
        echo "    generate_bootmenu.py : ERREUR DE SYNTAXE"
        note_fail
    fi
fi

# ---- 2. Cas de test ------------------------------------------
# On privilegie busybox ash : c'est le shell de la console. A defaut,
# dash, puis sh. Les cas sont rejoues sous chaque shell disponible.
# Les cas sont rejoues sous chaque shell POSIX disponible. busybox ash est
# le plus important : c'est celui qui execute reellement le bootloader sur
# la console.
run_cases_under() {
    echo ""
    echo "[2] Cas de test sous $*"
    for case_file in "$TESTS_DIR"/case_*.sh; do
        [ -f "$case_file" ] || continue
        echo ""
        echo "  >>> $(basename "$case_file")"
        "$@" "$case_file" || note_fail
    done
}

RAN_ANY=0
if command -v busybox > /dev/null 2>&1; then
    run_cases_under busybox sh
    RAN_ANY=1
fi
if command -v dash > /dev/null 2>&1; then
    run_cases_under dash
    RAN_ANY=1
fi
if [ "$RAN_ANY" -eq 0 ]; then
    run_cases_under sh
fi

# ---- 3. Bilan ------------------------------------------------
echo ""
echo "============================================================"
if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo "  TOUS LES TESTS PASSENT"
    echo "============================================================"
    exit 0
else
    echo "  $TOTAL_FAIL groupe(s) de tests en echec"
    echo "============================================================"
    exit 1
fi
