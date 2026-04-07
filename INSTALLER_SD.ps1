# =============================================================
#  INSTALLER DUAL BOOT - Miyoo Mini / Mini Plus
#  Ce script configure automatiquement la carte SD
#  Lance avec clic droit > "Executer avec PowerShell"
# =============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DUAL BOOT MIYOO MINI+ - Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Detection des chemins ---
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Demander la cible (lettre SD ou chemin) ---
Write-Host "Sur quel lecteur veux-tu installer le Dual Boot ?" -ForegroundColor Yellow
$SD = Read-Host "Entre la lettre (ex: E, F) ou le chemin complet"
$SD = $SD.Trim().TrimEnd('\')
if ($SD.Length -eq 1 -and $SD -match "^[A-Za-z]$") { $SD = "$SD`:" }

if (-not (Test-Path "$SD\")) {
    Write-Host "ERREUR : Le chemin '$SD' n'est pas accessible !" -ForegroundColor Red
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}
Write-Host "Cible    : $SD" -ForegroundColor Green
Write-Host "Sources  : $SCRIPT_DIR" -ForegroundColor Green
Write-Host ""

# --- Auto-detection des dossiers OS ---
# Cherche dans le dossier du script ET dans les dossiers parents (jusqu'a 2 niveaux)
$searchPaths = @(
    $SCRIPT_DIR,
    (Split-Path -Parent $SCRIPT_DIR),
    (Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR))
)

$onionFolder = $null
$telmiFolder  = $null
foreach ($searchPath in $searchPaths) {
    if (-not $onionFolder -and (Test-Path $searchPath)) {
        $onionFolder = Get-ChildItem -Path $searchPath -Directory | Where-Object { $_.Name -like "Onion*" } | Select-Object -First 1
    }
    if (-not $telmiFolder -and (Test-Path $searchPath)) {
        $telmiFolder = Get-ChildItem -Path $searchPath -Directory | Where-Object { $_.Name -like "Telmi*" } | Select-Object -First 1
    }
}

if (-not $onionFolder) {
    Write-Host "ERREUR : Aucun dossier OnionOS trouve !" -ForegroundColor Red
    Write-Host "         Place le dossier OnionOS (ex: Onion-v4.3.1-1) dans :"
    Write-Host "         $SCRIPT_DIR"
    Write-Host "         ou dans le dossier parent."
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}
if (-not $telmiFolder) {
    Write-Host "ERREUR : Aucun dossier TelmiOS trouve !" -ForegroundColor Red
    Write-Host "         Place le dossier TelmiOS (ex: TelmiOS_v1.10.1) dans :"
    Write-Host "         $SCRIPT_DIR"
    Write-Host "         ou dans le dossier parent."
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}

$SRC_DUALBOOT = "$SCRIPT_DIR\DualBoot"
$SRC_ONION    = $onionFolder.FullName
$SRC_TELMIOS  = $telmiFolder.FullName

Write-Host "OnionOS  : $SRC_ONION" -ForegroundColor Green
Write-Host "TelmiOS  : $SRC_TELMIOS" -ForegroundColor Green
Write-Host ""

# Le bin/ d'Onion se trouve dans miyoo\app\.tmp_update\bin\
$SRC_ONION_BIN = "$SRC_ONION\miyoo\app\.tmp_update\bin"
if (-not (Test-Path $SRC_ONION_BIN)) {
    # Fallback : .tmp_update\bin\ a la racine
    $SRC_ONION_BIN = "$SRC_ONION\.tmp_update\bin"
}
if (-not (Test-Path $SRC_ONION_BIN)) {
    Write-Host "ERREUR : Dossier bin/ introuvable dans OnionOS" -ForegroundColor Red
    Write-Host "         Cherche dans : $SRC_ONION\miyoo\app\.tmp_update\bin"
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}
Write-Host "bin/     : $SRC_ONION_BIN" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $SRC_DUALBOOT)) {
    Write-Host "ERREUR : Dossier DualBoot introuvable : $SRC_DUALBOOT" -ForegroundColor Red
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}

