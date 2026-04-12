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

# --- Fichier log (reinitialise a chaque lancement) ---
$LOG_FILE = "$env:USERPROFILE\Desktop\bifrost_install.log"
"" | Set-Content $LOG_FILE
function Log {
    param([string]$msg, [string]$level = "INFO")
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$level] $msg"
    Add-Content -Path $LOG_FILE -Value $line
    if ($level -eq "ERROR") { Write-Host "  LOG: $msg" -ForegroundColor DarkRed }
    elseif ($level -eq "WARN")  { Write-Host "  LOG: $msg" -ForegroundColor DarkYellow }
}

Log "=== Bifrost Installer start ==="
Log "Script: $($MyInvocation.MyCommand.Path)"
Log "User: $env:USERNAME  /  OS: $([System.Environment]::OSVersion.VersionString)"

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
Log "Langue choisie : $INSTALL_LANG"

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
        logSaved        = "  Log complet sauvegarde sur le Bureau"
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
        logSaved        = "  Full log saved to Desktop"
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
        logSaved        = "  Log completo guardado en el Escritorio"
    }
}
$L = $MSG[$INSTALL_LANG]

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host $L.title -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  (Log : $LOG_FILE)" -ForegroundColor DarkGray
Write-Host ""

# --- Detection des chemins ---
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Log "SCRIPT_DIR : $SCRIPT_DIR"

