# 🐧 Guide d'installation et configuration de Yazi pour Linux

## ✅ Prérequis

Ce guide est spécifiquement conçu pour les distributions Linux suivantes :
- **Arch Linux** / Manjaro / EndeavourOS
- **Ubuntu** / Debian / Linux Mint / Pop!_OS
- **Fedora** / RHEL / CentOS
- **openSUSE**
- **Gentoo**

**Shell supportés :** Bash, Zsh, Fish

---

## 📦 Installation rapide

# 1. Télécharger les fichiers
# 2. Copier les configs
cp yazi.toml ~/.config/yazi/
cp keymap.toml ~/.config/yazi/

# 3. Lancer le script
chmod +x setup-yazi.sh
./setup-yazi.sh

# 4. Configurer votre terminal dans keymap.toml
nano ~/.config/yazi/keymap.toml
# → Décommenter la ligne de votre terminal

# 5. Recharger le shell
source ~/.bashrc  # ou ~/.zshrc

# 6. Lancer Yazi
y

---

## 📦 Installation des fichiers de configuration

### 1. Sauvegardez votre configuration actuelle

```bash
# Créer une sauvegarde
cp ~/.config/yazi/yazi.toml ~/.config/yazi/yazi.toml.backup
cp ~/.config/yazi/keymap.toml ~/.config/yazi/keymap.toml.backup
```

### 2. Copiez les nouveaux fichiers de configuration

```bash
# Assurez-vous que le dossier existe
mkdir -p ~/.config/yazi

# Copiez les fichiers (remplacez par vos fichiers générés)
cp yazi.toml ~/.config/yazi/yazi.toml
cp keymap.toml ~/.config/yazi/keymap.toml
```

### 3. Rendez le script d'installation exécutable et lancez-le

```bash
chmod +x setup-yazi.sh
./setup-yazi.sh
```

---

## 🔌 Installation manuelle des plugins (si le script échoue)

### Méthode recommandée : ya pack

```bash
# Navigation intelligente
ya pack -a yazi-rs/plugins:zoxide

# Saut rapide
ya pack -a yazi-rs/plugins:jump

# Preview maximisé
ya pack -a yazi-rs/plugins:max-preview

# Enter intelligent (fichier OU dossier)
ya pack -a yazi-rs/plugins:smart-enter

# Marque-pages
ya pack -a dedukun/bookmarks.yazi

# Compression facile
ya pack -a KKV9/compress.yazi

# Renommage en masse (bulk rename)
ya pack -a yazi-rs/plugins:bulk-rename

# Intégration Git (optionnel)
ya pack -a yazi-rs/plugins:git

# Prompt Starship (optionnel)
ya pack -a Rolv-Apneseth/starship.yazi
```

### Alternative : Installation manuelle

Si `ya pack` ne fonctionne pas, clonez manuellement :

```bash
cd ~/.config/yazi/plugins

# Exemple pour zoxide
git clone https://github.com/yazi-rs/plugins.git temp
cp -r temp/zoxide.yazi .
rm -rf temp
```

---

## 🛠️ Installation des dépendances (Linux)

Les commandes varient selon votre distribution :

### Arch Linux / Manjaro / EndeavourOS

```bash
# Installation complète
sudo pacman -S yazi fzf fd ripgrep zoxide feh mpv zathura \
               unar p7zip jq glow bat ffmpegthumbnailer imagemagick \
               poppler

# Minimal (seulement l'essentiel)
sudo pacman -S yazi fzf fd ripgrep zoxide
```

### Ubuntu / Debian / Linux Mint / Pop!_OS

