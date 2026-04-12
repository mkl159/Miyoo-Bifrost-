@echo off
:: =====================================================================
::  Miyoo Bifrost - Build EXE Installer
::  Compile INSTALLER_BIFROST.cs -> INSTALLER_BIFROST.exe
::  Requires: .NET Framework 4.x (pre-installed on Windows 7/8/10/11)
:: =====================================================================

echo.
echo =====================================================
echo   Miyoo Bifrost - Build EXE Installer
echo =====================================================
echo.

:: --- Find csc.exe from .NET Framework ---
set "CSC="

:: 64-bit .NET Framework (prefer)
if exist "%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe" (
    set "CSC=%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    goto :found
)
:: 32-bit fallback
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe" (
    set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    goto :found
)

echo [ERREUR] csc.exe introuvable.
echo   .NET Framework 4.x est requis (pre-installe sur Windows 7/8/10/11).
echo   Telecharge sur : https://dotnet.microsoft.com/download/dotnet-framework
echo.
pause
exit /b 1

:found
echo Compilateur : %CSC%
echo.

:: --- Compile ---
set "ICON_FLAG="
if exist "%~dp0bifrost.ico" set "ICON_FLAG=/win32icon:%~dp0bifrost.ico"

"%CSC%" ^
    /target:winexe ^
    /out:INSTALLER_BIFROST.exe ^
    /platform:anycpu ^
    /optimize+ ^
    /r:System.dll ^
    /r:System.Windows.Forms.dll ^
    /r:System.Drawing.dll ^
    %ICON_FLAG% ^
    INSTALLER_BIFROST.cs

if %ERRORLEVEL% == 0 (
    echo.
    echo =====================================================
    echo   BUILD REUSSI : INSTALLER_BIFROST.exe
    echo =====================================================
    echo.
    echo   Lance INSTALLER_BIFROST.exe pour installer Bifrost.
    echo   (Double-clic ou clic droit "Executer en tant qu'admin")
    echo.
) else (
    echo.
    echo =====================================================
    echo   ECHEC DE LA COMPILATION  (code %ERRORLEVEL%)
    echo =====================================================
    echo.
    echo   Verifie que INSTALLER_BIFROST.cs est dans le meme
    echo   dossier que ce fichier BUILD_EXE.bat.
    echo.
)

pause
