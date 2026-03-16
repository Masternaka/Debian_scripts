# Suppression de Snap sur Debian/Ubuntu

Ce dossier contient un script (`snap.remove.sh`) qui désinstalle **Snap** et supprime les paquets et fichiers associés sur les distributions basées sur Debian/Ubuntu.

## Que fait le script ?

Le script `snap.remove.sh` :

- Met à jour le système (`apt update && apt upgrade`).
- Désinstalle une liste de snaps courants (`snapd`, `core22`, `firefox`, `gnome-42-2204`, etc.).
- Supprime le cache de Snap (`/var/cache/snapd/`).
- Supprime les paquets Snap du système (`snapd`, `gnome-software-plugin-snap`).
- Empêche la réinstallation de Snap en marquant `snapd` comme « hold » (`apt-mark hold snapd`).
- Supprime les répertoires `snap/` présents dans les dossiers personnels des utilisateurs.
- Affiche la liste des snaps encore présents (via `snap list`).

> ⚠️ Ce script supprime Snap et ses données utilisateur. Assurez-vous de ne plus en avoir besoin avant de l’exécuter.

## Comment l'utiliser

1. Ouvrez un terminal.
2. Placez-vous dans le dossier `snap` :

```bash
cd /path/to/Debian_scripts/snap
```

3. Rendez le script exécutable et lancez-le avec `sudo` :

```bash
chmod +x snap.remove.sh
sudo ./snap.remove.sh
```

4. Vérifiez qu'il n'y a plus de snaps installés :

```bash
snap list
```

---

Pour plus de détails, lisez le contenu du script `snap.remove.sh` (il est commenté ligne par ligne).