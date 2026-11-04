@echo off
:: Cree un raccourci "MajestyCraft Setup.lnk" avec l'icone dragon
:: a cote de MajestyLauncher.bat pour la distribution

set "SCRIPT_DIR=%~dp0"
set "ICO=C:\MajestyCraftIcon\MajestyCraft.ico"

:: Verifier que l'ico existe
if not exist "%ICO%" (
    echo Icone introuvable: %ICO%
    echo Lancez d'abord FixIcon.bat
    pause
    exit /b 1
)

:: Creer le raccourci par PowerShell (VBScript sera desactive par defaut dans Windows).
:: Les chemins sont lus dans les variables SCRIPT_DIR et ICO de ce script.
powershell -NoProfile -NonInteractive -Command "$ErrorActionPreference = 'Stop'; $s = New-Object -ComObject WScript.Shell; $l = $s.CreateShortcut((Join-Path $env:SCRIPT_DIR 'MajestyCraft Setup.lnk')); $l.TargetPath = (Join-Path $env:SCRIPT_DIR 'MajestyLauncher.bat'); $l.WorkingDirectory = $env:SCRIPT_DIR; $l.IconLocation = $env:ICO + ',0'; $l.Description = 'Installer MajestyCraft'; $l.Save()"
if errorlevel 1 (
    echo Raccourci non cree.
    pause
    exit /b 1
)

echo Raccourci cree : MajestyCraft Setup.lnk
pause
