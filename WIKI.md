# Wiki debian-scripts

## Prérequis

- Debian 13 `trixie`
- `bash`
- `sudo`
- `systemd`
- un compte utilisateur standard lançant le script via `sudo`

Le script principal doit être lancé depuis le dossier du projet :

```bash
sudo bash "00 - super_script.sh"
```

Pour simuler l'exécution :

```bash
sudo bash "00 - super_script.sh" --dry-run
```

## Ordre d'exécution

`00 - super_script.sh` exécute les scripts suivants :

| Script                       | Rôle                                                  | Droits             |
| ---------------------------- | ----------------------------------------------------- | ------------------ |
| `01 - systemd_services.sh`   | Active `fstrim`, `bluetooth`, `firewalld`             | root               |
| `02 - zram_settings.sh`      | Configure zram                                        | root               |
| `03 - flatpak_install.sh`    | Installe Flatpak, Flathub et les applications Flatpak | root + utilisateur |
| `04 - bash_tools.sh`         | Installe les outils CLI et configure `.bashrc`        | root + utilisateur |
| `07 - install_samba.sh`      | Installe Samba et configure le pare-feu               | root               |
| `08 - install_backports.sh`  | Active `trixie-backports`                             | root               |
| `09 - install_apt.sh`        | Installe les paquets APT listés                       | root               |
| `05 - install_alias.sh`      | Charge un fichier d'alias externe                     | utilisateur        |
| `06 - install_nerd_fonts.sh` | Installe les Nerd Fonts côté utilisateur              | utilisateur        |

## Scripts root

### `01 - systemd_services.sh`

Installe et active :

- `fstrim.timer`
- `bluetooth.service`
- `firewalld.service`

Simulation :

```bash
sudo bash "01 - systemd_services.sh" --dry-run
```

### `02 - zram_settings.sh`

Installe `systemd-zram-generator` et écrit :

```text
/etc/systemd/zram-generator.conf
```

Configuration appliquée :

- taille : `ram / 2`
- algorithme : `zstd`
- type : `swap`
- priorité : `100`

Simulation :

```bash
sudo bash "02 - zram_settings.sh" --dry-run
```

### `03 - flatpak_install.sh`

Installe `flatpak` si absent, configure Flathub pour l'utilisateur réel, puis installe les applications Flatpak listées dans le script.

Options :

```bash
sudo bash "03 - flatpak_install.sh" --list
sudo bash "03 - flatpak_install.sh" --dry-run
```

### `04 - bash_tools.sh`

Installe des outils CLI :

- `bat`
- `eza`
- `ripgrep`
- `fd-find`
- `fzf`
- `zoxide`
- `duf`

Puis ajoute un bloc de configuration dans le `.bashrc` de l'utilisateur réel.

Simulation :

```bash
sudo bash "04 - bash_tools.sh" --dry-run
```

### `07 - install_samba.sh`

Installe Samba, sauvegarde l'ancien `smb.conf`, écrit une configuration minimale, valide avec `testparm`, puis configure `firewalld` ou `ufw`.

Options :

```bash
sudo bash "07 - install_samba.sh" --dry-run
sudo bash "07 - install_samba.sh" --force
```

### `08 - install_backports.sh`

Active `trixie-backports` au format DEB822 en réutilisant le miroir principal détecté.

Simulation :

```bash
sudo bash "08 - install_backports.sh" --dry-run
```

### `09 - install_apt.sh`

Installe les paquets listés dans :

- `OFFICIAL_PACKAGES`
- `BACKPORT_PACKAGES`

`BACKPORT_PACKAGES` nécessite que `08 - install_backports.sh` ait déjà activé `trixie-backports`.

Simulation :

```bash
sudo bash "09 - install_apt.sh" --dry-run
```

## Scripts utilisateur

### `05 - install_alias.sh`

Ajoute dans `.bashrc` le chargement du fichier :

```text
~/debian_dotfiles/bash/.bash_aliases
```

Options :

```bash
bash "05 - install_alias.sh" --dry-run
bash "05 - install_alias.sh" --file "$HOME/.bash_aliases"
```

### `06 - install_nerd_fonts.sh`

Télécharge et installe localement :

- JetBrainsMono
- CascadiaMono
- FiraCode
- Meslo

Options :

```bash
bash "06 - install_nerd_fonts.sh" --list
bash "06 - install_nerd_fonts.sh" --dry-run
```

## Vérification syntaxique

Avant exécution, vérifier les scripts :

```bash
for f in ./*.sh; do bash -n "$f" && printf 'OK %s\n' "$f"; done
```

## Points d'attention

- `07` peut remplacer `smb.conf`; une sauvegarde est créée avant modification.
- `09` ne fait rien tant que les listes de paquets sont vides.
- `04` ajoute des alias qui remplacent certaines commandes standards (`cat`, `grep`, `find`).
- Les scripts sont lancés via `bash`, donc `chmod +x` n'est pas obligatoire.
