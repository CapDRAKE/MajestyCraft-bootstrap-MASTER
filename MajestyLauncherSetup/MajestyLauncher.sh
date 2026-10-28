#!/usr/bin/env bash
set -euo pipefail

# ===================================
#   Configuration
# ===================================
APP_NAME="MajestyLauncher"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux*)
            PLATFORM="linux"
            INSTALL_DIR="$HOME/.local/share/MajestyCraft"
            ;;
        Darwin*)
            PLATFORM="macos"
            INSTALL_DIR="$HOME/Library/Application Support/MajestyCraft"
            ;;
        *)
            echo "  Systeme non supporte: $OS"
            exit 1
            ;;
    esac

    case "$ARCH" in
        x86_64|amd64)  ARCH_TAG="x64" ;;
        aarch64|arm64) ARCH_TAG="aarch64" ;;
        *)
            echo "  Architecture non supportee: $ARCH"
            exit 1
            ;;
    esac
}

get_jre_url() {
    local base="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-fx-jre8.0.482"
    case "$PLATFORM" in
        linux)
            echo "${base}-linux_${ARCH_TAG}.tar.gz"
            ;;
        macos)
            echo "${base}-macosx_${ARCH_TAG}.tar.gz"
            ;;
    esac
}

JRE_SUBDIR="jre"
BOOTSTRAP_JAR_NAME="bootstrap.jar"

# ===================================
#   Utility
# ===================================
header() {
    clear 2>/dev/null || true
    echo ""
    echo "  ========================================"
    echo "    $1"
    echo "  ========================================"
    echo ""
}

# ===================================
#   Detect platform
# ===================================
detect_platform

JRE_DIR="$INSTALL_DIR/$JRE_SUBDIR"
JAVA="$JRE_DIR/bin/java"
BOOTSTRAP_JAR="$INSTALL_DIR/$BOOTSTRAP_JAR_NAME"

# Le bootstrap relance le launcher avec la commande "java" : sans cela, c'est le
# Java du systeme qui serait pris (souvent absent, ou en 17/21 sans JavaFX).
export PATH="$JRE_DIR/bin:$PATH"

# Chromebook : environnement Linux de ChromeOS (conteneur Crostini)
IS_CHROMEOS=0
if [ "$PLATFORM" = "linux" ] && { [ -e /dev/.cros_milestone ] || [ -d /opt/google/cros-containers ]; }; then
    IS_CHROMEOS=1
fi

# ===================================
#   Dependances systeme (Linux)
# ===================================
# Bibliotheques dont ont besoin Java/JavaFX (fenetre GTK, X11) et Minecraft
# (OpenGL, son). Presentes sur un bureau classique, souvent absentes d'un
# Linux minimal ou de l'environnement Linux d'un Chromebook.
# Debian 13+ a renomme certains paquets (suffixe t64) : on prend le nom disponible.
pkg_name() {
    if command -v apt-cache >/dev/null 2>&1 && apt-cache show "${1}t64" >/dev/null 2>&1; then
        echo "${1}t64"
    else
        echo "$1"
    fi
}

find_missing_packages() {
    MISSING=""
    command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || MISSING="$MISSING curl"
    command -v tar >/dev/null 2>&1 || MISSING="$MISSING tar"
    LDCONFIG="$(command -v ldconfig 2>/dev/null || true)"
    [ -z "$LDCONFIG" ] && [ -x /sbin/ldconfig ] && LDCONFIG=/sbin/ldconfig
    if [ -n "$LDCONFIG" ]; then
        LIBS="$("$LDCONFIG" -p 2>/dev/null || true)"
        echo "$LIBS" | grep -q "libgtk-3.so.0"   || MISSING="$MISSING $(pkg_name libgtk-3-0)"
        echo "$LIBS" | grep -q "libXtst.so.6"    || MISSING="$MISSING libxtst6"
        echo "$LIBS" | grep -q "libXxf86vm.so.1" || MISSING="$MISSING libxxf86vm1"
        echo "$LIBS" | grep -q "libGL.so.1"      || MISSING="$MISSING libgl1"
        echo "$LIBS" | grep -q "libasound.so.2"  || MISSING="$MISSING $(pkg_name libasound2)"
        echo "$LIBS" | grep -q "libpulse.so.0"   || MISSING="$MISSING libpulse0"
    fi
    # Pilotes OpenGL Mesa (GPU virtuel virgl des Chromebooks, ou rendu logiciel) :
    # sans eux, libGL est presente mais aucune fenetre OpenGL ne peut s'ouvrir.
    if command -v dpkg >/dev/null 2>&1 && ! dpkg -s libgl1-mesa-dri >/dev/null 2>&1; then
        MISSING="$MISSING libgl1-mesa-dri"
    fi
    # Anciennes versions (LWJGL 2, Minecraft 1.12 et avant) : xrandr requis (x86_64 seulement)
    if [ "$ARCH_TAG" = "x64" ]; then
        command -v xrandr >/dev/null 2>&1 || MISSING="$MISSING x11-xserver-utils"
    fi
}

