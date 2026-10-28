============================================
  MajestyLauncher - Installation Chromebook
============================================

Fonctionne sur les Chromebooks Intel / AMD et ARM.
  - Intel / AMD : toutes les versions de Minecraft.
  - ARM (MediaTek, Snapdragon...) : Minecraft 1.19 et plus recent
    (Minecraft ne fournit rien pour ARM avant la 1.19).

1. Activer Linux (une seule fois)
   Parametres > A propos de ChromeOS > Environnement de developpement
   Linux > Activer. Prevoir au moins 10 Go d'espace disque.

2. Activer l'acceleration graphique (fortement conseille)
   Ouvrir chrome://flags/#crostini-gpu-support dans Chrome,
   passer sur "Enabled", puis redemarrer le Chromebook.
   Sans elle, le jeu tourne mais tres lentement.

3. Copier le ZIP dans Linux
   Dans l'application Fichiers, glisser MajestyLauncher-Linux.zip
   dans "Fichiers Linux".

4. Installer
   Ouvrir l'application Terminal (onglet "penguin"), puis :
       unzip MajestyLauncher-Linux.zip -d MajestyLauncher
       cd MajestyLauncher
       ./MajestyLauncher.sh
   Repondre "o". L'installateur propose d'installer les paquets
   systeme manquants (repondre "O"), telecharge Java et lance
   MajestyLauncher.

5. Lancer ensuite
   Lanceur ChromeOS > dossier "Applications Linux" > MajestyLauncher.

Conseils
  - Reglages du launcher : donner au moins 4 Go de RAM au jeu
    (moins sur un Chromebook qui n'a que 4 Go en tout).
  - La camera tourne sans arret en jeu : activer
    chrome://flags/#exo-pointer-lock puis redemarrer.
  - Mode performance : les mods Sodium / Lithium (onglet Mods)
    aident beaucoup sur les petites machines.

Desinstallation : relancer ./MajestyLauncher.sh et choisir 3.

Support : https://majestylauncher.com
