#!/bin/bash
set -e

# ===================================
#   MajestyCraft - Setup
#   macOS / Linux
# ===================================

# --- Detection OS & Architecture ---
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        INSTALL_DIR="$HOME/Library/Application Support/MajestyCraft"
        OS_NAME="mac"
        ;;
    Linux)
        INSTALL_DIR="$HOME/.majestycraft"
        OS_NAME="linux"
        ;;
    *)
        echo "  ERREUR: OS non supporte: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64) ARCH_NAME="x64" ;;
    aarch64|arm64) ARCH_NAME="aarch64" ;;
    *)
        echo "  ERREUR: Architecture non supportee: $ARCH"
        exit 1
        ;;
esac

JRE_DIR="$INSTALL_DIR/jre"
BOOTSTRAP_JAR="$INSTALL_DIR/bootstrap.jar"
JAVA="$JRE_DIR/bin/java"
JAVAW="$JRE_DIR/bin/java"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Azul Zulu 8 JRE + JavaFX
if [ "$OS_NAME" = "mac" ]; then
    JRE_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-fx-jre8.0.482-macosx_${ARCH_NAME}.zip"
    JRE_EXT="zip"
else
    JRE_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-fx-jre8.0.482-linux_${ARCH_NAME}.tar.gz"
    JRE_EXT="tar.gz"
fi

# ===================================
#   Fonctions utilitaires
# ===================================
show_header() {
    clear
    echo ""
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║         MajestyCraft - Setup          ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo ""
}

# ===================================
#   MENU (si deja installe)
# ===================================
if [ -f "$JAVA" ] && [ -f "$BOOTSTRAP_JAR" ]; then
    while true; do
        show_header
        echo "  MajestyCraft est deja installe."
        echo ""
        echo "  [1] Lancer MajestyCraft"
        echo "  [2] Reparer l'installation"
        echo "  [3] Desinstaller"
        echo "  [4] Quitter"
        echo ""
        printf "  Votre choix : "
        read -r CHOICE

        case "$CHOICE" in
            1)
                cd "$INSTALL_DIR"
                exec "$JAVA" -jar "$BOOTSTRAP_JAR"
                ;;
            2)
                rm -rf "$JRE_DIR"
                rm -f "$BOOTSTRAP_JAR"
                break  # continue to install
                ;;
            3)
                show_header
                echo "  Desinstaller MajestyCraft ?"
                echo ""
                echo "  Cela supprimera :"
                echo "  - Java 8 (portable)"
                echo "  - Le bootstrap"
                echo "  - Les raccourcis"
                echo ""
                echo "  Vos donnees Minecraft ne seront PAS supprimees."
                echo ""
                printf "  Confirmer ? (O/N) : "
                read -r CONFIRM
                if [ "$CONFIRM" = "O" ] || [ "$CONFIRM" = "o" ]; then
                    # Supprimer raccourcis
                    if [ "$OS_NAME" = "linux" ]; then
                        rm -f "$HOME/.local/share/applications/majestycraft.desktop"
                        rm -f "$HOME/Desktop/MajestyCraft.desktop" 2>/dev/null
                        rm -f "$HOME/Bureau/MajestyCraft.desktop" 2>/dev/null
                    elif [ "$OS_NAME" = "mac" ]; then
                        rm -f "$HOME/Applications/MajestyCraft.command" 2>/dev/null
                    fi
                    # Supprimer dossier
                    rm -rf "$INSTALL_DIR"
                    echo ""
                    echo "  MajestyCraft a ete desinstalle avec succes."
                    echo ""
                    read -r -p "  Appuyez sur Entree pour quitter..."
                    exit 0
                fi
                ;;
            4)
                exit 0
                ;;
        esac
    done
fi

# ===================================
#   INSTALLATION
# ===================================
show_header
echo "  Bienvenue dans l'installateur de MajestyCraft !"
echo ""
echo "  Ce programme va installer :"
echo "  - Java 8 (portable)"
echo "  - MajestyCraft Bootstrap"
echo ""
echo "  Emplacement :"
echo "  $INSTALL_DIR"
echo ""
printf "  Installer MajestyCraft ? (O/N) : "
read -r CONFIRM
if [ "$CONFIRM" != "O" ] && [ "$CONFIRM" != "o" ]; then
    echo ""
    echo "  Installation annulee."
    sleep 2
    exit 0
fi

echo ""
echo "  -------------------------------------------"
echo "    Installation en cours..."
echo "  -------------------------------------------"
echo ""

mkdir -p "$INSTALL_DIR"

# --- Etape 1 : Java ---
if [ ! -f "$JAVA" ]; then
    echo "  [1/4] Telechargement de Java 8..."
    echo "        Cela peut prendre quelques minutes."
    echo ""

    # Fallback: si aarch64 pas dispo sur macOS pour Java 8, essayer x64 (Rosetta 2)
    HTTP_CODE=$(curl -L -s -o /dev/null -w "%{http_code}" "$JRE_URL")
    if [ "$HTTP_CODE" != "200" ] && [ "$OS_NAME" = "mac" ] && [ "$ARCH_NAME" = "aarch64" ]; then
        echo "  Java 8 ARM non disponible, utilisation x64 (Rosetta 2)..."
        JRE_URL="https://cdn.azul.com/zulu/bin/zulu8.92.0.21-ca-fx-jre8.0.482-macosx_x64.zip"
    fi

    curl -L -# -o "$INSTALL_DIR/jre_download" "$JRE_URL"
    if [ $? -ne 0 ]; then
        echo ""
        echo "  ERREUR: Impossible de telecharger Java."
        echo "  Verifiez votre connexion internet."
        exit 1
    fi

    echo ""
    echo "  [2/4] Extraction de Java..."
    if [ "$JRE_EXT" = "zip" ]; then
        unzip -q "$INSTALL_DIR/jre_download" -d "$INSTALL_DIR"
    else
        tar -xzf "$INSTALL_DIR/jre_download" -C "$INSTALL_DIR"
    fi

    for dir in "$INSTALL_DIR"/zulu*; do
        if [ -d "$dir" ] && [ -f "$dir/bin/java" ]; then
            mv "$dir" "$JRE_DIR"
            break
        fi
    done

    rm -f "$INSTALL_DIR/jre_download"

    # macOS: remove quarantine
    if [ "$OS_NAME" = "mac" ]; then
        xattr -rd com.apple.quarantine "$JRE_DIR" 2>/dev/null || true
    fi

    if [ ! -f "$JAVA" ]; then
        echo ""
        echo "  ERREUR: L'extraction de Java a echoue."
        exit 1
    fi

    chmod +x "$JAVA"
    echo "        Java installe."
    echo ""
