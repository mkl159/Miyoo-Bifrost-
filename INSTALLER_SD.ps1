# =============================================================
#  INSTALLER DUAL BOOT - Miyoo Mini / Mini Plus
#  Ce script configure automatiquement la carte SD
#  Lance avec clic droit > "Executer avec PowerShell"
# =============================================================

$ErrorActionPreference = "Stop"

# --- Auto-elevation administrateur (requis pour diskpart) ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DUAL BOOT MIYOO MINI+ - Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Detection des chemins ---
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# Fonction qui ouvre un selecteur de dossier toujours au premier plan
function Select-Folder {
    param([string]$Description)
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.RootFolder = "MyComputer"
    $dialog.ShowNewFolderButton = $false
    # Fenetre invisible TopMost pour forcer le dialog au premier plan
    $owner = New-Object System.Windows.Forms.Form
    $owner.TopMost = $true
    $owner.StartPosition = "CenterScreen"
    $owner.Size = New-Object System.Drawing.Size(0, 0)
    $owner.Show()
    $owner.Activate()
    $result = $dialog.ShowDialog($owner)
    $owner.Dispose()
    if ($result -eq "OK") { return $dialog.SelectedPath.TrimEnd('\') }
    return $null
}

# --- Selectionner la carte SD ---
Write-Host "Selectionne le dossier de ta carte SD..." -ForegroundColor Yellow
$SD = Select-Folder "Selectionne la CARTE SD (ex: E:\)"
if (-not $SD) {
    Write-Host "Annule." -ForegroundColor Red
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}
if (-not (Test-Path "$SD\")) {
    Write-Host "ERREUR : Le chemin '$SD' n'est pas accessible !" -ForegroundColor Red
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}
Write-Host "Cible    : $SD" -ForegroundColor Green
Write-Host ""

# --- Verification et formatage FAT32 ---
$sdLetter = ($SD -replace ':\\.*', '').ToUpper()
$vol = Get-Volume -DriveLetter $sdLetter -ErrorAction SilentlyContinue
if ($vol) {
    $sizeGB = [math]::Round($vol.Size / 1GB, 1)
    $currentFS = $vol.FileSystem
    Write-Host "Carte SD detectee : $sizeGB Go, format actuel : $currentFS" -ForegroundColor Cyan
    if ($currentFS -ne "FAT32") {
        Write-Host ""
        Write-Host "  !! ATTENTION : La carte n'est pas en FAT32 !!" -ForegroundColor Red
        Write-Host "  Le firmware Miyoo ne supporte que FAT32 pour demarrer." -ForegroundColor Red
        Write-Host "  Une carte exFAT ou NTFS ne bootera PAS." -ForegroundColor Red
        Write-Host ""
        $rep = Read-Host "  Formater en FAT32 maintenant ? (O=Oui, toutes les donnees seront effacees)"
        if ($rep -match "^[oOyY]") {
            Write-Host "  Formatage FAT32 en cours (peut prendre quelques minutes)..." -ForegroundColor Yellow
            # diskpart supporte FAT32 quelle que soit la taille (contrairement a format.com)
            $dpScript = "select volume $sdLetter`r`nformat fs=fat32 label=MiyooBoot quick`r`nexit"
            $dpScript | diskpart | Out-Null
            # Verifier que ca a fonctionne
            $volAfter = Get-Volume -DriveLetter $sdLetter -ErrorAction SilentlyContinue
            if ($volAfter -and $volAfter.FileSystem -eq "FAT32") {
                Write-Host "  FAT32 OK !" -ForegroundColor Green
            } else {
                Write-Host "  ECHEC du formatage automatique." -ForegroundColor Red
                Write-Host "  Utilise Rufus manuellement : https://rufus.ie (FAT32, 32 Ko)" -ForegroundColor Yellow
                Read-Host "  Appuie sur Entree pour quitter"
                exit 1
            }
        } else {
            Write-Host ""
            Write-Host "  ARRET : Formate la carte en FAT32 avant de continuer." -ForegroundColor Red
            Read-Host "  Appuie sur Entree pour quitter"
            exit 1
        }
    } else {
        Write-Host "  FAT32 detecte - parfait !" -ForegroundColor Green
    }
    Write-Host ""
}

# --- Selectionner le dossier OnionOS ---
Write-Host "Selectionne le dossier OnionOS (ex: Onion-v4.3.1-1)..." -ForegroundColor Yellow
$SRC_ONION = Select-Folder "Selectionne le dossier ONIONOS (ex: Onion-v4.3.1-1)"
if (-not $SRC_ONION) {
    Write-Host "Annule." -ForegroundColor Red
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}
Write-Host "OnionOS  : $SRC_ONION" -ForegroundColor Green
Write-Host ""

# --- Selectionner le dossier TelmiOS ---
Write-Host "Selectionne le dossier TelmiOS (ex: TelmiOS_v1.10.1)..." -ForegroundColor Yellow
$SRC_TELMIOS = Select-Folder "Selectionne le dossier TELMIOS (ex: TelmiOS_v1.10.1)"
if (-not $SRC_TELMIOS) {
    Write-Host "Annule." -ForegroundColor Red
    Read-Host "Appuie sur Entree pour quitter"
    exit 1
}
Write-Host "TelmiOS  : $SRC_TELMIOS" -ForegroundColor Green
Write-Host ""

$SRC_DUALBOOT = "$SCRIPT_DIR\DualBoot"

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
Write-Host "ETAPE 1/8 - Nettoyage de l'ancienne structure..." -ForegroundColor Yellow
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
Write-Host "ETAPE 2/8 - Installation du bootloader Bifrost..." -ForegroundColor Yellow
# Sauvegarder le dualboot.cfg existant avant ecrasement
$existingCfg = "$SD\.tmp_update\config\dualboot.cfg"
$savedCfg = $null
if (Test-Path $existingCfg) {
    $savedCfg = Get-Content $existingCfg -Raw
    Write-Host "  Config existante sauvegardee" -ForegroundColor Gray
}
Copy-Item "$SRC_DUALBOOT\.tmp_update" "$SD\.tmp_update" -Recurse -Force
Write-Host "  Copie : DualBoot\.tmp_update\ -> $SD\.tmp_update\" -ForegroundColor Gray
# Restaurer le dualboot.cfg si existant
if ($savedCfg) {
    Set-Content -Path $existingCfg -Value $savedCfg -NoNewline
    Write-Host "  Config precedente restauree" -ForegroundColor Gray
}
Copy-Item "$SRC_DUALBOOT\autorun.inf" "$SD\autorun.inf" -Force
Write-Host "  Copie : DualBoot\autorun.inf -> $SD\autorun.inf" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 3/8 - Copie du fichier 'updater'..." -ForegroundColor Yellow
Copy-Item "$SRC_ONION\.tmp_update\updater" "$SD\.tmp_update\updater" -Force
Write-Host "  Copie : updater -> $SD\.tmp_update\updater" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 4/8 - Copie des binaires (bin/)..." -ForegroundColor Yellow
Write-Host "  (Peut prendre 1-2 minutes...)" -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\bin" | Out-Null
Copy-Item "$SRC_ONION_BIN\*" "$SD\.tmp_update\bin\" -Recurse -Force
Write-Host "  Copie : $SRC_ONION_BIN -> $SD\.tmp_update\bin\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 5/8 - Copie des librairies (lib/)..." -ForegroundColor Yellow
Write-Host "  (Peut prendre 1-2 minutes...)" -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\lib" | Out-Null
Copy-Item "$SRC_TELMIOS\.tmp_update\lib\*" "$SD\.tmp_update\lib\" -Recurse -Force
Write-Host "  Copie : TelmiOS\.tmp_update\lib\ -> $SD\.tmp_update\lib\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 6/8 - Installation de TelmiOS dans $SD\telmios\..." -ForegroundColor Yellow
Write-Host "  (Peut prendre quelques minutes...)" -ForegroundColor Gray
foreach ($t in @("$SD\Telmios","$SD\telmios")) {
    if (Test-Path $t) { Remove-Item $t -Recurse -Force }
}
Copy-Item "$SRC_TELMIOS" "$SD\telmios" -Recurse -Force
Write-Host "  Copie : TelmiOS\ -> $SD\telmios\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 7/8 - Installation de OnionOS dans $SD\onion\..." -ForegroundColor Yellow
Write-Host "  (Peut prendre quelques minutes...)" -ForegroundColor Gray
if (Test-Path "$SD\onion") { Remove-Item "$SD\onion" -Recurse -Force }
Copy-Item "$SRC_ONION" "$SD\onion" -Recurse -Force
Write-Host "  Copie : OnionOS\ -> $SD\onion\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "ETAPE 8/8 - Generation des images du menu de boot..." -ForegroundColor Yellow
$pythonScript = "$SCRIPT_DIR\generate_bootmenu.py"
if (-not (Test-Path $pythonScript)) {
    Write-Host "  [IGNORE] generate_bootmenu.py introuvable dans $SCRIPT_DIR" -ForegroundColor Yellow
} else {
    # Verifier que Python est disponible
    $pythonCmd = $null
    foreach ($cmd in @("python", "python3")) {
        try {
            $ver = & $cmd --version 2>&1
            if ($LASTEXITCODE -eq 0) { $pythonCmd = $cmd; break }
        } catch {}
    }
    if (-not $pythonCmd) {
        Write-Host "  [IGNORE] Python non trouve. Installe Python 3 puis lance generate_bootmenu.py" -ForegroundColor Yellow
    } else {
        # Installer Pillow si necessaire
        Write-Host "  Verification de Pillow..." -ForegroundColor Gray
        $pillowCheck = & $pythonCmd -c "import PIL" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  Installation de Pillow (pip install Pillow)..." -ForegroundColor Gray
            & $pythonCmd -m pip install Pillow --quiet
        }
        # Lancer le generateur avec le chemin de la SD
        Write-Host "  Generation des images RAW (FR/EN/ES)..." -ForegroundColor Gray
        & $pythonCmd $pythonScript $SD
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK - Images generees" -ForegroundColor Green
        } else {
            Write-Host "  ERREUR lors de la generation des images" -ForegroundColor Red
        }
    }
}

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
