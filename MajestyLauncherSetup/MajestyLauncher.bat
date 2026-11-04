@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>nul
title MajestyLauncher - Setup

:: ===================================
::   Configuration
:: ===================================
set "INSTALL_DIR=%LocalAppData%\MajestyCraft"
set "JRE_DIR=%INSTALL_DIR%\jre"
set "BOOTSTRAP_JAR=%INSTALL_DIR%\bootstrap.jar"
set "OLD_VBS=%INSTALL_DIR%\MajestyLauncher.vbs"
set "UNINSTALL_BAT=%INSTALL_DIR%\Uninstall.bat"
set "JAVA=%JRE_DIR%\bin\javaw.exe"
set "JRE_URL=https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-fx-jre8.0.482-win_x64.zip"
set "SCRIPT_DIR=%~dp0"

:: ===================================
::   Si deja installe, proposer les options
:: ===================================
if exist "%JAVA%" if exist "%BOOTSTRAP_JAR%" goto :menu

goto :install

:: ===================================
::   MENU
:: ===================================
:menu
cls
echo.
echo   ========================================
echo            MajestyLauncher
echo   ========================================
echo.
echo   [1] Lancer MajestyLauncher
echo   [2] Reparer l'installation
echo   [3] Desinstaller
echo   [4] Quitter
echo.
set /p "CHOICE=  Votre choix : "

if "%CHOICE%"=="1" goto :launch
if "%CHOICE%"=="2" goto :repair
if "%CHOICE%"=="3" goto :uninstall_prompt
if "%CHOICE%"=="4" exit /b 0
goto :menu

:: ===================================
::   INSTALLATION
:: ===================================
:install
cls
echo.
echo   ========================================
echo          MajestyLauncher - Setup
echo   ========================================
echo.
echo   Bienvenue dans l'installateur
echo   de MajestyLauncher !
echo.
echo   Ce programme va installer :
echo   - Java 8 portable
echo   - MajestyLauncher Bootstrap
echo.
echo   Emplacement :
echo   %INSTALL_DIR%
echo.
set /p "CONFIRM=  Installer MajestyLauncher ? [O/N] : "
if /i not "%CONFIRM%"=="O" goto :cancel

echo.
echo   -------------------------------------------
echo     Installation en cours...
echo   -------------------------------------------
echo.

:: Ferme un eventuel MajestyLauncher/bootstrap deja lance depuis cette
:: installation : sinon le java.exe encore actif garde les fichiers du JRE
:: ouverts et toute tentative de reinstallation/reparation echoue (rmdir,
:: ren, robocopy... rien ne peut remplacer un fichier utilise par un
:: processus en cours).
powershell -NoProfile -Command "Get-Process -Name java,javaw -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith('%INSTALL_DIR%', [System.StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue" 2>nul
timeout /t 1 /nobreak >nul

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: --- Etape 1 : Java ---
if exist "%JAVA%" goto :java_ok

echo   [1/4] Telechargement de Java 8...
echo         Cela peut prendre quelques minutes.
echo.

:: Nettoyage d'une precedente tentative interrompue. On utilise un dossier
:: d'extraction temporaire a part (jre_tmp) pour ne jamais avoir a renommer
:: par-dessus %JRE_DIR% : "rmdir /s /q" ne se termine pas toujours de facon
:: synchrone sur de gros dossiers (antivirus, etc.), et un "ren" juste apres
:: peut alors echouer avec "le nom de fichier existe deja" meme si la
:: suppression a ete lancee. robocopy /MOVE est beaucoup plus robuste
:: (retries integres) qu'un simple "ren"/"move" pour deplacer le contenu.
if exist "%INSTALL_DIR%\jre_tmp" rmdir /s /q "%INSTALL_DIR%\jre_tmp" 2>nul
del "%INSTALL_DIR%\jre.zip" 2>nul

curl -L -# -o "%INSTALL_DIR%\jre.zip" "%JRE_URL%"
if errorlevel 1 goto :err_download

echo.
echo   [2/4] Extraction de Java...
mkdir "%INSTALL_DIR%\jre_tmp" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%INSTALL_DIR%\jre.zip' -DestinationPath '%INSTALL_DIR%\jre_tmp' -Force" 2>nul

if exist "%JRE_DIR%" rmdir /s /q "%JRE_DIR%" 2>nul
mkdir "%JRE_DIR%" 2>nul

