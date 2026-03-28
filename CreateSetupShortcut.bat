@echo off
:: Cree un raccourci "MajestyCraft Setup.lnk" avec l'icone dragon
:: a cote de MajestyLauncher.bat pour la distribution

set "SCRIPT_DIR=%~dp0"
set "ICO=C:\MajestyCraftIcon\MajestyCraft.ico"
set "VBS=%TEMP%\mksetuplnk.vbs"

:: Verifier que l'ico existe
if not exist "%ICO%" (
    echo Icone introuvable: %ICO%
    echo Lancez d'abord FixIcon.bat
    pause
    exit /b 1
)

:: Creer le raccourci via VBS
> "%VBS%" echo Set ws = CreateObject("WScript.Shell")
>> "%VBS%" echo Set lnk = ws.CreateShortcut("%SCRIPT_DIR%MajestyCraft Setup.lnk")
>> "%VBS%" echo lnk.TargetPath = "%SCRIPT_DIR%MajestyLauncher.bat"
>> "%VBS%" echo lnk.WorkingDirectory = "%SCRIPT_DIR%"
>> "%VBS%" echo lnk.IconLocation = "%ICO%,0"
>> "%VBS%" echo lnk.Description = "Installer MajestyCraft"
>> "%VBS%" echo lnk.Save
cscript //nologo "%VBS%"
del "%VBS%" 2>nul

echo Raccourci cree : MajestyCraft Setup.lnk
pause
