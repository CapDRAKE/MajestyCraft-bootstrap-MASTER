#!/bin/bash
set -e

PROJECT="AlternativeAPI-bootstrap-master"
SRC="$PROJECT/src"
LIB="$PROJECT/lib"
BUILD="build_tmp"
DIST="dist"
OUTPUT="$DIST/bootstrap.jar"

echo ""
echo "  ==================================="
echo "    MajestyCraft Bootstrap - Build"
echo "  ==================================="
echo ""

# Clean previous build
rm -rf "$BUILD"
mkdir -p "$BUILD/classes"
mkdir -p "$DIST"

# Build classpath from lib/*.jar
CP=""
for jar in "$LIB"/*.jar; do
    if [ -z "$CP" ]; then
        CP="$jar"
    else
        CP="$CP:$jar"
    fi
done

# Compile Java sources
echo "  [1/4] Compilation des sources..."
javac -source 1.8 -target 1.8 -encoding ISO-8859-1 -cp "$CP" -d "$BUILD/classes" -sourcepath "$SRC" \
    "$SRC/fr/trxyy/alternative/bootstrap/Home.java" \
    "$SRC/fr/trxyy/alternative/bootstrap/BootPanel.java" \
    "$SRC/fr/trxyy/alternative/bootstrap/BootstrapConstants.java" \
    "$SRC/fr/trxyy/alternative/bootstrap/Downloader.java" \
    "$SRC/fr/trxyy/alternative/bootstrap/ui/JCircleProgressBar.java" \
    "$SRC/fr/trxyy/alternative/bootstrap/ui/ProgressCircleUI.java"

# Extract all lib JARs into build dir (fat JAR)
echo "  [2/4] Integration des dependances..."
cd "$BUILD/classes"
for jar in "../../$LIB"/*.jar; do
    jar -xf "$jar" 2>/dev/null || true
done
# Remove META-INF signatures from dependencies
rm -f META-INF/*.SF META-INF/*.DSA META-INF/*.RSA 2>/dev/null || true
cd ../..

# Copy resources
echo "  [3/4] Copie des ressources..."
cp -r "$SRC/resources" "$BUILD/classes/"

# Create manifest
echo "Main-Class: fr.trxyy.alternative.bootstrap.Home" > "$BUILD/MANIFEST.MF"

# Create fat JAR
echo "  [4/4] Creation du JAR..."
jar cfm "$OUTPUT" "$BUILD/MANIFEST.MF" -C "$BUILD/classes" .

# Clean build temp
rm -rf "$BUILD"

echo ""
echo "  Build termine: $OUTPUT"
echo "  Vous pouvez maintenant lancer MajestyLauncher.sh"
echo ""
