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
set "LAUNCHER_VBS=%INSTALL_DIR%\MajestyLauncher.vbs"
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

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: --- Etape 1 : Java ---
if exist "%JAVA%" goto :java_ok

echo   [1/4] Telechargement de Java 8...
echo         Cela peut prendre quelques minutes.
echo.
curl -L -# -o "%INSTALL_DIR%\jre.zip" "%JRE_URL%"
if errorlevel 1 goto :err_download

echo.
echo   [2/4] Extraction de Java...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%INSTALL_DIR%\jre.zip' -DestinationPath '%INSTALL_DIR%' -Force" 2>nul

for /d %%i in ("%INSTALL_DIR%\zulu*") do (
    if exist "%%i\bin\javaw.exe" ren "%%i" "jre"
)
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

:: Creer le lanceur VBS (silencieux, pas de fenetre console)
echo Set ws = CreateObject("WScript.Shell")> "%LAUNCHER_VBS%"
echo ws.CurrentDirectory = "%INSTALL_DIR%">> "%LAUNCHER_VBS%"
echo ws.Run """%JRE_DIR%\bin\javaw.exe"" -jar ""%BOOTSTRAP_JAR%""", 1, False>> "%LAUNCHER_VBS%"

:: Creer le desinstalleur
echo @echo off> "%UNINSTALL_BAT%"
echo title MajestyCraft - Desinstallation>> "%UNINSTALL_BAT%"
echo echo.>> "%UNINSTALL_BAT%"
echo echo   Desinstallation de MajestyCraft...>> "%UNINSTALL_BAT%"
echo echo.>> "%UNINSTALL_BAT%"
echo del "%%USERPROFILE%%\Desktop\MajestyCraft.lnk" 2^>nul>> "%UNINSTALL_BAT%"
echo del "%%AppData%%\Microsoft\Windows\Start Menu\Programs\MajestyCraft.lnk" 2^>nul>> "%UNINSTALL_BAT%"
echo cd /d "%%TEMP%%">> "%UNINSTALL_BAT%"
echo rmdir /s /q "%INSTALL_DIR%" 2^>nul>> "%UNINSTALL_BAT%"
echo rmdir /s /q "C:\ProgramData\MajestyCraft" 2^>nul>> "%UNINSTALL_BAT%"
echo echo   MajestyCraft a ete desinstalle.>> "%UNINSTALL_BAT%"
echo echo.>> "%UNINSTALL_BAT%"
echo pause>> "%UNINSTALL_BAT%"

:: Supprimer ancien raccourci MajestyCraft s'il existe
del "%USERPROFILE%\Desktop\MajestyCraft.lnk" 2>nul
del "%USERPROFILE%\OneDrive\Bureau\MajestyCraft.lnk" 2>nul

:: Creer raccourcis via VBS (plus fiable que PowerShell)
set "SHORTCUT_VBS=%INSTALL_DIR%\shortcut_tmp.vbs"
echo Set ws = CreateObject("WScript.Shell")> "%SHORTCUT_VBS%"
echo Set lnk = ws.CreateShortcut(ws.SpecialFolders("Desktop") ^& "\MajestyLauncher.lnk")>> "%SHORTCUT_VBS%"
echo lnk.TargetPath = "%LAUNCHER_VBS%">> "%SHORTCUT_VBS%"
echo lnk.WorkingDirectory = "%INSTALL_DIR%">> "%SHORTCUT_VBS%"
echo lnk.IconLocation = "%ICON%,0">> "%SHORTCUT_VBS%"
echo lnk.Description = "Lancer MajestyLauncher">> "%SHORTCUT_VBS%"
echo lnk.Save>> "%SHORTCUT_VBS%"
echo Set lnk2 = ws.CreateShortcut(ws.SpecialFolders("Programs") ^& "\MajestyLauncher.lnk")>> "%SHORTCUT_VBS%"
echo lnk2.TargetPath = "%LAUNCHER_VBS%">> "%SHORTCUT_VBS%"
echo lnk2.WorkingDirectory = "%INSTALL_DIR%">> "%SHORTCUT_VBS%"
echo lnk2.IconLocation = "%ICON%,0">> "%SHORTCUT_VBS%"
echo lnk2.Description = "Lancer MajestyCraft">> "%SHORTCUT_VBS%"
echo lnk2.Save>> "%SHORTCUT_VBS%"
cscript //nologo "%SHORTCUT_VBS%" 2>nul
del "%SHORTCUT_VBS%" 2>nul

echo         Raccourcis crees.

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
cd /d "%TEMP%"
rmdir /s /q "%INSTALL_DIR%" 2>nul
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
