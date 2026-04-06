# =============================================================
#  INSTALLER DUAL BOOT - Miyoo Mini Plus
#  Ce script configure automatiquement la carte SD
#  Lance avec clic droit > "Executer avec PowerShell"
# =============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DUAL BOOT MIYOO MINI+ - Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Détection des chemins ---
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Demander à l'utilisateur de choisir la cible
Write-Host "Sur quel lecteur ou dossier veux-tu installer le Dual Boot ?" -ForegroundColor Yellow
$SD = Read-Host "Entrez la lettre (ex: E, F) ou le chemin complet"

# Nettoyage de l'entrée (enlève les espaces et l'anti-slash final s'il y en a un)
$SD = $SD.Trim().TrimEnd('\')

# Si l'utilisateur a juste tapé une lettre (ex: "F"), on ajoute ":"
if ($SD.Length -eq 1 -and $SD -match "^[A-Za-z]$") {
    $SD = "$SD`:"
}

# Vérifier que la SD (ou le dossier) est accessible
if (-not (Test-Path "$SD\")) {
    Write-Host "ERREUR : Le chemin '$SD' n'est pas trouve ou est inaccessible !" -ForegroundColor Red
    Write-Host "Verifie que la carte SD est bien inseree ou que le chemin est correct."
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}

Write-Host "Cible trouvee : $SD" -ForegroundColor Green
Write-Host "Dossier source   : $SCRIPT_DIR" -ForegroundColor Green
Write-Host ""

# --- Chemins sources ---
$SRC_DUALBOOT  = "$SCRIPT_DIR\DualBoot"
$SRC_TELMIOS   = "$SCRIPT_DIR\Telmios"
$SRC_ONION     = "$SCRIPT_DIR\onion"

# Vérifier les sources
foreach ($path in @($SRC_DUALBOOT, $SRC_TELMIOS, $SRC_ONION)) {
    if (-not (Test-Path $path)) {
        Write-Host "ERREUR : Dossier introuvable : $path" -ForegroundColor Red
        Read-Host "Appuie sur Entree pour quitter"
        exit 1
    }
}

# =============================================================
Write-Host "ETAPE 1/7 - Nettoyage de l'ancienne structure..." -ForegroundColor Yellow
# Supprimer l'ancien DualBoot mal placé
if (Test-Path "$SD\DualBoot") {
    Remove-Item "$SD\DualBoot" -Recurse -Force
    Write-Host "  Supprime : $SD\DualBoot" -ForegroundColor Gray
}
# Supprimer l'ancien .tmp_update si présent
if (Test-Path "$SD\.tmp_update") {
    Remove-Item "$SD\.tmp_update" -Recurse -Force
    Write-Host "  Supprime : $SD\.tmp_update" -ForegroundColor Gray
}
# Supprimer les fichiers mal placés à la racine
foreach ($f in @("bootmenu_onion.png","bootmenu_telmios.png","generate_bootmenu.py","system.json","cachefile","autorun.inf")) {
    if (Test-Path "$SD\$f") {
        Remove-Item "$SD\$f" -Force
        Write-Host "  Supprime : $SD\$f" -ForegroundColor Gray
    }
}
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 2/7 - Installation du bootloader..." -ForegroundColor Yellow

# Copier le .tmp_update du DualBoot à la racine
Copy-Item "$SRC_DUALBOOT\.tmp_update" "$SD\.tmp_update" -Recurse -Force
Write-Host "  Copie : DualBoot\.tmp_update\ -> $SD\.tmp_update\" -ForegroundColor Gray

# Copier autorun.inf
Copy-Item "$SRC_DUALBOOT\autorun.inf" "$SD\autorun.inf" -Force
Write-Host "  Copie : DualBoot\autorun.inf -> $SD\autorun.inf" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 3/7 - Copie du fichier 'updater' (point d'entree)..." -ForegroundColor Yellow

Copy-Item "$SRC_ONION\.tmp_update\updater" "$SD\.tmp_update\updater" -Force
Write-Host "  Copie : onion\.tmp_update\updater -> $SD\.tmp_update\updater" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 4/7 - Copie des binaires (bin/)..." -ForegroundColor Yellow
Write-Host "  (Cette etape peut prendre 1-2 minutes...)" -ForegroundColor Gray

New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\bin" | Out-Null
Copy-Item "$SRC_ONION\.tmp_update\bin\*" "$SD\.tmp_update\bin\" -Recurse -Force
Write-Host "  Copie : onion\.tmp_update\bin\ -> $SD\.tmp_update\bin\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 5/7 - Copie des librairies (lib/)..." -ForegroundColor Yellow
Write-Host "  (Cette etape peut prendre 1-2 minutes...)" -ForegroundColor Gray

New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\lib" | Out-Null
Copy-Item "$SRC_TELMIOS\.tmp_update\lib\*" "$SD\.tmp_update\lib\" -Recurse -Force
Write-Host "  Copie : Telmios\.tmp_update\lib\ -> $SD\.tmp_update\lib\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 6/7 - Installation de TelmOS dans $SD\telmios\..." -ForegroundColor Yellow
Write-Host "  (Cette etape peut prendre quelques minutes...)" -ForegroundColor Gray

if (Test-Path "$SD\Telmios") {
    Remove-Item "$SD\Telmios" -Recurse -Force
}
if (Test-Path "$SD\telmios") {
    Remove-Item "$SD\telmios" -Recurse -Force
}
Copy-Item "$SRC_TELMIOS" "$SD\telmios" -Recurse -Force
Write-Host "  Copie : Telmios\ -> $SD\telmios\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 7/7 - Installation de OnionOS dans $SD\onion\..." -ForegroundColor Yellow
Write-Host "  (Cette etape peut prendre quelques minutes...)" -ForegroundColor Gray

if (Test-Path "$SD\onion") {
    Remove-Item "$SD\onion" -Recurse -Force
}
Copy-Item "$SRC_ONION" "$SD\onion" -Recurse -Force
Write-Host "  Copie : onion\ -> $SD\onion\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "Verification de la structure finale..." -ForegroundColor Yellow

$errors = 0
$checks = @(
    "$SD\.tmp_update\runtime.sh",
    "$SD\.tmp_update\updater",
    "$SD\.tmp_update\bin\prompt",
    "$SD\.tmp_update\bin\imgpop",
    "$SD\.tmp_update\lib\libSDL-1.2.so.0",
    "$SD\.tmp_update\res\bootmenu_onion.png",
    "$SD\.tmp_update\res\bootmenu_telmios.png",
    "$SD\telmios\.tmp_update\runtime.sh",
    "$SD\onion\.tmp_update\runtime.sh"
)

foreach ($check in $checks) {
    if (Test-Path $check) {
        Write-Host "  [OK] $check" -ForegroundColor Green
    } else {
        Write-Host "  [MANQUANT] $check" -ForegroundColor Red
        $errors++
    }
}

# =============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($errors -eq 0) {
    Write-Host "  INSTALLATION REUSSIE !" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Ejecte proprement la carte SD cible (clic droit"
    Write-Host "  sur $SD dans l'explorateur > Ejecter)"
    Write-Host "  puis insere-la dans le Miyoo Mini Plus."
    Write-Host ""
    Write-Host "  Au demarrage :"
    Write-Host "  D-pad gauche/droite = changer d'OS"
    Write-Host "  A = confirmer"
    Write-Host "  B = relancer le dernier OS"
} else {
    Write-Host "  ATTENTION : $errors fichier(s) manquant(s)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Verifie que les dossiers Telmios/ et"
    Write-Host "  onion/ sont bien dans le meme dossier"
    Write-Host "  que ce script."
}
Write-Host ""
Read-Host "Appuie sur Entree pour quitter"
