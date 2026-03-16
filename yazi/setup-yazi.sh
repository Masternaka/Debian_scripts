#!/usr/bin/env bash
# Script d'installation et configuration de Yazi pour Linux
# À exécuter après avoir copié les fichiers de configuration

set -e

echo "🐧 Configuration Yazi pour Linux"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier qu'on est bien sur Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "⚠️  Ce script est conçu pour Linux uniquement"
    echo "Système détecté: $OSTYPE"
    exit 1
fi

echo "✅ Système Linux détecté"
echo ""

# Créer le dossier des plugins si nécessaire
mkdir -p ~/.config/yazi/plugins

# Fonction pour installer un plugin
install_plugin() {
    local plugin=$1
    local name=$2
    echo "📦 Installation de $name..."
    ya pack -a "$plugin" 2>/dev/null || echo "⚠️  Erreur lors de l'installation de $name (peut-être déjà installé)"
}

# Plugins essentiels
echo "=== Plugins essentiels ==="
install_plugin "yazi-rs/plugins:zoxide" "Zoxide (navigation intelligente)"
install_plugin "yazi-rs/plugins:jump" "Jump (saut rapide)"
install_plugin "yazi-rs/plugins:max-preview" "Max Preview (preview plein écran)"
install_plugin "yazi-rs/plugins:smart-enter" "Smart Enter (enter intelligent)"

echo ""
echo "=== Plugins utilitaires ==="
install_plugin "dedukun/bookmarks.yazi" "Bookmarks (marque-pages)"
install_plugin "KKV9/compress.yazi" "Compress (compression facile)"

echo ""
echo "=== Plugins optionnels (recommandés) ==="
install_plugin "Rolv-Apneseth/starship.yazi" "Starship (prompt personnalisé)"
install_plugin "yazi-rs/plugins:git" "Git (intégration Git)"

echo ""
echo "✅ Installation des plugins terminée!"
echo ""

# Configuration du shell wrapper
echo "🔧 Configuration du shell wrapper..."
echo ""

SHELL_CONFIG=""
SHELL_NAME=""

# Détecter le shell utilisé
if [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
    SHELL_NAME="Bash"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
    SHELL_NAME="Zsh"
elif [ -n "$FISH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.config/fish/config.fish"
    SHELL_NAME="Fish"
else
    echo "⚠️  Shell non reconnu automatiquement"
    echo "Shells Linux supportés: bash, zsh, fish"
    echo ""
    echo "Voulez-vous configurer manuellement? [b]ash / [z]sh / [f]ish / [n]on"
    read -r shell_choice
    case $shell_choice in
        b|B) SHELL_CONFIG="$HOME/.bashrc"; SHELL_NAME="Bash" ;;
        z|Z) SHELL_CONFIG="$HOME/.zshrc"; SHELL_NAME="Zsh" ;;
        f|F) SHELL_CONFIG="$HOME/.config/fish/config.fish"; SHELL_NAME="Fish" ;;
        *) echo "Configuration shell ignorée"; SHELL_CONFIG="" ;;
    esac
fi

if [ -n "$SHELL_CONFIG" ]; then
    # Vérifier si la fonction y() existe déjà
    if ! grep -q "function y()" "$SHELL_CONFIG" 2>/dev/null && ! grep -q "function y" "$SHELL_CONFIG" 2>/dev/null; then
        echo "Ajout de la fonction y() à $SHELL_CONFIG ($SHELL_NAME)..."

        if [ "$SHELL_NAME" = "Fish" ]; then
            # Configuration spécifique pour Fish
            cat >> "$SHELL_CONFIG" << 'EOF'

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
        else
            # Configuration pour Bash/Zsh
            cat >> "$SHELL_CONFIG" << 'EOF'

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
        fi

        echo "✅ Fonction y() ajoutée à $SHELL_CONFIG"
        echo "⚠️  Redémarrez votre shell ou exécutez: source $SHELL_CONFIG"
    else
        echo "✅ La fonction y() existe déjà dans $SHELL_CONFIG"
    fi