# Fonction qui ouvre un selecteur de dossier toujours au premier plan
function Select-Folder {
    param([string]$Description, [string]$InitialPath = $SCRIPT_DIR)
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $false
    # Demarre directement dans le dossier du script (ou le chemin fourni)
    if ($InitialPath -and (Test-Path $InitialPath)) {
        $dialog.SelectedPath = $InitialPath
    }
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
Log "Ouverture selecteur carte SD"
$SD = Select-Folder $L.selectSD
if (-not $SD) {
    Log "Carte SD : annule par l'utilisateur" "WARN"
    Write-Host $L.cancelled -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
# Normalise : "E:" -> "E:\" pour eviter Path.Combine bug (E:.tmp_update au lieu de E:\.tmp_update)
if ($SD -match '^[A-Za-z]:$') { $SD = "$SD\" }
Log "Carte SD selectionnee : $SD"
if (-not (Test-Path "$SD\")) {
    Log "Carte SD inaccessible : $SD" "ERROR"
    Write-Host ($L.errNoSD -replace '%s', $SD) -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
Write-Host "$($L.sdTarget) : $SD" -ForegroundColor Green
Write-Host ""

# --- Verification et formatage FAT32 ---
$sdLetter = ($SD -replace ':\\.*', '').ToUpper()
Log "Lettre lecteur SD : $sdLetter"
$vol = Get-Volume -DriveLetter $sdLetter -ErrorAction SilentlyContinue
if ($vol) {
    $sizeGB = [math]::Round($vol.Size / 1GB, 1)
    $currentFS = $vol.FileSystem
    Log "Volume detecte : $sizeGB Go, FS=$currentFS, Label=$($vol.FileSystemLabel)"
    Write-Host "$($L.fat32Detected) : $sizeGB Go, $($L.fat32Current) : $currentFS" -ForegroundColor Cyan
    if ($currentFS -ne "FAT32") {
        Log "FAT32 requis mais FS=$currentFS - proposition de formatage" "WARN"
        Write-Host ""
        Write-Host $L.fat32Warn -ForegroundColor Red
        Write-Host $L.fat32Req -ForegroundColor Red
        Write-Host $L.fat32NoExfat -ForegroundColor Red
        Write-Host ""
        $rep = Read-Host $L.fat32Ask
        if ($rep -match "^[oOyYsS]") {
            Log "Formatage FAT32 demande par l'utilisateur"
            Write-Host $L.fat32Progress -ForegroundColor Yellow
            $dpScript = "select volume $sdLetter`r`nformat fs=fat32 label=MiyooBoot quick`r`nexit"
            $dpOut = $dpScript | diskpart
            Log "diskpart output : $($dpOut -join ' | ')"
            $volAfter = Get-Volume -DriveLetter $sdLetter -ErrorAction SilentlyContinue
            if ($volAfter -and $volAfter.FileSystem -eq "FAT32") {
                Log "Formatage FAT32 reussi"
                Write-Host $L.fat32Ok -ForegroundColor Green
            } else {
                Log "Formatage FAT32 echoue - FS apres=$($volAfter.FileSystem)" "ERROR"
                Write-Host $L.fat32Fail -ForegroundColor Red
                Write-Host $L.fat32Rufus -ForegroundColor Yellow
                Log "=== FIN (echec formatage) ==="
                Write-Host $L.logSaved -ForegroundColor DarkGray
                Read-Host $L.pressEnter
                exit 1
            }
        } else {
            Log "Formatage refuse - demande si continuer quand meme" "WARN"
            Write-Host ""
            Write-Host "  La carte n'est pas en FAT32. Le Miyoo risque de ne pas demarrer." -ForegroundColor Yellow
            $repSkip = Read-Host "  Continuer quand meme sans formater ? (O=Oui pour risquer, N=Non pour arreter)"
            if ($repSkip -match "^[oOyYsS]") {
                Log "Continuer sans FAT32 - risque accepte par l'utilisateur" "WARN"
                Write-Host "  [AVERT] Installation continuee sans FAT32 - la carte risque de ne pas booter." -ForegroundColor Yellow
            } else {
                Log "Arret demande par l'utilisateur" "WARN"
                Write-Host ""
                Write-Host $L.fat32Abort -ForegroundColor Red
                Log "=== FIN (annule) ==="
                Write-Host $L.logSaved -ForegroundColor DarkGray
                Read-Host $L.pressEnter
                exit 1
            }
        }
    } else {
        Log "FAT32 deja present - OK"
        Write-Host $L.fat32Good -ForegroundColor Green
    }
    Write-Host ""
} else {
    Log "Volume non detecte pour la lettre $sdLetter" "WARN"
}

# --- Selectionner le dossier OnionOS ---
Write-Host "$($L.selectOnion)..." -ForegroundColor Yellow
Log "Ouverture selecteur OnionOS"
$SRC_ONION = Select-Folder $L.selectOnion
if (-not $SRC_ONION) {
    Log "OnionOS : annule par l'utilisateur" "WARN"
    Write-Host $L.cancelled -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
Log "OnionOS selectionne : $SRC_ONION"
Write-Host "$($L.onionDir) : $SRC_ONION" -ForegroundColor Green
Write-Host ""

# --- Selectionner le dossier TelmiOS ---
Write-Host "$($L.selectTelmi)..." -ForegroundColor Yellow
Log "Ouverture selecteur TelmiOS"
$SRC_TELMIOS = Select-Folder $L.selectTelmi
if (-not $SRC_TELMIOS) {
    Log "TelmiOS : annule par l'utilisateur" "WARN"
    Write-Host $L.cancelled -ForegroundColor Red
    Read-Host $L.pressEnter
    exit 1
}
Log "TelmiOS selectionne : $SRC_TELMIOS"
Write-Host "$($L.telmiDir) : $SRC_TELMIOS" -ForegroundColor Green
Write-Host ""

$SRC_DUALBOOT = "$SCRIPT_DIR\DualBoot"
Log "SRC_DUALBOOT : $SRC_DUALBOOT"

# Le bin/ d'Onion se trouve dans miyoo\app\.tmp_update\bin\
$SRC_ONION_BIN = "$SRC_ONION\miyoo\app\.tmp_update\bin"
Log "Recherche bin/ dans : $SRC_ONION_BIN"
if (-not (Test-Path $SRC_ONION_BIN)) {
    $SRC_ONION_BIN = "$SRC_ONION\.tmp_update\bin"
    Log "Fallback bin/ : $SRC_ONION_BIN"
}
if (-not (Test-Path $SRC_ONION_BIN)) {
    Log "bin/ introuvable dans OnionOS" "ERROR"
    Write-Host $L.errBin -ForegroundColor Red
    Write-Host "         $SRC_ONION\miyoo\app\.tmp_update\bin"
    Log "=== FIN (bin/ manquant) ==="
    Write-Host $L.logSaved -ForegroundColor DarkGray
    Read-Host $L.pressEnter
    exit 1
}
Log "bin/ trouve : $SRC_ONION_BIN"
Write-Host "$($L.binDir) : $SRC_ONION_BIN" -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $SRC_DUALBOOT)) {
    Log "DualBoot introuvable : $SRC_DUALBOOT" "ERROR"
    Write-Host "$($L.errNoDual) : $SRC_DUALBOOT" -ForegroundColor Red
    Log "=== FIN (DualBoot manquant) ==="
    Write-Host $L.logSaved -ForegroundColor DarkGray
    Read-Host $L.pressEnter
    exit 1
}

# =============================================================
Write-Host $L.step1 -ForegroundColor Yellow
Log "--- ETAPE 1 : Nettoyage ---"
foreach ($item in @("$SD\DualBoot", "$SD\.tmp_update")) {
    if (Test-Path $item) {
        Log "Suppression : $item"
        Remove-Item $item -Recurse -Force
        Write-Host "  Supprime : $item" -ForegroundColor Gray
    }
}
foreach ($f in @("bootmenu_onion.png","bootmenu_telmios.png","generate_bootmenu.py","system.json","cachefile","autorun.inf")) {
    if (Test-Path "$SD\$f") {
        Log "Suppression fichier racine : $f"
        Remove-Item "$SD\$f" -Force
    }
}
Log "Nettoyage termine"
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step2 -ForegroundColor Yellow
Log "--- ETAPE 2 : Bootloader Bifrost ---"
$existingCfg = "$SD\.tmp_update\config\dualboot.cfg"
$savedCfg = $null
if (Test-Path $existingCfg) {
    $savedCfg = Get-Content $existingCfg -Raw
    Log "Config existante sauvegardee ($($savedCfg.Length) chars)"
    Write-Host "  Config existante sauvegardee" -ForegroundColor Gray
}
Log "Copie DualBoot\.tmp_update -> $SD\.tmp_update"
Copy-Item "$SRC_DUALBOOT\.tmp_update" "$SD\.tmp_update" -Recurse -Force
Write-Host "  DualBoot\.tmp_update\ -> $SD\.tmp_update\" -ForegroundColor Gray
if ($savedCfg) {
    Set-Content -Path $existingCfg -Value $savedCfg -NoNewline
    Log "Config precedente restauree"
    Write-Host "  Config precedente restauree" -ForegroundColor Gray
} else {
    $cfgContent = Get-Content $existingCfg -Raw
    $cfgContent = $cfgContent -replace '(?m)^LANG=.*$', "LANG=$INSTALL_LANG"
    Set-Content -Path $existingCfg -Value $cfgContent -NoNewline
    Log "LANG=$INSTALL_LANG ecrit dans dualboot.cfg"
    Write-Host "  LANG=$INSTALL_LANG defini dans dualboot.cfg" -ForegroundColor Gray
}
Log "Copie autorun.inf"
Copy-Item "$SRC_DUALBOOT\autorun.inf" "$SD\autorun.inf" -Force
Write-Host "  DualBoot\autorun.inf -> $SD\autorun.inf" -ForegroundColor Gray
Log "Etape 2 terminee"
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step3 -ForegroundColor Yellow
Log "--- ETAPE 3 : updater ---"
$updaterSrc = "$SRC_ONION\.tmp_update\updater"
if (Test-Path $updaterSrc) {
    Copy-Item $updaterSrc "$SD\.tmp_update\updater" -Force
    Log "updater copie depuis $updaterSrc"
} else {
    Log "updater introuvable dans $updaterSrc" "WARN"
}
Write-Host "  updater -> $SD\.tmp_update\updater" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step4 -ForegroundColor Yellow
Write-Host $L.slowCopy -ForegroundColor Gray
Log "--- ETAPE 4 : bin/ ---"
New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\bin" | Out-Null
Log "Copie bin/ : $SRC_ONION_BIN -> $SD\.tmp_update\bin"
Copy-Item "$SRC_ONION_BIN\*" "$SD\.tmp_update\bin\" -Recurse -Force
$binCount = (Get-ChildItem "$SD\.tmp_update\bin" -Recurse -File).Count
Log "bin/ copie : $binCount fichiers"
Write-Host "  $SRC_ONION_BIN -> $SD\.tmp_update\bin\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step5 -ForegroundColor Yellow
Write-Host $L.slowCopy -ForegroundColor Gray
Log "--- ETAPE 5 : lib/ ---"
$libSrc = "$SRC_TELMIOS\.tmp_update\lib"
if (-not (Test-Path $libSrc)) {
    Log "lib/ introuvable dans TelmiOS : $libSrc" "ERROR"
} else {
    New-Item -ItemType Directory -Force -Path "$SD\.tmp_update\lib" | Out-Null
    Log "Copie lib/ : $libSrc -> $SD\.tmp_update\lib"
    Copy-Item "$libSrc\*" "$SD\.tmp_update\lib\" -Recurse -Force
    $libCount = (Get-ChildItem "$SD\.tmp_update\lib" -Recurse -File).Count
    Log "lib/ copie : $libCount fichiers"
}
Write-Host "  TelmiOS\.tmp_update\lib\ -> $SD\.tmp_update\lib\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host "$($L.step6_pre) $SD\telmios\..." -ForegroundColor Yellow
Write-Host $L.slowMinutes -ForegroundColor Gray
Log "--- ETAPE 6 : TelmiOS ---"
foreach ($t in @("$SD\Telmios","$SD\telmios")) {
    if (Test-Path $t) {
        Log "Suppression ancien dossier : $t"
        Remove-Item $t -Recurse -Force
    }
}
Log "Copie TelmiOS : $SRC_TELMIOS -> $SD\telmios"
Copy-Item "$SRC_TELMIOS" "$SD\telmios" -Recurse -Force
$telmiCount = (Get-ChildItem "$SD\telmios" -Recurse -File).Count
Log "TelmiOS copie : $telmiCount fichiers"
Write-Host "  TelmiOS\ -> $SD\telmios\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# --- Telmi-Sync : Stories / Saves / Music doivent etre a la racine ---
# Telmi-Sync lit/ecrit Stories et Saves directement a la racine de la SD.
# Le runtime.sh ne bind-monte un dossier de telmios/ que s'il existe :
# en le retirant de telmios/, TelmiOS lira automatiquement la racine.
Log "--- Telmi-Sync : deplacement Stories/Saves/Music vers racine ---"
Write-Host "  [Telmi-Sync] Placement des donnees a la racine..." -ForegroundColor Gray
foreach ($datadir in @("Stories", "Saves", "Music")) {
    $srcDir = "$SD\telmios\$datadir"
    $dstDir = "$SD\$datadir"
    if (Test-Path $srcDir) {
        if (Test-Path $dstDir) {
            # La racine a deja ce dossier (ex : histoires existantes) - on garde la racine
            Remove-Item $srcDir -Recurse -Force
            Log "telmios\$datadir supprime (racine\$datadir deja presente - donnees preservees)"
        } else {
            Move-Item $srcDir $dstDir -Force
            Log "Deplace telmios\$datadir -> racine\$datadir"
            Write-Host "  [Telmi-Sync] telmios\$datadir\ -> \$datadir\" -ForegroundColor Gray
        }
    }
}
# S'assurer que Saves/.parameters existe (Telmi-Sync en a besoin pour detecter la carte)
if (-not (Test-Path "$SD\Saves")) { New-Item -ItemType Directory -Force -Path "$SD\Saves" | Out-Null }
if (-not (Test-Path "$SD\Saves\.parameters")) {
    Set-Content -Path "$SD\Saves\.parameters" -Value "{}" -Encoding ASCII -NoNewline
    Log "Saves\.parameters cree (defaut)"
    Write-Host "  [Telmi-Sync] Saves\.parameters cree" -ForegroundColor Gray
}
Log "Telmi-Sync prep terminee"

# =============================================================
Write-Host ""
Write-Host "$($L.step7_pre) $SD\onion\..." -ForegroundColor Yellow
Write-Host $L.slowMinutes -ForegroundColor Gray
Log "--- ETAPE 7 : OnionOS ---"
if (Test-Path "$SD\onion") {
    Log "Suppression ancien $SD\onion"
    Remove-Item "$SD\onion" -Recurse -Force
}
Log "Copie OnionOS : $SRC_ONION -> $SD\onion"
Copy-Item "$SRC_ONION" "$SD\onion" -Recurse -Force
$onionCount = (Get-ChildItem "$SD\onion" -Recurse -File).Count
Log "OnionOS copie : $onionCount fichiers"
Write-Host "  OnionOS\ -> $SD\onion\" -ForegroundColor Gray
Write-Host "  OK" -ForegroundColor Green

# =============================================================
Write-Host ""
Write-Host $L.step8 -ForegroundColor Yellow
Log "--- ETAPE 8 : Images menu ---"
$pythonScript = "$SCRIPT_DIR\generate_bootmenu.py"
if (-not (Test-Path $pythonScript)) {
    Log "generate_bootmenu.py introuvable dans $SCRIPT_DIR" "WARN"
    Write-Host "  [IGNORE] generate_bootmenu.py introuvable dans $SCRIPT_DIR" -ForegroundColor Yellow
} else {
    $pythonCmd = $null
    foreach ($cmd in @("python", "python3")) {
        try {
            $ver = & $cmd --version 2>&1
            if ($LASTEXITCODE -eq 0) { $pythonCmd = $cmd; Log "Python trouve : $cmd ($ver)"; break }
        } catch {}
    }
    if (-not $pythonCmd) {
        Log "Python non trouve sur le systeme" "WARN"
        Write-Host "  [IGNORE] Python non trouve. Installe Python 3 puis lance generate_bootmenu.py" -ForegroundColor Yellow
    } else {
        # Verifier la compatibilite de la version Python avec Pillow
        $pyVerStr = & $pythonCmd --version 2>&1
        $pyVerMatch = [regex]::Match($pyVerStr, 'Python (\d+)\.(\d+)')
        $pyTooNew = $false
        if ($pyVerMatch.Success) {
            $pyMaj = [int]$pyVerMatch.Groups[1].Value
            $pyMin = [int]$pyVerMatch.Groups[2].Value
            if ($pyMaj -gt 3 -or ($pyMaj -eq 3 -and $pyMin -ge 14)) {
                $pyTooNew = $true
                Log "Python $pyMaj.$pyMin detecte - Pillow n'a pas de wheel pour cette version (necessite Python <= 3.13)" "WARN"
                Write-Host "  [AVERT] Python $pyMaj.$pyMin est trop recent pour Pillow." -ForegroundColor Yellow
                Write-Host "  Installe Python 3.11 ou 3.12 depuis python.org pour generer les images." -ForegroundColor Yellow
                Write-Host "  L'installation continue - les images seront absentes (ecran noir au boot)." -ForegroundColor Yellow
            }
        }

        if (-not $pyTooNew) {
            Write-Host "  Verification de Pillow..." -ForegroundColor Gray
            $pillowCheck = & $pythonCmd -c "import PIL" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Log "Pillow absent - installation (wheel uniquement, pas de compilation source)..."
                Write-Host "  Installation de Pillow..." -ForegroundColor Gray
                # --only-binary=:all: evite la compilation source qui bloque indefiniment
                $pipOut = & $pythonCmd -m pip install Pillow --only-binary=:all: --quiet 2>&1
                Log "pip output : $($pipOut -join ' | ')"
                if ($LASTEXITCODE -ne 0) {
                    Log "Pillow introuvable pour cette version Python - images non generees" "WARN"
                    Write-Host "  [AVERT] Pillow indisponible pour $pyVerStr - images non generees." -ForegroundColor Yellow
                    $pyTooNew = $true
                }
            } else {
                Log "Pillow deja installe"
            }
        }

        if (-not $pyTooNew) {
            Write-Host "  Generation des images RAW (FR/EN/ES)..." -ForegroundColor Gray
            Log "Lancement generate_bootmenu.py $SD"
            $pyOut = & $pythonCmd $pythonScript $SD 2>&1
            Log "generate_bootmenu output : $($pyOut -join ' | ')"
            if ($LASTEXITCODE -eq 0) {
                Log "Images generees avec succes"
                Write-Host "  OK - Images generees" -ForegroundColor Green
            } else {
                Log "ERREUR generation images (code $LASTEXITCODE)" "ERROR"
                Write-Host "  ERREUR lors de la generation des images" -ForegroundColor Red
            }
        }
    }
}

# =============================================================
Write-Host ""
Write-Host $L.verif -ForegroundColor Yellow
Log "--- VERIFICATION FINALE ---"

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
        Log "OK : $check"
        Write-Host "  [OK] $check" -ForegroundColor Green
    } else {
        Log "MANQUANT : $check" "ERROR"
        Write-Host "  [MANQUANT] $check" -ForegroundColor Red
        $errors++
    }
}

if ((Test-Path "$SD\onion\miyoo\app\.tmp_update\install.sh") -or (Test-Path "$SD\onion\.tmp_update\runtime.sh")) {
    Log "OK : onion/ pret"
    Write-Host "  [OK] $SD\onion\ (OnionOS pret)" -ForegroundColor Green
} else {
    Log "MANQUANT : onion/ absent ou incomplet" "ERROR"
    Write-Host "  [MANQUANT] $SD\onion\ - dossier OnionOS absent ou incomplet" -ForegroundColor Red
    $errors++
}

$hasImages = (Test-Path "$SD\.tmp_update\res\bootmenu_onion_FR.raw") -or (Test-Path "$SD\.tmp_update\res\bootmenu_onion.raw")
if ($hasImages) {
    Log "OK : images menu presentes"
    Write-Host "  [OK] Images menu .raw presentes" -ForegroundColor Green
} else {
    Log "MANQUANT : images menu .raw" "WARN"
    Write-Host "  [MANQUANT] Images menu .raw - lance generate_bootmenu.py avec la SD inseree" -ForegroundColor Yellow
}

# =============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($errors -eq 0) {
    Log "=== INSTALLATION REUSSIE (0 erreur) ==="
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
    Log "=== INSTALLATION INCOMPLETE ($errors erreur(s)) ===" "ERROR"
    Write-Host "  $($L.warning) $errors $($L.missingFiles)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $L.checkFolders
    Write-Host $L.checkSameDir
}
Write-Host ""
Log "Log complet : $LOG_FILE"
Write-Host $L.logSaved -ForegroundColor DarkGray
Write-Host "  $LOG_FILE" -ForegroundColor DarkGray
Write-Host ""
Read-Host $L.pressEnter