install_linux_dependencies() {
    [ "$PLATFORM" = "linux" ] || return 0
    find_missing_packages
    if [ -z "$MISSING" ]; then
        echo "  [0/3] Dependances systeme presentes."
        return 0
    fi
    echo "  [0/3] Paquets systeme manquants :$MISSING"
    if command -v apt-get >/dev/null 2>&1; then
        printf "        Les installer maintenant (sudo) ? [O/n] : "
        read -r DEPS_OK
        if [ "$DEPS_OK" != "n" ] && [ "$DEPS_OK" != "N" ]; then
            # shellcheck disable=SC2086
            if sudo apt-get update && sudo apt-get install -y $MISSING; then
                echo "        Dependances installees."
            else
                echo "        ATTENTION : installation incomplete, le launcher risque de ne pas demarrer."
            fi
        fi
    else
        echo "        Installez-les avec le gestionnaire de paquets de votre distribution"
        echo "        (noms Debian/Ubuntu ci-dessus ; GTK 3, Xtst, Xxf86vm, OpenGL, ALSA, PulseAudio)."
    fi
    echo ""
}

# ===================================
#   If already installed, show menu
# ===================================
if [ -f "$JAVA" ] && [ -f "$BOOTSTRAP_JAR" ]; then
    while true; do
        header "$APP_NAME"
        echo "  [1] Lancer $APP_NAME"
        echo "  [2] Reparer l'installation"
        echo "  [3] Desinstaller"
        echo "  [4] Quitter"
        echo ""
        printf "  Votre choix : "
        read -r CHOICE
        case "$CHOICE" in
            1) exec "$JAVA" -jar "$BOOTSTRAP_JAR" ;;
            2)
                rm -rf "$JRE_DIR" "$BOOTSTRAP_JAR"
                break
                ;;
            3)
                header "Desinstaller MajestyCraft ?"
                echo "  Cela supprimera :"
                echo "  - Java 8 portable"
                echo "  - Le bootstrap"
                echo "  - Les raccourcis"
                echo ""
                echo "  Vos donnees Minecraft ne seront"
                echo "  PAS supprimees."
                echo ""
                printf "  Confirmer ? [o/N] : "
                read -r CONFIRM
                if [ "$CONFIRM" = "o" ] || [ "$CONFIRM" = "O" ]; then
                    # Remove desktop shortcut (Linux)
                    rm -f "$HOME/.local/share/applications/majestylauncher.desktop" 2>/dev/null
                    rm -f "$HOME/Desktop/MajestyLauncher.desktop" "$HOME/Bureau/MajestyLauncher.desktop" 2>/dev/null
                    DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
                    [ -n "$DESKTOP_DIR" ] && rm -f "$DESKTOP_DIR/MajestyLauncher.desktop" 2>/dev/null
                    # Remove macOS app alias
                    rm -rf "$HOME/Applications/MajestyLauncher.app" 2>/dev/null
                    rm -rf "$INSTALL_DIR"
                    echo ""
                    echo "  MajestyCraft a ete desinstalle avec succes."
                    echo ""
                    exit 0
                fi
                ;;
            4) exit 0 ;;
        esac
    done
fi

# ===================================
#   Installation
# ===================================
header "$APP_NAME - Setup"
echo "  Bienvenue dans l'installateur"
echo "  de $APP_NAME !"
echo ""
echo "  Ce programme va installer :"
echo "  - Java 8 portable (Azul Zulu FX)"
echo "  - MajestyLauncher Bootstrap"
echo ""
if [ "$IS_CHROMEOS" = "1" ]; then
    echo "  Systeme detecte : Chromebook ($ARCH_TAG)"
else
    echo "  Systeme detecte : $PLATFORM ($ARCH_TAG)"
fi
if [ "$PLATFORM" = "linux" ] && [ "$ARCH_TAG" = "aarch64" ]; then
    echo "  Processeur ARM : Minecraft 1.19 ou plus recent."
fi
echo "  Emplacement : $INSTALL_DIR"
echo ""
printf "  Installer $APP_NAME ? [o/N] : "
read -r CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    echo ""
    echo "  Installation annulee."
    exit 0
fi

echo ""
echo "  -------------------------------------------"
echo "    Installation en cours..."
echo "  -------------------------------------------"
echo ""