```bash
# Installation complète
sudo apt update
sudo apt install fzf fd-find ripgrep feh mpv zathura \
                 unar p7zip-full jq bat ffmpegthumbnailer imagemagick \
                 poppler-utils

# Créer un lien symbolique pour fd (nommé fdfind sur Debian)
sudo ln -s $(which fdfind) /usr/local/bin/fd 2>/dev/null || true

# Créer un lien pour bat (nommé batcat sur Debian)
sudo ln -s $(which batcat) /usr/local/bin/bat 2>/dev/null || true

# Installer glow (via GitHub releases)
wget https://github.com/charmbracelet/glow/releases/latest/download/glow_Linux_x86_64.tar.gz
tar -xzf glow_Linux_x86_64.tar.gz
sudo mv glow /usr/local/bin/
rm glow_Linux_x86_64.tar.gz

# Installer zoxide (via GitHub releases ou cargo)
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Installer Yazi (dernière version via cargo ou GitHub)
cargo install --locked yazi-fm yazi-cli
# OU télécharger depuis GitHub releases
```

### Fedora / RHEL / CentOS

```bash
# Installation complète
sudo dnf install fzf fd-find ripgrep zoxide feh mpv zathura \
                 unar p7zip p7zip-plugins jq glow bat \
                 ffmpegthumbnailer ImageMagick poppler-utils

# Minimal
sudo dnf install fzf fd-find ripgrep zoxide
```

### openSUSE

```bash
# Installation complète
sudo zypper install fzf fd ripgrep zoxide feh mpv zathura \
                    unar p7zip jq bat ffmpegthumbnailer ImageMagick \
                    poppler-tools

# Installer glow et autres via opi (Open Build Service)
opi glow
```

### Gentoo

```bash
# Installation complète
sudo emerge -av app-shells/fzf sys-apps/fd app-text/ripgrep \
                 app-shells/zoxide media-gfx/feh media-video/mpv \
                 app-text/zathura app-arch/unar app-arch/p7zip \
                 app-misc/jq sys-apps/bat \
                 media-video/ffmpegthumbnailer media-gfx/imagemagick
```

### Installation universelle via Cargo (Rust)

Si votre distribution ne propose pas certains packages :

```bash
# Installer Rust/Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Installer via cargo
cargo install yazi-fm yazi-cli
cargo install zoxide
cargo install bat
cargo install ripgrep
cargo install fd-find
```

---

## ⚙️ Configuration du shell wrapper (Linux)

### Pour Bash (~/.bashrc)

```bash
# Ajouter à la fin de ~/.bashrc
cat >> ~/.bashrc << 'EOF'

# Yazi shell wrapper - permet de changer de dossier à la sortie
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
EOF

# Recharger la configuration
source ~/.bashrc
```

### Pour Zsh (~/.zshrc)

```bash
# Ajouter à la fin de ~/.zshrc
cat >> ~/.zshrc << 'EOF'

# Yazi shell wrapper - permet de changer de dossier à la sortie
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
EOF

# Recharger la configuration
source ~/.zshrc
```

### Pour Fish (~/.config/fish/config.fish)

```bash
# Ajouter à ~/.config/fish/config.fish
cat >> ~/.config/fish/config.fish << 'EOF'

# Yazi shell wrapper - permet de changer de dossier à la sortie
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
EOF

# Recharger la configuration
source ~/.config/fish/config.fish
```

### Configuration de Zoxide (optionnel mais recommandé)

Ajouter à votre fichier de configuration shell :

**Bash (~/.bashrc) :**
```bash
eval "$(zoxide init bash)"
```

**Zsh (~/.zshrc) :**
```bash
eval "$(zoxide init zsh)"
```

**Fish (~/.config/fish/config.fish) :**
```fish
zoxide init fish | source
```

---

## 🖥️ Configuration du terminal

Yazi utilise la variable d'environnement `$TERMINAL` ou vous pouvez spécifier votre terminal dans `keymap.toml`.

### Éditez `~/.config/yazi/keymap.toml`

Décommentez la ligne correspondant à votre terminal (section "Terminal dans le dossier courant") :

