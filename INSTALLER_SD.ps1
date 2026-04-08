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

# --- Choix de la langue / Language selection / Seleccion de idioma ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DUAL BOOT MIYOO MINI+ - Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Choisissez la langue / Choose language / Elige idioma :" -ForegroundColor Yellow
Write-Host "    1) Francais (FR)"
Write-Host "    2) English  (EN)"
Write-Host "    3) Espanol  (ES)"
Write-Host ""
do {
    $langChoice = Read-Host "  Entree / Enter / Entrada (1/2/3)"
} while ($langChoice -notin @("1","2","3"))

switch ($langChoice) {
    "1" { $INSTALL_LANG = "FR" }
    "2" { $INSTALL_LANG = "EN" }
    "3" { $INSTALL_LANG = "ES" }
}

$MSG = @{
    FR = @{
        title           = "  DUAL BOOT MIYOO MINI+ - Installation"
        selectSD        = "Selectionne le dossier de ta CARTE SD (ex: E:\)"
        selectOnion     = "Selectionne le dossier ONIONOS (ex: Onion-v4.3.1-1)"
        selectTelmi     = "Selectionne le dossier TELMIOS (ex: TelmiOS_v1.10.1)"
        cancelled       = "Annule."
        pressEnter      = "Appuie sur Entree pour quitter"
        sdTarget        = "Cible SD"
        onionDir        = "OnionOS "
        telmiDir        = "TelmiOS "
        binDir          = "bin/    "
        fat32Warn       = "  !! ATTENTION : La carte n'est pas en FAT32 !!"
        fat32Req        = "  Le firmware Miyoo ne supporte que FAT32 pour demarrer."
        fat32NoExfat    = "  Une carte exFAT ou NTFS ne bootera PAS."
        fat32Ask        = "  Formater en FAT32 maintenant ? (O=Oui, toutes les donnees seront effacees)"
        fat32Progress   = "  Formatage FAT32 en cours (peut prendre quelques minutes)..."
        fat32Ok         = "  FAT32 OK !"
        fat32Fail       = "  ECHEC du formatage automatique."
        fat32Rufus      = "  Utilise Rufus manuellement : https://rufus.ie (FAT32, 32 Ko)"
        fat32Abort      = "  ARRET : Formate la carte en FAT32 avant de continuer."
        fat32Good       = "  FAT32 detecte - parfait !"
        fat32Detected   = "Carte SD detectee"
        fat32Current    = "format actuel"
        step1           = "ETAPE 1/8 - Nettoyage de l'ancienne structure..."
        step2           = "ETAPE 2/8 - Installation du bootloader Bifrost..."
        step3           = "ETAPE 3/8 - Copie du fichier 'updater'..."
        step4           = "ETAPE 4/8 - Copie des binaires (bin/)..."
        step5           = "ETAPE 5/8 - Copie des librairies (lib/)..."
        step6_pre       = "ETAPE 6/8 - Installation de TelmiOS dans"
        step7_pre       = "ETAPE 7/8 - Installation de OnionOS dans"
        step8           = "ETAPE 8/8 - Generation des images du menu de boot..."
        slowCopy        = "  (Peut prendre 1-2 minutes...)"
        slowMinutes     = "  (Peut prendre quelques minutes...)"
        verif           = "Verification de la structure finale..."
        success         = "  INSTALLATION REUSSIE !"
        eject           = "  Ejecte la carte SD (clic droit > Ejecter)"
        insertSD        = "  puis insere-la dans le Miyoo Mini / Mini Plus."
        atBoot          = "  Au demarrage :"
        navOS           = "  D-pad gauche/droite = changer d'OS"
        confirm         = "  A = confirmer"
        lastOS          = "  B = relancer le dernier OS"
        missingFiles    = "  fichier(s) manquant(s)"
        checkFolders    = "  Verifie que les dossiers Onion* et Telmi*"
        checkSameDir    = "  sont bien dans le meme dossier que ce script."
        errBin          = "ERREUR : Dossier bin/ introuvable dans OnionOS"
        errNoSD         = "ERREUR : Le chemin '%s' n'est pas accessible !"
        errNoDual       = "ERREUR : Dossier DualBoot introuvable"
    }
    EN = @{
        title           = "  DUAL BOOT MIYOO MINI+ - Installation"
        selectSD        = "Select your SD CARD folder (ex: E:\)"
        selectOnion     = "Select the ONIONOS folder (ex: Onion-v4.3.1-1)"
        selectTelmi     = "Select the TELMIOS folder (ex: TelmiOS_v1.10.1)"
        cancelled       = "Cancelled."
        pressEnter      = "Press Enter to exit"
        sdTarget        = "SD target"
        onionDir        = "OnionOS "
        telmiDir        = "TelmiOS "
        binDir          = "bin/    "
        fat32Warn       = "  !! WARNING: The card is not FAT32 !!"
        fat32Req        = "  The Miyoo firmware only supports FAT32 for booting."
        fat32NoExfat    = "  An exFAT or NTFS card will NOT boot."
        fat32Ask        = "  Format to FAT32 now? (Y=Yes, all data will be erased)"
        fat32Progress   = "  Formatting to FAT32 (may take a few minutes)..."
        fat32Ok         = "  FAT32 OK!"
        fat32Fail       = "  Automatic format failed."
        fat32Rufus      = "  Use Rufus manually: https://rufus.ie (FAT32, 32 KB)"
        fat32Abort      = "  STOPPED: Format the card to FAT32 before continuing."
        fat32Good       = "  FAT32 detected - perfect!"
        fat32Detected   = "SD card detected"
        fat32Current    = "current format"
        step1           = "STEP 1/8 - Cleaning old structure..."
        step2           = "STEP 2/8 - Installing Bifrost bootloader..."
        step3           = "STEP 3/8 - Copying 'updater' file..."
        step4           = "STEP 4/8 - Copying binaries (bin/)..."
        step5           = "STEP 5/8 - Copying libraries (lib/)..."
        step6_pre       = "STEP 6/8 - Installing TelmiOS into"
        step7_pre       = "STEP 7/8 - Installing OnionOS into"
        step8           = "STEP 8/8 - Generating boot menu images..."
        slowCopy        = "  (May take 1-2 minutes...)"
        slowMinutes     = "  (May take a few minutes...)"
        verif           = "Checking final structure..."
        success         = "  INSTALLATION SUCCESSFUL!"
        eject           = "  Eject the SD card (right-click > Eject)"
        insertSD        = "  then insert it into your Miyoo Mini / Mini Plus."
        atBoot          = "  At startup:"
        navOS           = "  D-pad left/right = switch OS"
        confirm         = "  A = confirm"
        lastOS          = "  B = relaunch last OS"
        missingFiles    = "  missing file(s)"
        checkFolders    = "  Make sure the Onion* and Telmi* folders"
        checkSameDir    = "  are in the same folder as this script."
        errBin          = "ERROR: bin/ folder not found in OnionOS"
        errNoSD         = "ERROR: Path '%s' is not accessible!"
        errNoDual       = "ERROR: DualBoot folder not found"
    }
    ES = @{
        title           = "  DUAL BOOT MIYOO MINI+ - Instalacion"
        selectSD        = "Selecciona la carpeta de tu TARJETA SD (ej: E:\)"
        selectOnion     = "Selecciona la carpeta ONIONOS (ej: Onion-v4.3.1-1)"
        selectTelmi     = "Selecciona la carpeta TELMIOS (ej: TelmiOS_v1.10.1)"
        cancelled       = "Cancelado."
        pressEnter      = "Pulsa Enter para salir"
        sdTarget        = "SD destino"
        onionDir        = "OnionOS "
        telmiDir        = "TelmiOS "
        binDir          = "bin/    "
        fat32Warn       = "  !! ATENCION: La tarjeta no esta en FAT32 !!"
        fat32Req        = "  El firmware Miyoo solo soporta FAT32 para arrancar."
        fat32NoExfat    = "  Una tarjeta exFAT o NTFS NO arrancara."
        fat32Ask        = "  Formatear a FAT32 ahora? (S=Si, todos los datos seran borrados)"
        fat32Progress   = "  Formateando a FAT32 (puede tardar unos minutos)..."
        fat32Ok         = "  FAT32 OK!"
        fat32Fail       = "  Fallo el formateo automatico."
        fat32Rufus      = "  Usa Rufus manualmente: https://rufus.ie (FAT32, 32 KB)"
        fat32Abort      = "  DETENIDO: Formatea la tarjeta en FAT32 antes de continuar."
        fat32Good       = "  FAT32 detectado - perfecto!"
        fat32Detected   = "Tarjeta SD detectada"
        fat32Current    = "formato actual"
        step1           = "PASO 1/8 - Limpiando estructura antigua..."
        step2           = "PASO 2/8 - Instalando bootloader Bifrost..."
        step3           = "PASO 3/8 - Copiando archivo 'updater'..."
        step4           = "PASO 4/8 - Copiando binarios (bin/)..."
        step5           = "PASO 5/8 - Copiando librerias (lib/)..."
        step6_pre       = "PASO 6/8 - Instalando TelmiOS en"
        step7_pre       = "PASO 7/8 - Instalando OnionOS en"
        step8           = "PASO 8/8 - Generando imagenes del menu de arranque..."
        slowCopy        = "  (Puede tardar 1-2 minutos...)"
        slowMinutes     = "  (Puede tardar unos minutos...)"
        verif           = "Verificando estructura final..."
        success         = "  INSTALACION EXITOSA!"
        eject           = "  Expulsa la tarjeta SD (clic derecho > Expulsar)"
        insertSD        = "  luego insertala en tu Miyoo Mini / Mini Plus."
        atBoot          = "  Al encender:"
        navOS           = "  D-pad izquierda/derecha = cambiar OS"
        confirm         = "  A = confirmar"
        lastOS          = "  B = relanzar el ultimo OS"
        missingFiles    = "  archivo(s) faltante(s)"
        checkFolders    = "  Verifica que las carpetas Onion* y Telmi*"
        checkSameDir    = "  esten en la misma carpeta que este script."
        errBin          = "ERROR: carpeta bin/ no encontrada en OnionOS"
        errNoSD         = "ERROR: La ruta '%s' no es accesible!"
        errNoDual       = "ERROR: Carpeta DualBoot no encontrada"
    }
}
$L = $MSG[$INSTALL_LANG]

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host $L.title -ForegroundColor Cyan
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
Write-Host "$($L.selectSD)..." -ForegroundColor Yellow
$SD = Select-Folder $L.selectSD
if (-not $SD) {
    Write-Host $L.cancelled -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
if (-not (Test-Path "$SD\")) {
    Write-Host ($L.errNoSD -replace '%s', $SD) -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
Write-Host "$($L.sdTarget) : $SD" -ForegroundColor Green
Write-Host ""

# --- Verification et formatage FAT32 ---
$sdLetter = ($SD -replace ':\\.*', '').ToUpper()
$vol = Get-Volume -DriveLetter $sdLetter -ErrorAction SilentlyContinue
if ($vol) {
    $sizeGB = [math]::Round($vol.Size / 1GB, 1)
    $currentFS = $vol.FileSystem
    Write-Host "$($L.fat32Detected) : $sizeGB Go, $($L.fat32Current) : $currentFS" -ForegroundColor Cyan
    if ($currentFS -ne "FAT32") {
        Write-Host ""
        Write-Host $L.fat32Warn -ForegroundColor Red
        Write-Host $L.fat32Req -ForegroundColor Red
        Write-Host $L.fat32NoExfat -ForegroundColor Red
        Write-Host ""
        $rep = Read-Host $L.fat32Ask
        if ($rep -match "^[oOyYsS]") {
            Write-Host $L.fat32Progress -ForegroundColor Yellow
            # diskpart supporte FAT32 quelle que soit la taille (contrairement a format.com)
            $dpScript = "select volume $sdLetter`r`nformat fs=fat32 label=MiyooBoot quick`r`nexit"
            $dpScript | diskpart | Out-Null
            # Verifier que ca a fonctionne
            $volAfter = Get-Volume -DriveLetter $sdLetter -ErrorAction SilentlyContinue
            if ($volAfter -and $volAfter.FileSystem -eq "FAT32") {
                Write-Host $L.fat32Ok -ForegroundColor Green
            } else {
                Write-Host $L.fat32Fail -ForegroundColor Red
                Write-Host $L.fat32Rufus -ForegroundColor Yellow
                Read-Host $L.pressEnter
                exit 1
            }
        } else {
            Write-Host ""
            Write-Host $L.fat32Abort -ForegroundColor Red
            Read-Host $L.pressEnter
            exit 1
        }
    } else {
        Write-Host $L.fat32Good -ForegroundColor Green
    }
    Write-Host ""
}

# --- Selectionner le dossier OnionOS ---
Write-Host "$($L.selectOnion)..." -ForegroundColor Yellow
$SRC_ONION = Select-Folder $L.selectOnion
if (-not $SRC_ONION) {
    Write-Host $L.cancelled -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
Write-Host "$($L.onionDir) : $SRC_ONION" -ForegroundColor Green
Write-Host ""

# --- Selectionner le dossier TelmiOS ---
Write-Host "$($L.selectTelmi)..." -ForegroundColor Yellow
$SRC_TELMIOS = Select-Folder $L.selectTelmi
if (-not $SRC_TELMIOS) {
    Write-Host $L.cancelled -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
Write-Host "$($L.telmiDir) : $SRC_TELMIOS" -ForegroundColor Green
Write-Host ""

$SRC_DUALBOOT = "$SCRIPT_DIR\DualBoot"

# Le bin/ d'Onion se trouve dans miyoo\app\.tmp_update\bin\
$SRC_ONION_BIN = "$SRC_ONION\miyoo\app\.tmp_update\bin"
if (-not (Test-Path $SRC_ONION_BIN)) {
    # Fallback : .tmp_update\bin\ a la racine
    $SRC_ONION_BIN = "$SRC_ONION\.tmp_update\bin"
}
if (-not (Test-Path $SRC_ONION_BIN)) {
    Write-Host $L.errBin -ForegroundColor Red
    Write-Host "         $SRC_ONION\miyoo\app\.tmp_update\bin"
    Read-Host $L.pressEnter
    exit 1
}
Write-Host "$($L.binDir) : $SRC_ONION_BIN" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $SRC_DUALBOOT)) {
    Write-Host "$($L.errNoDual) : $SRC_DUALBOOT" -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}

# =============================================================
Write-Host $L.step1 -ForegroundColor Yellow
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
Write-Host $L.step2 -ForegroundColor Yellow
# Sauvegarder le dualboot.cfg existant avant ecrasement
$existingCfg = "$SD\.tmp_update\config\dualboot.cfg"
$savedCfg = $null
if (Test-Path $existingCfg) {
    $savedCfg = Get-Content $existingCfg -Raw
    Write-Host "  Config existante sauvegardee" -ForegroundColor Gray
}
Copy-Item "$SRC_DUALBOOT\.tmp_update" "$SD\.tmp_update" -Recurse -Force
Write-Host "  DualBoot\.tmp_update\ -> $SD\.tmp_update\" -ForegroundColor Gray
# Restaurer le dualboot.cfg si existant, sinon mettre LANG selon choix utilisateur
if ($savedCfg) {
    Set-Content -Path $existingCfg -Value $savedCfg -NoNewline
    Write-Host "  Config precedente restauree" -ForegroundColor Gray
} else {
    # Mettre a jour LANG dans le nouveau dualboot.cfg selon le choix de langue
    $cfgContent = Get-Content $existingCfg -Raw
    $cfgContent = $cfgContent -replace '(?m)^LANG=.*$', "LANG=$INSTALL_LANG"
    Set-Content -Path $existingCfg -Value $cfgContent -NoNewline
    Write-Host "  LANG=$INSTALL_LANG defini dans dualboot.cfg" -ForegroundColor Gray
}
Copy-Item "$SRC_DUALBOOT\autorun.inf" "$SD\autorun.inf" -Force
Write-Host "  DualBoot\autorun.inf -> $SD\autorun.inf" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step3 -ForegroundColor Yellow
Copy-Item "$SRC_ONION\.tmp_update\updater" "$SD\.tmp_update\updater" -Force
Write-Host "  updater -> $SD\.tmp_update\updater" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step4 -ForegroundColor Yellow
Write-Host $L.slowCopy -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\bin" | Out-Null
Copy-Item "$SRC_ONION_BIN\*" "$SD\.tmp_update\bin\" -Recurse -Force
Write-Host "  $SRC_ONION_BIN -> $SD\.tmp_update\bin\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step5 -ForegroundColor Yellow
Write-Host $L.slowCopy -ForegroundColor Gray
New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\lib" | Out-Null
Copy-Item "$SRC_TELMIOS\.tmp_update\lib\*" "$SD\.tmp_update\lib\" -Recurse -Force
Write-Host "  TelmiOS\.tmp_update\lib\ -> $SD\.tmp_update\lib\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "$($L.step6_pre) $SD\telmios\..." -ForegroundColor Yellow
Write-Host $L.slowMinutes -ForegroundColor Gray
foreach ($t in @("$SD\Telmios","$SD\telmios")) {
    if (Test-Path $t) { Remove-Item $t -Recurse -Force }
}
Copy-Item "$SRC_TELMIOS" "$SD\telmios" -Recurse -Force
Write-Host "  TelmiOS\ -> $SD\telmios\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "$($L.step7_pre) $SD\onion\..." -ForegroundColor Yellow
Write-Host $L.slowMinutes -ForegroundColor Gray
if (Test-Path "$SD\onion") { Remove-Item "$SD\onion" -Recurse -Force }
Copy-Item "$SRC_ONION" "$SD\onion" -Recurse -Force
Write-Host "  OnionOS\ -> $SD\onion\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step8 -ForegroundColor Yellow
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
Write-Host $L.verif -ForegroundColor Yellow

$errors = 0
$checks = @(
    "$SD\.tmp_update\runtime.sh",
    "$SD\.tmp_update\updater",
    "$SD\.tmp_update\bin\prompt",
    "$SD\.tmp_update\lib\libSDL-1.2.so.0",
    "$SD\.tmp_update\config\dualboot.cfg",
    "$SD\telmios\.tmp_update\runtime.sh"
)

foreach ($check in $checks) {
    if (Test-Path $check) {
        Write-Host "  [OK] $check" -ForegroundColor Green
    } else {
        Write-Host "  [MANQUANT] $check" -ForegroundColor Red
        $errors++
    }
}

# OnionOS: runtime.sh est absent avant le premier demarrage (installe par install.sh au boot)
# On verifie la presence de l'installeur ou du runtime
if ((Test-Path "$SD\onion\miyoo\app\.tmp_update\install.sh") -or (Test-Path "$SD\onion\.tmp_update\runtime.sh")) {
    Write-Host "  [OK] $SD\onion\ (OnionOS pret)" -ForegroundColor Green
} else {
    Write-Host "  [MANQUANT] $SD\onion\ - dossier OnionOS absent ou incomplet" -ForegroundColor Red
    $errors++
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
    Write-Host $L.success -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host $L.eject
    Write-Host $L.insertSD
    Write-Host ""
    Write-Host $L.atBoot
    Write-Host $L.navOS
    Write-Host $L.confirm
    Write-Host $L.lastOS
} else {
    Write-Host "  $($L.warning) $errors $($L.missingFiles)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $L.checkFolders
    Write-Host $L.checkSameDir
}
Write-Host ""
Read-Host $L.pressEnter
