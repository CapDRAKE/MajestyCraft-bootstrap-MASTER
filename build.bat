@echo off
setlocal enabledelayedexpansion
title MajestyCraft Bootstrap - Build

set "PROJECT=AlternativeAPI-bootstrap-master"
set "SRC=%PROJECT%\src"
set "LIB=%PROJECT%\lib"
set "BUILD=build_tmp"
set "DIST=dist"
set "OUTPUT=%DIST%\bootstrap.jar"

:: Find JDK bin directory (jar.exe might not be in PATH)
set "JDK_BIN="
for /f "tokens=*" %%p in ('where javac 2^>nul') do (
    if not defined JDK_BIN (
        for %%d in ("%%~dpp..") do set "JDK_BIN=%%~fd\bin"
    )
)
:: If jar not found via javac parent, try common paths
if not exist "%JDK_BIN%\jar.exe" (
    if exist "C:\Program Files\Java\jdk-21\bin\jar.exe" set "JDK_BIN=C:\Program Files\Java\jdk-21\bin"
    if exist "C:\Program Files\Java\jdk1.8.0_202\bin\jar.exe" set "JDK_BIN=C:\Program Files\Java\jdk1.8.0_202\bin"
)
set "JAR=%JDK_BIN%\jar.exe"

echo.
echo   ===================================
echo     MajestyCraft Bootstrap - Build
echo   ===================================
echo.

:: Clean previous build
if exist "%BUILD%" rmdir /s /q "%BUILD%"
mkdir "%BUILD%\classes"
if not exist "%DIST%" mkdir "%DIST%"

:: Build classpath from lib/*.jar
set "CP="
for %%f in ("%LIB%\*.jar") do (
    if defined CP (
        set "CP=!CP!;%%f"
    ) else (
        set "CP=%%f"
    )
)

:: Compile Java sources
echo   [1/4] Compilation des sources...
javac -source 1.8 -target 1.8 -encoding ISO-8859-1 -cp "%CP%" -d "%BUILD%\classes" -sourcepath "%SRC%" "%SRC%\fr\trxyy\alternative\bootstrap\Home.java" "%SRC%\fr\trxyy\alternative\bootstrap\BootPanel.java" "%SRC%\fr\trxyy\alternative\bootstrap\BootstrapConstants.java" "%SRC%\fr\trxyy\alternative\bootstrap\Downloader.java" "%SRC%\fr\trxyy\alternative\bootstrap\ui\JCircleProgressBar.java" "%SRC%\fr\trxyy\alternative\bootstrap\ui\ProgressCircleUI.java"
if errorlevel 1 (
    echo   ERREUR: La compilation a echoue.
    pause
    exit /b 1
)

:: Extract all lib JARs into build dir (fat JAR)
echo   [2/4] Integration des dependances...
pushd "%BUILD%\classes"
for %%f in ("..\..\%LIB%\*.jar") do (
    "%JAR%" -xf "%%f" 2>nul
)
:: Remove META-INF signatures from dependencies (avoid conflicts)
if exist "META-INF\*.SF" del /q "META-INF\*.SF" 2>nul
if exist "META-INF\*.DSA" del /q "META-INF\*.DSA" 2>nul
if exist "META-INF\*.RSA" del /q "META-INF\*.RSA" 2>nul
popd

:: Copy resources
echo   [3/4] Copie des ressources...
xcopy /s /y /i "%SRC%\resources" "%BUILD%\classes\resources\" >nul 2>nul

:: Create manifest
echo Main-Class: fr.trxyy.alternative.bootstrap.Home> "%BUILD%\MANIFEST.MF"

:: Create fat JAR
echo   [4/4] Creation du JAR...
"%JAR%" cfm "%OUTPUT%" "%BUILD%\MANIFEST.MF" -C "%BUILD%\classes" .
if errorlevel 1 (
    echo   ERREUR: La creation du JAR a echoue.
    pause
    exit /b 1
)

:: Clean build temp
rmdir /s /q "%BUILD%"

echo.
echo   Build termine: %OUTPUT%
echo   Vous pouvez maintenant lancer MajestyLauncher.bat
echo.
pause