for /d %%i in ("%INSTALL_DIR%\jre_tmp\zulu*") do (
    if exist "%%i\bin\javaw.exe" (
        robocopy "%%i" "%JRE_DIR%" /E /MOVE /NFL /NDL /NJH /NJS /R:5 /W:1 >nul
    )
)

rmdir /s /q "%INSTALL_DIR%\jre_tmp" 2>nul
del "%INSTALL_DIR%\jre.zip" 2>nul

if not exist "%JAVA%" goto :err_extract
echo         Java installe.
echo.
goto :bootstrap

:java_ok
echo   [1/4] Java deja present.
echo   [2/4] Java deja present.
echo.

:: --- Etape 2 : Bootstrap ---
:bootstrap
echo   [3/4] Installation du bootstrap...
if exist "%SCRIPT_DIR%dist\bootstrap.jar" (
    copy /y "%SCRIPT_DIR%dist\bootstrap.jar" "%BOOTSTRAP_JAR%" >nul
    goto :bootstrap_ok
)
if exist "%SCRIPT_DIR%bootstrap.jar" (
    copy /y "%SCRIPT_DIR%bootstrap.jar" "%BOOTSTRAP_JAR%" >nul
    goto :bootstrap_ok
)
goto :err_nojar

:bootstrap_ok
echo         Bootstrap installe.
echo.

:: --- Etape 3 : Icone & Raccourcis ---
echo   [4/4] Creation des raccourcis...

:: Copier l'icone (dans ProgramData pour eviter les problemes de chemin %USERPROFILE%)
set "ICON_DIR=C:\ProgramData\MajestyCraft"
set "ICON=%ICON_DIR%\MajestyCraft.ico"
if not exist "%ICON_DIR%" mkdir "%ICON_DIR%"
if exist "%SCRIPT_DIR%AlternativeAPI-bootstrap-master\src\resources\MajestyCraft.ico" (
    copy /y "%SCRIPT_DIR%AlternativeAPI-bootstrap-master\src\resources\MajestyCraft.ico" "%ICON%" >nul
) else if exist "%SCRIPT_DIR%MajestyCraft.ico" (
    copy /y "%SCRIPT_DIR%MajestyCraft.ico" "%ICON%" >nul
)

:: Les raccourcis lancent directement javaw.exe (signe par Azul, sans fenetre
:: console). L'ancien lanceur MajestyLauncher.vbs ne sert plus : Microsoft
:: desactivera VBScript par defaut dans Windows (annonce pour 2027 environ).
del "%OLD_VBS%" 2>nul

:: Creer le desinstalleur
echo @echo off> "%UNINSTALL_BAT%"
:: Les chemins sont ecrits en UTF-8 (chcp 65001 plus haut) : le desinstalleur doit
:: les relire de meme, sinon un nom d'utilisateur accentue devient introuvable.
echo chcp 65001 ^>nul>> "%UNINSTALL_BAT%"
echo title MajestyCraft - Desinstallation>> "%UNINSTALL_BAT%"
echo echo.>> "%UNINSTALL_BAT%"
echo echo   Desinstallation de MajestyCraft...>> "%UNINSTALL_BAT%"
echo echo.>> "%UNINSTALL_BAT%"
echo del "%%USERPROFILE%%\Desktop\MajestyCraft.lnk" 2^>nul>> "%UNINSTALL_BAT%"
echo del "%%AppData%%\Microsoft\Windows\Start Menu\Programs\MajestyCraft.lnk" 2^>nul>> "%UNINSTALL_BAT%"
echo powershell -NoProfile -NonInteractive -Command "foreach ($n in 'Desktop','Programs') { $f = [Environment]::GetFolderPath($n); if ($f) { Remove-Item -LiteralPath (Join-Path $f 'MajestyLauncher.lnk') -ErrorAction SilentlyContinue } }" 2^>nul>> "%UNINSTALL_BAT%"
echo cd /d "%%TEMP%%">> "%UNINSTALL_BAT%"
echo rmdir /s /q "C:\ProgramData\MajestyCraft" 2^>nul>> "%UNINSTALL_BAT%"
:: Derniere ligne d'un seul tenant : le desinstalleur est dans le dossier qu'il
:: supprime, cmd ne pourrait plus lire les lignes suivantes.
echo rmdir /s /q "%INSTALL_DIR%" 2^>nul ^& echo   MajestyCraft a ete desinstalle. ^& echo. ^& pause>> "%UNINSTALL_BAT%"

:: Supprimer ancien raccourci MajestyCraft s'il existe
del "%USERPROFILE%\Desktop\MajestyCraft.lnk" 2>nul
del "%USERPROFILE%\OneDrive\Bureau\MajestyCraft.lnk" 2>nul

