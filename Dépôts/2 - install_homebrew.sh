#!/bin/bash

# -------------------------------------------------------------------
# Script d'installation de paquets avec Homebrew (Linux)
# Éditez la liste PACKAGES ci-dessous pour y mettre vos paquets.
# Usage : ./install_brew_packages.sh [paquet_supplementaire ...]
# -------------------------------------------------------------------

# ----- Liste des paquets (modifiez ici) -----
PACKAGES=(
    # Exemples (décommentez ou remplacez par vos paquets) :
    wget
    node
    python
    # htop
    # neovim
    # ripgrep
)
# ---------------------------------------------

# 1. Installer Homebrew si absent
if ! command -v brew &>/dev/null; then
    echo "Homebrew n'est pas installé. Installation en cours..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Ajouter Homebrew au PATH pour la session courante (Linux)
    if [ -d /home/linuxbrew/.linuxbrew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -d "$HOME/.linuxbrew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    else
        echo "Erreur : impossible de trouver l'installation de Homebrew." >&2
        exit 1
    fi
fi

# 2. Mettre à jour Homebrew
echo "Mise à jour de Homebrew..."
brew update

# 3. Fusionner la liste interne et les éventuels arguments (sans doublons)
ALL_PACKAGES=("${PACKAGES[@]}")
for arg in "$@"; do
    # Ajouter seulement s'il n'est pas déjà présent (évite un "already installed" mais ce n'est pas bloquant)
    if [[ ! " ${ALL_PACKAGES[*]} " =~ " ${arg} " ]]; then
        ALL_PACKAGES+=("$arg")
    fi
done

# Vérifier qu'il y a au moins un paquet à installer
if [ ${#ALL_PACKAGES[@]} -eq 0 ]; then
    echo "Aucun paquet à installer. Ajoutez des paquets dans le tableau PACKAGES ou passez-les en argument." >&2
    exit 1
fi

# 4. Installer chaque paquet
echo "Paquets à installer : ${ALL_PACKAGES[*]}"
for package in "${ALL_PACKAGES[@]}"; do
    echo "Installation de $package ..."
    brew install "$package"
done

echo "✅ Toutes les installations sont terminées."