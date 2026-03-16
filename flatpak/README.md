# Installation d'applications Flatpak (Debian / Ubuntu / Linux Mint)

Ce dossier contient un script d'installation automatique d'applications Flatpak.

## Que fait le script ?

Le script `installation_flatpak_debian_base.sh` :

- Vérifie que l'ordinateur est connecté à Internet (accès à `flathub.org`).
- Vérifie que `flatpak` est installé (sinon, affiche la commande à exécuter).
- Détecte la distribution Linux (Debian, Ubuntu, Linux Mint, etc.) et l'environnement de bureau (GNOME, KDE, Cinnamon, XFCE, MATE, ...).
- Installe les paquets nécessaires pour une intégration Flatpak dans le gestionnaire de logiciels du bureau (par exemple `gnome-software-plugin-flatpak`, `plasma-discover-backend-flatpak`, etc.).
- Ajoute le dépôt `flathub` si ce n'est pas déjà fait.
- Installe une liste d'applications Flatpak (Bottles, Warehouse, Flatseal, FlatSweep, Bazaar).
- Nettoie les paquets Flatpak inutilisés.
- Affiche un message recommandant de redémarrer la session si Flathub a été ajouté pour la première fois.

> Le script est prévu pour les distributions basées sur Debian/Ubuntu. Il peut fonctionner sur d'autres distributions, mais sans garantie.

## Comment l'utiliser

1. Ouvrez un terminal.
2. Placez-vous dans le dossier `flatpak` :

```bash
cd /path/to/Debian_scripts/flatpak
```

3. Lancez le script avec `sudo` :

```bash
sudo ./installation_flatpak_debian_base.sh
```

### Options disponibles

- `--help` : affiche l'aide et quitte.
- `--dry-run` : simule l'installation sans effectuer de changements.
- `--list` : affiche la liste des applications qui seraient installées.

Exemples :

```bash
sudo ./installation_flatpak_debian_base.sh --dry-run
sudo ./installation_flatpak_debian_base.sh --list
```

## Applications installées

Le script installe (par défaut) les applications suivantes :

- Bottles (gestionnaire de bouteilles Wine)
- Warehouse (gestionnaire d'applications Flatpak)
- Flatseal (gestionnaire de permissions Flatpak)
- FlatSweep (nettoyeur de données Flatpak)
- Bazaar (gestionnaire de paquets Flatpak)

> Les applications sont définies dans le tableau `applications` du script. Vous pouvez l'adapter en commentant/ajoutant des lignes.