# =============================================================
Write-Host "ETAPE 1/7 - Nettoyage de l'ancienne structure..." -ForegroundColor Yellow
foreach ($item in @("$SD\DualBoot", "$SD\.tmp_update")) {
    if (Test-Path $item) {
        Remove-Item $item -Recurse -Force
        Write-Host "  Supprime : $item" -ForegroundColor Gray
    }
}
foreach ($f in @("bootmenu_onion.png","bootmenu_telmios.png","generate_bootmenu.py","system.json","cachefile","autorun.inf")) {
    if (Test-Path "$SD\$f") { Remove-Item "$SD\$f" -Force }
}
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 2/7 - Installation du bootloader Bifrost..." -ForegroundColor Yellow
Copy-Item "$SRC_DUALBOOT\.tmp_update" "$SD\.tmp_update" -Recurse -Force
Write-Host "  Copie : DualBoot\.tmp_update\ -> $SD\.tmp_update\" -ForegroundColor Gray
Copy-Item "$SRC_DUALBOOT\autorun.inf" "$SD\autorun.inf" -Force
Write-Host "  Copie : DualBoot\autorun.inf -> $SD\autorun.inf" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 3/7 - Copie du fichier 'updater'..." -ForegroundColor Yellow
Copy-Item "$SRC_ONION\.tmp_update\updater" "$SD\.tmp_update\updater" -Force
Write-Host "  Copie : updater -> $SD\.tmp_update\updater" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 4/7 - Copie des binaires (bin/)..." -ForegroundColor Yellow
Write-Host "  (Peut prendre 1-2 minutes...)" -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\bin" | Out-Null
Copy-Item "$SRC_ONION_BIN\*" "$SD\.tmp_update\bin\" -Recurse -Force
Write-Host "  Copie : $SRC_ONION_BIN -> $SD\.tmp_update\bin\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 5/7 - Copie des librairies (lib/)..." -ForegroundColor Yellow
Write-Host "  (Peut prendre 1-2 minutes...)" -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\lib" | Out-Null
Copy-Item "$SRC_TELMIOS\.tmp_update\lib\*" "$SD\.tmp_update\lib\" -Recurse -Force
Write-Host "  Copie : TelmiOS\.tmp_update\lib\ -> $SD\.tmp_update\lib\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 6/7 - Installation de TelmiOS dans $SD\telmios\..." -ForegroundColor Yellow
Write-Host "  (Peut prendre quelques minutes...)" -ForegroundColor Gray
foreach ($t in @("$SD\Telmios","$SD\telmios")) {
    if (Test-Path $t) { Remove-Item $t -Recurse -Force }
}
Copy-Item "$SRC_TELMIOS" "$SD\telmios" -Recurse -Force
Write-Host "  Copie : TelmiOS\ -> $SD\telmios\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 7/7 - Installation de OnionOS dans $SD\onion\..." -ForegroundColor Yellow
Write-Host "  (Peut prendre quelques minutes...)" -ForegroundColor Gray
if (Test-Path "$SD\onion") { Remove-Item "$SD\onion" -Recurse -Force }
Copy-Item "$SRC_ONION" "$SD\onion" -Recurse -Force
Write-Host "  Copie : OnionOS\ -> $SD\onion\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "Verification de la structure finale..." -ForegroundColor Yellow

$errors = 0
$checks = @(
    "$SD\.tmp_update\runtime.sh",
    "$SD\.tmp_update\updater",
    "$SD\.tmp_update\bin\prompt",
    "$SD\.tmp_update\lib\libSDL-1.2.so.0",
    "$SD\.tmp_update\config\dualboot.cfg",
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

# Verifier les images du menu (au moins une langue)
$hasImages = (Test-Path "$SD\.tmp_update\res\bootmenu_onion_FR.raw") -or (Test-Path "$SD\.tmp_update\res\bootmenu_onion.raw")
if ($hasImages) {
    Write-Host "  [OK] Images menu .raw presentes" -ForegroundColor Green
} else {
    Write-Host "  [MANQUANT] Images menu .raw - lance generate_bootmenu.py avec la SD inseree" -ForegroundColor Yellow
}

# =============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($errors -eq 0) {
    Write-Host "  INSTALLATION REUSSIE !" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Ejecte la carte SD (clic droit sur $SD > Ejecter)"
    Write-Host "  puis insere-la dans le Miyoo Mini / Mini Plus."
    Write-Host ""
    Write-Host "  Au demarrage :"
    Write-Host "  D-pad gauche/droite = changer d'OS"
    Write-Host "  A = confirmer"
    Write-Host "  B = relancer le dernier OS"
} else {
    Write-Host "  ATTENTION : $errors fichier(s) manquant(s)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Verifie que les dossiers Onion* et Telmi*"
    Write-Host "  sont bien dans le meme dossier que ce script."
}
Write-Host ""
Read-Host "Appuie sur Entree pour quitter"