else
    echo "  [1/4] Java deja present."
    echo "  [2/4] Java deja present."
    echo ""
fi

# --- Etape 2 : Bootstrap ---
echo "  [3/4] Installation du bootstrap..."
if [ -f "$SCRIPT_DIR/dist/bootstrap.jar" ]; then
    cp "$SCRIPT_DIR/dist/bootstrap.jar" "$BOOTSTRAP_JAR"
elif [ -f "$SCRIPT_DIR/bootstrap.jar" ]; then
    cp "$SCRIPT_DIR/bootstrap.jar" "$BOOTSTRAP_JAR"
else
    echo ""
    echo "  ERREUR: bootstrap.jar introuvable."
    echo "  Lancez d'abord build.sh pour compiler le projet,"
    echo "  ou placez bootstrap.jar a cote de ce script."
    exit 1
fi
echo "        Bootstrap installe."
echo ""

# --- Etape 3 : Raccourcis ---
echo "  [4/4] Creation des raccourcis..."

# Creer le lanceur
cat > "$INSTALL_DIR/MajestyLauncher.sh" << LAUNCH_EOF
#!/bin/bash
cd "$INSTALL_DIR"
exec "$JAVA" -jar "$BOOTSTRAP_JAR"
LAUNCH_EOF
chmod +x "$INSTALL_DIR/MajestyLauncher.sh"

# Creer le desinstalleur
cat > "$INSTALL_DIR/Uninstall.sh" << UNINST_EOF
#!/bin/bash
echo ""
echo "  Desinstallation de MajestyCraft..."
echo ""
rm -f "$HOME/.local/share/applications/majestycraft.desktop" 2>/dev/null
rm -f "$HOME/Desktop/MajestyCraft.desktop" 2>/dev/null
rm -f "$HOME/Bureau/MajestyCraft.desktop" 2>/dev/null
rm -f "$HOME/Applications/MajestyCraft.command" 2>/dev/null
rm -rf "$INSTALL_DIR"
echo "  MajestyCraft a ete desinstalle."
echo ""
UNINST_EOF
chmod +x "$INSTALL_DIR/Uninstall.sh"

if [ "$OS_NAME" = "mac" ]; then
    cp "$INSTALL_DIR/MajestyLauncher.sh" "$INSTALL_DIR/MajestyLauncher.command"
    chmod +x "$INSTALL_DIR/MajestyLauncher.command"
    mkdir -p "$HOME/Applications"
    ln -sf "$INSTALL_DIR/MajestyLauncher.command" "$HOME/Applications/MajestyCraft.command" 2>/dev/null || true
    echo "        Raccourci : ~/Applications/MajestyCraft.command"

elif [ "$OS_NAME" = "linux" ]; then
    DESKTOP_DIR="$HOME/.local/share/applications"
    mkdir -p "$DESKTOP_DIR"
    cat > "$DESKTOP_DIR/majestycraft.desktop" << DESKTOP_EOF
[Desktop Entry]
Type=Application
Name=MajestyCraft
Exec=$JAVA -jar $BOOTSTRAP_JAR
Path=$INSTALL_DIR
Terminal=false
Categories=Game;
DESKTOP_EOF
    chmod +x "$DESKTOP_DIR/majestycraft.desktop"

    # Raccourci bureau (fr/en)
    if [ -d "$HOME/Desktop" ]; then
        cp "$DESKTOP_DIR/majestycraft.desktop" "$HOME/Desktop/MajestyCraft.desktop"
        chmod +x "$HOME/Desktop/MajestyCraft.desktop"
    elif [ -d "$HOME/Bureau" ]; then
        cp "$DESKTOP_DIR/majestycraft.desktop" "$HOME/Bureau/MajestyCraft.desktop"
        chmod +x "$HOME/Bureau/MajestyCraft.desktop"
    fi
    echo "        Raccourci cree sur le bureau."
fi

# --- Ecran de fin ---
echo ""
echo "  ╔═══════════════════════════════════════╗"
echo "  ║                                       ║"
echo "  ║   Installation terminee !             ║"
echo "  ║                                       ║"
echo "  ╠═══════════════════════════════════════╣"
echo "  ║                                       ║"
echo "  ║   Emplacement :                       ║"
echo "  ║   $INSTALL_DIR"
echo "  ║                                       ║"
echo "  ║   MajestyCraft va se lancer...        ║"
echo "  ║                                       ║"
echo "  ╚═══════════════════════════════════════╝"
echo ""
sleep 3

# --- Lancement ---
cd "$INSTALL_DIR"
exec "$JAVA" -jar "$BOOTSTRAP_JAR"