```toml
# Pour kitty :
{ on = ["T"], run = 'shell --orphan "kitty --directory \"$PWD\""', desc = "Ouvrir kitty" },

# Pour alacritty :
{ on = ["T"], run = 'shell --orphan "alacritty --working-directory \"$PWD\""', desc = "Ouvrir alacritty" },

# Pour gnome-terminal :
{ on = ["T"], run = 'shell --orphan "gnome-terminal --working-directory=\"$PWD\""', desc = "Ouvrir gnome-terminal" },

# Pour konsole (KDE) :
{ on = ["T"], run = 'shell --orphan "konsole --workdir \"$PWD\""', desc = "Ouvrir konsole" },

# Pour xterm :
{ on = ["T"], run = 'shell --orphan "xterm -e \"cd $PWD && $SHELL\""', desc = "Ouvrir xterm" },

# Pour terminator :
{ on = ["T"], run = 'shell --orphan "terminator --working-directory=\"$PWD\""', desc = "Ouvrir terminator" },

# Pour tilix :
{ on = ["T"], run = 'shell --orphan "tilix --working-directory=\"$PWD\""', desc = "Ouvrir tilix" },
```

### Ou définir la variable $TERMINAL

Ajoutez dans votre `~/.bashrc`, `~/.zshrc` ou `~/.config/fish/config.fish` :

```bash
export TERMINAL="kitty"  # Remplacez par votre terminal préféré
```

---

## 🎯 Raccourcis principaux à retenir
### Navigation de base
- `<Space>` - Toggle sélection
- `v` - Mode visuel
- `gg` / `G` - Début/fin de liste

### Opérations fichiers
- `o` / `Enter` - Ouvrir
- `y` - Copier (yank)
- `x` - Couper
- `p` - Coller
- `d` - Supprimer (corbeille)
- `D` - Supprimer définitivement
- `a` - Créer fichier/dossier
- `r` - Renommer
- `R` - Renommage en masse

### Recherche
- `/` - Rechercher
- `f` - Filtrer
- `S` - Recherche fd (récursive)

### Navigation rapide (goto)
- `gh` - Home (~)
- `gc` - Config (~/.config)
- `gd` - Downloads
- `gD` - Documents
- `gr` - Racine (/)
- `g<Space>` - cd interactif
- `zz` - Zoxide jump

### Marque-pages (si plugin installé)
- `m` - Sauver marque-page
- `'` - Aller au marque-page

### Onglets
- `t` - Nouvel onglet
- `1-9` - Aller à l'onglet N
- `[` / `]` - Onglet précédent/suivant
- `<C-w>` - Fermer onglet

### Affichage
- `zh` - Toggle fichiers cachés
- `zP` - Maximiser preview

### Utilitaires
- `C` - Compresser sélection
- `T` - Ouvrir kitty ici
- `w` - Afficher tâches
- `~` ou `?` - Aide

### Quitter
- `q` - Quitter (change le dossier)
- `Q` - Quitter (sans changer le dossier)

---

## 🔍 Vérification de l'installation

### Tester Yazi

```bash
# Lancer Yazi avec le wrapper
y

# Une fois dans Yazi :
# 1. Appuyez sur ~ pour voir l'aide
# 2. Appuyez sur g<Space> pour tester la navigation interactive
# 3. Sélectionnez des fichiers avec <Space> puis appuyez sur C pour tester la compression
```

### Vérifier les plugins installés

```bash
# Lister les plugins
ls ~/.config/yazi/plugins/

# Devrait afficher : zoxide.yazi, jump.yazi, max-preview.yazi, etc.
```

---

## 🐛 Dépannage (Linux)

### Yazi n'est pas installé

```bash
# Vérifier l'installation
which yazi

# Si absent, installer via cargo
cargo install --locked yazi-fm yazi-cli

# OU télécharger le binaire depuis GitHub
wget https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
unzip yazi-x86_64-unknown-linux-gnu.zip
sudo mv yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
sudo mv yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/
```

```bash
# Vérifier que ya est installé
ya --version

# Réinstaller un plugin
ya pack -u yazi-rs/plugins:zoxide
ya pack -a yazi-rs/plugins:zoxide
```

### Zoxide ne fonctionne pas

```bash
# Vérifier que zoxide est installé et configuré
zoxide --version

# Ajouter à ~/.bashrc ou ~/.zshrc :
eval "$(zoxide init bash)"  # ou zsh
```