mkdir -p "$INSTALL_DIR"

# --- Step 0: dependances systeme (Linux) ---
install_linux_dependencies

# --- Step 1: Java ---
if [ -f "$JAVA" ]; then
    echo "  [1/3] Java deja present."
else
    JRE_URL="$(get_jre_url)"
    JRE_ARCHIVE="$INSTALL_DIR/jre-download.tar.gz"

    # Nettoyage d'une precedente tentative interrompue (sinon le "mv" plus bas
    # deplace l'archive DANS $JRE_DIR au lieu de la renommer)
    rm -rf "$JRE_DIR" "$INSTALL_DIR/jre_tmp" "$JRE_ARCHIVE"

    echo "  [1/3] Telechargement de Java 8..."
    echo "        $JRE_URL"
    echo "        Cela peut prendre quelques minutes."
    echo ""

    if command -v curl &>/dev/null; then
        curl -L --progress-bar -o "$JRE_ARCHIVE" "$JRE_URL"
    elif command -v wget &>/dev/null; then
        wget --show-progress -O "$JRE_ARCHIVE" "$JRE_URL"
    else
        echo "  ERREUR: curl ou wget requis."
        exit 1
    fi

    echo ""
    echo "  [2/3] Extraction de Java..."

    mkdir -p "$INSTALL_DIR/jre_tmp"
    tar -xzf "$JRE_ARCHIVE" -C "$INSTALL_DIR/jre_tmp"

    # Find extracted Zulu directory and rename to jre
    ZULU_DIR=$(find "$INSTALL_DIR/jre_tmp" -maxdepth 1 -type d -name "zulu*" | head -1)
    if [ -z "$ZULU_DIR" ]; then
        echo "  ERREUR: Extraction de Java echouee."
        rm -rf "$INSTALL_DIR/jre_tmp" "$JRE_ARCHIVE"
        exit 1
    fi

    # On macOS, the JRE is inside <archive>/zulu-8.jre/Contents/Home
    JRE_HOME_SRC=""
    if [ "$PLATFORM" = "macos" ]; then
        JRE_HOME_SRC="$(find "$ZULU_DIR" -maxdepth 3 -type d -path "*/Contents/Home" | head -1)"
    fi
    if [ -n "$JRE_HOME_SRC" ]; then
        mv "$JRE_HOME_SRC" "$JRE_DIR"
    else
        mv "$ZULU_DIR" "$JRE_DIR"
    fi

    rm -rf "$INSTALL_DIR/jre_tmp" "$JRE_ARCHIVE"

    if [ ! -f "$JAVA" ]; then
        echo "  ERREUR: Java introuvable apres extraction."
        exit 1
    fi

    chmod +x "$JAVA"
    echo "        Java installe."
fi

echo ""

# --- Step 2: Bootstrap ---
echo "  [2/3] Installation du bootstrap..."
FOUND_JAR=""
if [ -f "$SCRIPT_DIR/dist/bootstrap.jar" ]; then
    FOUND_JAR="$SCRIPT_DIR/dist/bootstrap.jar"
elif [ -f "$SCRIPT_DIR/bootstrap.jar" ]; then
    FOUND_JAR="$SCRIPT_DIR/bootstrap.jar"
fi

if [ -z "$FOUND_JAR" ]; then
    echo ""
    echo "  ERREUR: bootstrap.jar introuvable."
    echo "  Lancez d'abord build.sh pour compiler le projet,"
    echo "  ou placez bootstrap.jar a cote de ce script."
    exit 1
fi

cp "$FOUND_JAR" "$BOOTSTRAP_JAR"
echo "        Bootstrap installe."
echo ""

# --- Step 3: Shortcuts ---
echo "  [3/3] Creation des raccourcis..."

# Create launcher script
LAUNCHER_SH="$INSTALL_DIR/launch.sh"
cat > "$LAUNCHER_SH" << LAUNCHER_EOF
#!/usr/bin/env bash
cd "\$(dirname "\$0")"
export PATH="$JRE_DIR/bin:\$PATH"
exec "$JRE_DIR/bin/java" -jar "$BOOTSTRAP_JAR"
LAUNCHER_EOF
chmod +x "$LAUNCHER_SH"

if [ "$PLATFORM" = "linux" ]; then
    # Copy icon for .desktop file
    ICON_SRC=""
    if [ -f "$SCRIPT_DIR/AlternativeAPI-bootstrap-master/src/resources/majestycraft.png" ]; then
        ICON_SRC="$SCRIPT_DIR/AlternativeAPI-bootstrap-master/src/resources/majestycraft.png"
    elif [ -f "$SCRIPT_DIR/majestycraft.png" ]; then
        ICON_SRC="$SCRIPT_DIR/majestycraft.png"
    fi

    ICON_DEST="$INSTALL_DIR/icon.png"
    if [ -n "$ICON_SRC" ]; then
        cp "$ICON_SRC" "$ICON_DEST"
    fi

    # Create .desktop file
    DESKTOP_FILE="$HOME/.local/share/applications/majestylauncher.desktop"
    mkdir -p "$HOME/.local/share/applications"
    cat > "$DESKTOP_FILE" << DESKTOP_EOF