else
    echo "⚠️  Shell non configuré, ajoutez manuellement la fonction y() à votre configuration shell"
fi

echo ""
echo "📋 Vérification des dépendances Linux..."
echo ""

# Détecter la distribution Linux
DISTRO=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
fi

echo "Distribution détectée: $DISTRO"
echo ""

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Suggestions d'installation selon la distribution
suggest_install() {
    local pkg=$1
    echo "❌ $pkg (manquant)"

    case $DISTRO in
        arch|manjaro|endeavouros)
            echo "   → sudo pacman -S $pkg"
            ;;
        ubuntu|debian|linuxmint|pop)
            local deb_pkg=$pkg
            # Certains packages ont des noms différents sur Debian/Ubuntu
            case $pkg in
                fd) deb_pkg="fd-find" ;;
                ripgrep) deb_pkg="ripgrep" ;;
            esac
            echo "   → sudo apt install $deb_pkg"
            ;;
        fedora|rhel|centos)
            echo "   → sudo dnf install $pkg"
            ;;
        opensuse*|suse)
            echo "   → sudo zypper install $pkg"
            ;;
        gentoo)
            echo "   → sudo emerge $pkg"
            ;;
        *)
            echo "   → Installez via votre gestionnaire de paquets"
            ;;
    esac
}

# Vérifier les outils recommandés
echo "=== Outils de base ==="
command_exists "fzf" && echo "✅ fzf" || suggest_install "fzf"
command_exists "fd" && echo "✅ fd" || suggest_install "fd"
command_exists "rg" && echo "✅ ripgrep" || suggest_install "ripgrep"
command_exists "zoxide" && echo "✅ zoxide" || suggest_install "zoxide"

echo ""
echo "=== Visualiseurs ==="
command_exists "feh" && echo "✅ feh" || suggest_install "feh"
command_exists "mpv" && echo "✅ mpv" || suggest_install "mpv"
command_exists "zathura" && echo "✅ zathura" || suggest_install "zathura"
command_exists "glow" && echo "✅ glow" || suggest_install "glow"

echo ""
echo "=== Utilitaires ==="
command_exists "unar" && echo "✅ unar" || suggest_install "unar"
command_exists "7z" && echo "✅ 7z (p7zip)" || suggest_install "p7zip"
command_exists "jq" && echo "✅ jq" || suggest_install "jq"
command_exists "bat" && echo "✅ bat" || suggest_install "bat"

echo ""
echo "=== Dépendances preview (optionnelles) ==="
command_exists "ffmpegthumbnailer" && echo "✅ ffmpegthumbnailer" || suggest_install "ffmpegthumbnailer"
command_exists "imagemagick" && echo "✅ imagemagick" || suggest_install "imagemagick"
command_exists "poppler" && echo "✅ poppler (pdftotext)" || suggest_install "poppler-utils"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Configuration de Yazi pour Linux terminée!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Redémarrez votre shell: source $SHELL_CONFIG"
echo "2. Lancez Yazi avec: y"
echo "3. Appuyez sur ~ ou ? pour voir l'aide des raccourcis"
echo ""
echo "💡 Configuration terminal:"
echo "• Éditez ~/.config/yazi/keymap.toml ligne 'Terminal'"
echo "• Décommentez la ligne correspondant à votre terminal"
echo "  (kitty, alacritty, gnome-terminal, konsole, etc.)"
echo ""
echo "💡 Conseils:"
echo "• Utilisez 'y' au lieu de 'yazi' pour changer de dossier à la sortie"
echo "• Appuyez sur 'g<Space>' pour la navigation interactive"
echo "• Utilisez 'm' pour sauver un marque-page, ' pour y accéder"
echo "• Appuyez sur 'R' pour renommer en masse plusieurs fichiers"
echo "• Appuyez sur 'T' pour ouvrir un terminal dans le dossier actuel"
echo ""
echo "🔗 Documentation: https://yazi-rs.github.io"
echo ""
