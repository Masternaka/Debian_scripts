#!/bin/bash

# Sauvegarde du système avant toute modification (recommandé)
sudo apt update && sudo apt upgrade

# Liste des snaps à supprimer (ajoutez-en si nécessaire)
snaps_to_remove=("snapd" "core22" "firefox" "gnome-42-2204" "gtk-common-themes" "snap-store")

# Suppression des snaps
for snap in "${snaps_to_remove[@]}"; do
  sudo snap remove --purge "$snap"
done

# Suppression du cache Snap
sudo rm -rf /var/cache/snapd/

# Suppression des paquets liés à Snap
sudo apt remove --purge snapd gnome-software-plugin-snap

# Blocage de l'installation future de Snap
sudo apt-mark hold snapd

# Suppression des répertoires Snap dans les dossiers personnels
find /home -type d -name snap -exec sudo rm -rf {} \;

# Vérification de la suppression
snap list

# Message de confirmation
echo "Snap a été supprimé avec succès !"