:: Raccourcis Bureau et menu Demarrer, crees par PowerShell. Les chemins sont lus
:: dans les variables de ce script (JAVA, BOOTSTRAP_JAR, INSTALL_DIR, ICON) au lieu
:: d'etre recopies dans un fichier : un nom d'utilisateur avec accents ou apostrophe
:: reste intact, et Windows donne lui-meme le Bureau, meme deplace dans OneDrive.
powershell -NoProfile -NonInteractive -Command "$ErrorActionPreference = 'Stop'; $q = [char]34; $s = New-Object -ComObject WScript.Shell; foreach ($n in 'Desktop','Programs') { $f = [Environment]::GetFolderPath($n); if (-not $f) { continue }; $l = $s.CreateShortcut((Join-Path $f 'MajestyLauncher.lnk')); $l.TargetPath = $env:JAVA; $l.Arguments = '-jar ' + $q + $env:BOOTSTRAP_JAR + $q; $l.WorkingDirectory = $env:INSTALL_DIR; $l.IconLocation = $env:ICON + ',0'; $l.Description = 'Lancer MajestyLauncher'; $l.Save() }"
if errorlevel 1 (
    echo         Attention : raccourcis non crees.
    echo         Relancez ce script et choisissez [1] pour jouer.
) else (
    echo         Raccourcis crees.
)

:: --- Ecran de fin ---
cls
echo.
echo   ========================================
echo     Installation terminee !
echo   ========================================
echo.
echo   MajestyCraft a ete installe dans :
echo   %INSTALL_DIR%
echo.
echo   Raccourcis crees :
echo   - Bureau
echo   - Menu Demarrer
echo.
echo   MajestyCraft va se lancer...
echo.
ping -n 5 127.0.0.1 >nul
goto :launch

:: ===================================
::   REPARATION
:: ===================================
:repair
cls
echo.
echo   Reparation de l'installation...
echo.
if exist "%JRE_DIR%" rmdir /s /q "%JRE_DIR%"
if exist "%BOOTSTRAP_JAR%" del /q "%BOOTSTRAP_JAR%"
goto :install

:: ===================================
::   DESINSTALLATION
:: ===================================
:uninstall_prompt
cls
echo.
echo   ========================================
echo     Desinstaller MajestyCraft ?
echo   ========================================
echo.
echo   Cela supprimera :
echo   - Java 8 portable
echo   - Le bootstrap
echo   - Les raccourcis
echo.
echo   Vos donnees Minecraft ne seront
echo   PAS supprimees.
echo.
set /p "CONFIRM_UNINST=  Confirmer ? [O/N] : "
if /i not "%CONFIRM_UNINST%"=="O" goto :menu

echo.
echo   Desinstallation en cours...
del "%USERPROFILE%\Desktop\MajestyLauncher.lnk" 2>nul
del "%AppData%\Microsoft\Windows\Start Menu\Programs\MajestyLauncher.lnk" 2>nul
powershell -NoProfile -NonInteractive -Command "foreach ($n in 'Desktop','Programs') { $f = [Environment]::GetFolderPath($n); if ($f) { Remove-Item -LiteralPath (Join-Path $f 'MajestyLauncher.lnk') -ErrorAction SilentlyContinue } }" 2>nul
cd /d "%TEMP%"
rmdir /s /q "%INSTALL_DIR%" 2>nul
rmdir /s /q "C:\ProgramData\MajestyCraft" 2>nul
echo.
echo   MajestyCraft a ete desinstalle avec succes.
echo.
pause
exit /b 0

:: ===================================
::   LANCEMENT
:: ===================================
:launch
cd /d "%INSTALL_DIR%"
start "" "%JAVA%" -jar "%BOOTSTRAP_JAR%"
exit /b 0

:: ===================================
::   ERREURS
:: ===================================
:cancel
echo.
echo   Installation annulee.
ping -n 3 127.0.0.1 >nul
exit /b 0

:err_download
echo.
echo   ERREUR: Impossible de telecharger Java.
echo   Verifiez votre connexion internet.
pause
exit /b 1

:err_extract
echo.
echo   ERREUR: L'extraction de Java a echoue.
pause
exit /b 1

:err_nojar
echo.
echo   ERREUR: bootstrap.jar introuvable.
echo   Lancez d'abord build.bat pour compiler le projet,
echo   ou placez bootstrap.jar a cote de ce script.
pause
exit /b 1