### La fonction y() ne change pas de dossier

Vérifiez que :
1. La fonction est bien dans votre fichier de config shell
2. Vous avez rechargé le shell : `source ~/.bashrc`
3. Vous utilisez `y` et non `yazi` pour lancer l'application

### Preview d'images ne fonctionne pas (Linux)

Yazi nécessite un terminal supportant les protocoles d'images :

**Terminaux compatibles :**
- ✅ **kitty** (recommandé) - Protocole kitty
- ✅ **wezterm** - Protocole iTerm2
- ✅ **Konsole** (KDE) - Protocole kitty
- ✅ **foot** - Protocole sixel
- ✅ **mlterm** - Protocole sixel
- ⚠️ **alacritty** - Pas de support natif, utilise ueberzugpp
- ⚠️ **gnome-terminal** - Limité, utilise ueberzugpp
- ⚠️ **xterm** - Support sixel uniquement

**Installation de ueberzugpp (pour terminaux non compatibles) :**

```bash
# Arch Linux
sudo pacman -S ueberzugpp

# Ubuntu/Debian (via GitHub)
wget https://github.com/jstkdng/ueberzugpp/releases/latest/download/ueberzugpp-Linux-x86_64.tar.gz
tar -xzf ueberzugpp-Linux-x86_64.tar.gz
sudo mv ueberzugpp /usr/local/bin/

# Installer les dépendances d'image
sudo apt install imagemagick ffmpegthumbnailer  # Ubuntu
sudo pacman -S imagemagick ffmpegthumbnailer    # Arch
```

**Vérifier le support :**
```bash
# Lancer Yazi et vérifier le log
yazi --debug
```

### Permissions refusées lors de la suppression

```bash
# Vérifier les permissions du fichier
ls -la fichier

# Si besoin, utiliser sudo (attention !)
sudo yazi

# Ou changer les permissions du dossier
sudo chown -R $USER:$USER /chemin/vers/dossier
```

### Problème avec les fichiers cachés

```bash
# Dans Yazi, appuyer sur zh pour toggle les fichiers cachés
# Ou modifier yazi.toml :
show_hidden = true  # Toujours afficher les fichiers cachés
```

### Performance lente sur grands dossiers

```bash
# Réduire la zone de preview dans yazi.toml :
max_width = 400
max_height = 600

# Désactiver certains previewers pour les gros fichiers
# Ou augmenter les workers dans yazi.toml :
micro_workers = 10
macro_workers = 20
```

- **Documentation officielle** : https://yazi-rs.github.io
- **Plugins** : https://github.com/yazi-rs/plugins
- **Wiki** : https://github.com/sxyazi/yazi/wiki
- **Configuration avancée** : https://yazi-rs.github.io/docs/configuration/overview

---

## 🎨 Personnalisation supplémentaire

### Thème

Créez `~/.config/yazi/theme.toml` pour personnaliser les couleurs.

Exemple minimal :

```toml
[manager]
cwd = { fg = "cyan" }

[status]
separator_open = ""
separator_close = ""

[filetype]
rules = [
    { mime = "image/*", fg = "yellow" },
    { mime = "video/*", fg = "magenta" },
    { mime = "audio/*", fg = "cyan" },
]
```

### Init.lua (scripts Lua personnalisés)

Créez `~/.config/yazi/init.lua` pour des fonctions avancées :

```lua
-- Exemple : afficher un message au démarrage
function Status:render(area)
    self.area = area
    return ui.Text("Bienvenue dans Yazi! 🚀")
end
```

---

## ✅ Checklist finale

- [ ] Fichiers de configuration copiés
- [ ] Plugins installés
- [ ] Wrapper shell configuré et testé
- [ ] Dépendances recommandées installées
- [ ] Yazi lancé avec `y` et fonctionne correctement
- [ ] Raccourcis testés (navigation, sélection, opérations)
- [ ] Plugins testés (zoxide avec `zz`, bookmarks avec `m` et `'`)

**Félicitations ! Votre configuration Yazi est maintenant optimisée ! 🎉**
