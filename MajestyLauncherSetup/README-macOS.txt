============================================
  MajestyLauncher - Installation macOS
============================================

Contenu du ZIP :
  - MajestyLauncher.sh   (installateur)
  - bootstrap.jar        (bootstrap du launcher)

Installation :
  1. Extraire le ZIP dans un dossier de votre choix
  2. Ouvrir le Terminal (Applications > Utilitaires > Terminal)
  3. Naviguer vers le dossier extrait :
       cd ~/Downloads/MajestyLauncher-macOS
  4. Rendre le script executable :
       chmod +x MajestyLauncher.sh
  5. Lancer l'installateur :
       ./MajestyLauncher.sh
  6. Suivre les instructions a l'ecran
  7. L'installateur va :
     - Detecter votre architecture (Intel / Apple Silicon)
     - Telecharger Java 8 automatiquement
     - Installer le bootstrap
     - Creer MajestyLauncher.app dans ~/Applications
     - Lancer MajestyLauncher

Note : Si macOS bloque le lancement, aller dans
Preferences Systeme > Securite et confidentialite
et autoriser l'execution.

Desinstallation :
  - Relancer MajestyLauncher.sh et choisir "Desinstaller"

Configuration requise :
  - macOS 10.14 (Mojave) ou superieur
  - Intel ou Apple Silicon (M1/M2/M3)
  - Connexion internet (pour le telechargement de Java)
  - ~200 Mo d'espace disque

Support : https://majestylauncher.com