[Desktop Entry]
Type=Application
Name=MajestyLauncher
Comment=Launcher Minecraft francais
Exec=$LAUNCHER_SH
Icon=$ICON_DEST
Terminal=false
Categories=Game;
DESKTOP_EOF
    chmod +x "$DESKTOP_FILE"

    # Copy to Desktop (dossier Bureau reel, quelle que soit la langue)
    DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
    if [ -z "$DESKTOP_DIR" ] || [ ! -d "$DESKTOP_DIR" ]; then
        if [ -d "$HOME/Desktop" ]; then DESKTOP_DIR="$HOME/Desktop"
        elif [ -d "$HOME/Bureau" ]; then DESKTOP_DIR="$HOME/Bureau"
        else DESKTOP_DIR=""
        fi
    fi
    if [ -n "$DESKTOP_DIR" ]; then
        cp "$DESKTOP_FILE" "$DESKTOP_DIR/MajestyLauncher.desktop"
        chmod +x "$DESKTOP_DIR/MajestyLauncher.desktop"
        # GNOME : sans cela, le raccourci demande « Autoriser le lancement »
        gio set "$DESKTOP_DIR/MajestyLauncher.desktop" metadata::trusted true 2>/dev/null || true
    fi

    if [ "$IS_CHROMEOS" = "1" ]; then
        echo "        Raccourci ajoute au lanceur ChromeOS (dossier « Applications Linux »)."
    else
        echo "        Raccourcis crees (menu applications + bureau)."
    fi

elif [ "$PLATFORM" = "macos" ]; then
    # Create a minimal .app bundle
    APP_DIR="$HOME/Applications/MajestyLauncher.app"
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"

    # Copy icon if available
    if [ -f "$SCRIPT_DIR/AlternativeAPI-bootstrap-master/src/resources/majestycraft.png" ]; then
        cp "$SCRIPT_DIR/AlternativeAPI-bootstrap-master/src/resources/majestycraft.png" "$APP_DIR/Contents/Resources/icon.png"
    fi

    # Create executable
    cat > "$APP_DIR/Contents/MacOS/MajestyLauncher" << MACOS_EOF
#!/usr/bin/env bash
cd "$INSTALL_DIR"
export PATH="$JRE_DIR/bin:\$PATH"
exec "$JRE_DIR/bin/java" -jar "$BOOTSTRAP_JAR"
MACOS_EOF
    chmod +x "$APP_DIR/Contents/MacOS/MajestyLauncher"

    # Create Info.plist
    cat > "$APP_DIR/Contents/Info.plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MajestyLauncher</string>
    <key>CFBundleDisplayName</key>
    <string>MajestyLauncher</string>
    <key>CFBundleIdentifier</key>
    <string>com.majestycraft.launcher</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>MajestyLauncher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
PLIST_EOF

    echo "        Application creee dans ~/Applications/MajestyLauncher.app"
fi

# ===================================
#   Done
# ===================================
header "Installation terminee !"
echo "  $APP_NAME a ete installe dans :"
echo "  $INSTALL_DIR"
echo ""
if [ "$IS_CHROMEOS" = "1" ]; then
    echo "  Raccourci : lanceur ChromeOS > Applications Linux > MajestyLauncher"
    echo ""
    echo "  Conseils Chromebook :"
    echo "  - Activez l'acceleration graphique de Linux :"
    echo "      chrome://flags/#crostini-gpu-support  (puis redemarrez)"
    echo "  - Si la camera tourne sans arret en jeu :"
    echo "      chrome://flags/#exo-pointer-lock  (puis redemarrez)"
    echo "  - Donnez au moins 4 Go de RAM au jeu dans les Reglages du launcher."
elif [ "$PLATFORM" = "linux" ]; then
    echo "  Raccourcis crees :"
    echo "  - Menu Applications"
    echo "  - Bureau"
elif [ "$PLATFORM" = "macos" ]; then
    echo "  Application creee :"
    echo "  - ~/Applications/MajestyLauncher.app"
fi
echo ""
echo "  Lancement de $APP_NAME..."
echo ""
sleep 2

cd "$INSTALL_DIR"
exec "$JAVA" -jar "$BOOTSTRAP_JAR"
