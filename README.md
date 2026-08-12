# debian-scripts

Scripts Bash pour configurer et personnaliser une installation Debian 13 `trixie`.

## Prérequis

- Debian 13 `trixie`
- `bash`
- `sudo`
- `systemd`
- Un compte utilisateur standard pour l'exécution des scripts utilisateur et l'invocation via `sudo` pour les scripts administrateur.

---

## Utilisation

Chaque script peut être exécuté individuellement depuis le dossier du projet selon vos besoins. Les scripts administrateur requièrent `sudo`, tandis que les scripts utilisateur doivent être exécutés avec un compte utilisateur standard.

La plupart des scripts prennent en charge l'option `--dry-run` (ou `-n`) pour simuler les actions sans modifier le système :

```bash
# Simulation pour un script root
sudo bash "01 - systemd_services.sh" --dry-run

# Simulation pour un script utilisateur
bash "06 - install_nerd_fonts.sh" --dry-run
```

---

## Vue d'ensemble des scripts

| Script | Rôle principal | Droits requis |
| :--- | :--- | :--- |
| `01 - systemd_services.sh` | Activer `fstrim`, `bluetooth`, `firewalld` | Root (`sudo`) |
| `02 - zram_settings.sh` | Configuration de zram (`systemd-zram-generator`) | Root (`sudo`) |
| `06 - install_fontawesome.sh` | Installation locale de Font Awesome et Material Design Icons | Utilisateur |
| `06 - install_nerd_fonts.sh` | Installation locale des Nerd Fonts dans `~/.local/share/fonts` | Utilisateur |
| `07 - install_samba.sh` | Installation et configuration de Samba & pare-feu | Root (`sudo`) |
| `08 - install_backports.sh` | Activation du dépôt `trixie-backports` (DEB822) | Root (`sudo`) |
| `09 - install_extrepo.sh` | Installation et gestion des paquets via `extrepo` | Root (`sudo`) |
| `10 - install_apt.sh` | Installation des paquets APT (officiels & backports) | Root (`sudo`) |
| `11 - install_flatpak.sh` | Installation de Flatpak, Flathub et applications Flatpak | Root (`sudo`) / User |
| `12 - install_appimage.sh` | Dépendances AppImage et raccourcis d'applications (Helix Notes) | Root / User |
| `13 - install_dotfiles.sh` | Déploiement des fichiers de configuration dotfiles (en préparation) | Utilisateur |
| `14 - install_externaldeb.sh` | Installation de navigateurs et logiciels tiers (Brave, Vivaldi, Fresh) | Root (`sudo`) |
| `15 - install_homebrew.sh` | Installation et gestion des paquets Homebrew pour Linux | Utilisateur |
| `16 - remove_packages.sh` | Nettoyage des paquets préinstallés / bloatware par environnement | Root (`sudo`) |
| `XX - bash_tools.sh` | Installation d'outils CLI modernes (`bat`, `eza`, `ripgrep`, etc.) | Root (`sudo`) / User |
| `XX - install_alias.sh` | Importation automatique de `.bash_aliases` dans `.bashrc` | Utilisateur |

---

## Guide détaillé des scripts

### Scripts Administrateur (Root / Sudo)

#### `01 - systemd_services.sh`
Installe et active les services essentiels au système :
- `fstrim.timer` (optimisation des SSD)
- `bluetooth.service`
- `firewalld.service`

**Utilisation :**
```bash
sudo bash "01 - systemd_services.sh"
sudo bash "01 - systemd_services.sh" --dry-run
```

#### `02 - zram_settings.sh`
Installe `systemd-zram-generator` et génère le fichier `/etc/systemd/zram-generator.conf`.
- **Configuration appliquée :** Taille `ram / 2`, algorithme `zstd`, type `swap`, priorité `100`.

**Utilisation :**
```bash
sudo bash "02 - zram_settings.sh"
sudo bash "02 - zram_settings.sh" --dry-run
```

#### `07 - install_samba.sh`
Installe Samba, sauvegarde le fichier `smb.conf` existant, écrit une configuration minimale sécurisée, valide le fichier via `testparm` et configure le pare-feu (`firewalld` ou `ufw`).
- `--force` : Remplace `smb.conf` sans demander de confirmation.
- `--dry-run` : Affiche les actions sans modifier le système.

**Utilisation :**
```bash
sudo bash "07 - install_samba.sh" --dry-run
sudo bash "07 - install_samba.sh" --force
```

#### `08 - install_backports.sh`
Active le dépôt `trixie-backports` au format moderne DEB822 dans `/etc/apt/sources.list.d/trixie-backports.sources` en réutilisant automatiquement le miroir principal.

**Utilisation :**
```bash
sudo bash "08 - install_backports.sh"
sudo bash "08 - install_backports.sh" --dry-run
```

#### `09 - install_extrepo.sh`
Utilise l'outil officiel Debian `extrepo` pour activer des dépôts tiers vérifiés (ex: Google Chrome, VS Code, Docker) sans gestion manuelle des clés GPG.
- `-n`, `--dry-run` : Simulation des opérations.
- `-c`, `--contrib` : Active la politique "contrib".
- `-f`, `--non-free` : Active la politique "non-free".
- `-s`, `--search TERME` : Recherche un dépôt disponible.

**Utilisation :**
```bash
sudo bash "09 - install_extrepo.sh" --contrib --non-free google_chrome vscode
sudo bash "09 - install_extrepo.sh" --search chrome
sudo bash "09 - install_extrepo.sh" --dry-run
```

