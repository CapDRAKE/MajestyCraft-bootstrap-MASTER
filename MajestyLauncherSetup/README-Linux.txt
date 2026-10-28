============================================
  MajestyLauncher - Installation Linux
============================================

Contenu du ZIP :
  - MajestyLauncher.sh   (installateur)
  - bootstrap.jar        (bootstrap du launcher)
  - majestycraft.png     (icone des raccourcis)
  - README-ChromeOS.txt  (guide Chromebook)

Installation :
  1. Extraire le ZIP dans un dossier de votre choix
  2. Ouvrir un terminal
  3. Naviguer vers le dossier extrait :
       cd ~/Downloads/MajestyLauncher-Linux
  4. Rendre le script executable :
       chmod +x MajestyLauncher.sh
  5. Lancer l'installateur :
       ./MajestyLauncher.sh
  6. Suivre les instructions a l'ecran
  7. L'installateur va :
     - Telecharger Java 8 automatiquement
     - Installer le bootstrap dans ~/.local/share/MajestyCraft
     - Creer un raccourci dans le menu applications
     - Creer un raccourci sur le bureau
     - Lancer MajestyLauncher

Deja installe ?
  Si le launcher ne s'ouvrait pas, relancer MajestyLauncher.sh
  et choisir "Reparer l'installation" : les raccourcis sont
  recrees avec le bon Java.

Desinstallation :
  - Relancer MajestyLauncher.sh et choisir "Desinstaller"

Dependances :
  - curl ou wget (pour le telechargement)
  - tar (pour l'extraction)
  - FFmpeg (facultatif, pour la musique du launcher)

Configuration requise :
  - Distribution Linux avec glibc (Ubuntu, Debian, Fedora, etc.)
  - Architecture x86_64 (toutes les versions de Minecraft)
    ou ARM aarch64 (Minecraft 1.19 et plus recent)
  - Chromebook : voir README-ChromeOS.txt
  - Connexion internet (pour le telechargement de Java)
  - ~200 Mo d'espace disque

Support : https://majestylauncher.com