#### `10 - install_apt.sh`
Installe la liste des paquets système définis dans :
- `OFFICIAL_PACKAGES` (dépôts Debian standards)
- `BACKPORT_PACKAGES` (nécessite `08 - install_backports.sh`)

**Utilisation :**
```bash
sudo bash "10 - install_apt.sh"
sudo bash "10 - install_apt.sh" --dry-run
```

#### `14 - install_externaldeb.sh`
Menu interactif pour installer des logiciels propriétaires ou récents depuis leurs serveurs officiels :
1. **Brave Browser**
2. **Vivaldi Browser**
3. **Fresh Editor** (`getfresh.dev`)

**Utilisation :**
```bash
sudo bash "14 - install_externaldeb.sh"
```

#### `16 - remove_packages.sh`
Détecte l'environnement de bureau actif (KDE Plasma, GNOME, XFCE, LXQt, MATE, Cinnamon) ou accepte un environnement spécifié, puis procède à la suppression des paquets non essentiels (jeux préinstallés, bloatware).
- `-n`, `--dry-run` : Simulation de la suppression.
- `-y`, `--yes` : Exécution sans confirmation.
- `--desktop ENVIRO` : Forcer l'environnement (`kde`, `gnome`, `xfce`, `lxqt`, `mate`, `cinnamon`).
- `--no-autoremove` : Désactive `apt autoremove`.

**Utilisation :**
```bash
sudo bash "16 - remove_packages.sh" --dry-run
sudo bash "16 - remove_packages.sh" --desktop gnome --dry-run
```

#### `XX - bash_tools.sh`
Installe des outils CLI modernes (`bat`, `eza`, `ripgrep`, `fd-find`, `fzf`, `zoxide`, `duf`) et injecte leur configuration dans le `.bashrc`.

**Utilisation :**
```bash
sudo bash "XX - bash_tools.sh"
sudo bash "XX - bash_tools.sh" --dry-run
```

---

### Scripts Utilisateur (Sans Sudo)

#### `06 - install_fontawesome.sh`
Télécharge et installe dans `~/.local/share/fonts` :
- Font Awesome Free (v6.7.2)
- Material Design Icons

**Utilisation :**
```bash
bash "06 - install_fontawesome.sh"
bash "06 - install_fontawesome.sh" --dry-run
```

#### `06 - install_nerd_fonts.sh`
Télécharge et installe les polices Nerd Fonts (CascadiaMono, FiraCode, Hack, Iosevka, JetBrainsMono, Meslo, Noto) dans `~/.local/share/fonts`.
- `--list` : Liste les polices disponibles.
- `--dry-run` : Simule le téléchargement.

**Utilisation :**
```bash
bash "06 - install_nerd_fonts.sh" --list
bash "06 - install_nerd_fonts.sh" --dry-run
```

#### `11 - install_flatpak.sh`
Vérifie l'installation de `flatpak`, ajoute le dépôt Flathub pour l'utilisateur courant (`SUDO_USER`) et installe les applications configurées.
- `--list` : Liste les applications Flatpak prévues.
- `--dry-run` : Simulation de l'installation.

**Utilisation :**
```bash
sudo bash "11 - install_flatpak.sh" --list
sudo bash "11 - install_flatpak.sh" --dry-run
```

#### `12 - install_appimage.sh`
Installe les dépendances AppImage (`libfuse2`, etc.), prépare le dossier de stockage des AppImages et installe des applications (ex: Helix Notes) avec leurs entrées de menu `.desktop`.

**Utilisation :**
```bash
bash "12 - install_appimage.sh"
```

#### `13 - install_dotfiles.sh`
*(En cours de développement)* — Automatisation du déploiement des fichiers de configuration (dotfiles).

**Utilisation :**
```bash
bash "13 - install_dotfiles.sh"
```

#### `15 - install_homebrew.sh`
Installe le gestionnaire de paquets Homebrew sur Linux si nécessaire, puis procède à l'installation des formules définies dans la liste `PACKAGES` ou passées en arguments.

**Utilisation :**
```bash
bash "15 - install_homebrew.sh"
bash "15 - install_homebrew.sh" htop neovim
```

#### `XX - install_alias.sh`
Ajoute au fichier `~/.bashrc` l'importation automatique d'un fichier d'alias externe (par défaut `~/debian_dotfiles/bash/.bash_aliases`).
- `--dry-run` : Simulation sans modifier `.bashrc`.
- `--file CHEMIN` : Fichier d'alias personnalisé.

**Utilisation :**
```bash
bash "XX - install_alias.sh" --dry-run
bash "XX - install_alias.sh" --file "$HOME/.bash_aliases"
```

---

## Vérification syntaxique

Avant toute exécution ou soumission, vous pouvez valider la syntaxe Bash de tous les scripts du projet avec la commande suivante :

```bash
for f in ./*.sh; do bash -n "$f" && printf 'OK %s\n' "$f"; done
```

---

## Points d'attention

1. **Scripts autonomes** : L'ancien script agrégateur `00 - super_script.sh` a été supprimé. Chaque script s'exécute désormais indépendamment selon vos besoins.
2. **Droits Root vs Utilisateur** : Les scripts modifiant la configuration système globale nécessitent `sudo`, tandis que les polices, dotfiles, alias et Homebrew doivent s'exécuter sous le compte utilisateur standard.
3. **Listes de paquets** : Pensez à adapter les tableaux de paquets dans `10 - install_apt.sh` et `15 - install_homebrew.sh` selon vos besoins avant exécution.


