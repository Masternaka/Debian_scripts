#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0

show_help() {
    echo "Usage: sudo $0 [--dry-run]"
    echo "  --dry-run  Affiche les commandes APT sans les exécuter."
}

for arg in "$@"; do
    case "$arg" in
        --dry-run|-n)
            DRY_RUN=1
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "ERREUR : Argument inconnu : $arg" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

[ "$EUID" -ne 0 ] && { echo "Lancer en root (sudo)."; exit 1; }

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf 'DRY-RUN:'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

# -------------------------------
# PAQUETS À INSTALLER
# -------------------------------
OFFICIAL_PACKAGES=(

# Kernel (Important, il faut vérifier la dernière version disponible sur le miroir officiel)
    linux-image-amd64
    linux-headers-amd64

# Utilitaires
    ufw
    gufw
    #firewalld
    #firewall-config
    catfish
    gnome-disk-utility
    gparted
    qbittorrent
    transmission-gtk
    lshw
    fwupd
    timeshift
    7zip
    unzip
    stow
    fontconfig
    font-manager
    gnome-system-tools
    synaptic
    flameshot
    xclip (x11 uniquement)
    #wl-clipboard (wayland uniquement)

# Utilitaires terminal
    btop
    fastfetch
    starship
    git
    curl
    wget
    ranger

# Sécurité
    #keepassxc (plus à jour que le paquet officiel, voir install_flatpak.sh)

# Multimédia
    strawberry
    vlc
    mpv

# Communication
    

# Office et notes
    libreoffice

# Virtualisation
    qemu
    virt-manager
    distrobox
    podman

# Terminal
    kitty
    #foot #wayland uniquement

# Développement
    micro
    meld
    hx
    #neovim

# Polices
    fonts-cascadia-code
    fonts-firacode
    fonts-hack
    fonts-jetbrains-mono
    fonts-noto
    fonts-font-awesome

# Langues
    libreoffice-l10n-fr
    firefox-l10n-fr
    thunderbird-l10n-fr 

# Debian Testing
    #extrepo (installer via le script install_extrepo.sh)
    debsecan
    listbugs
    apt-listchanges
)

# -------------------------------
# MISE À JOUR
# -------------------------------
if [ ${#OFFICIAL_PACKAGES[@]} -eq 0 ]; then
    echo "Aucun paquet à installer. Remplis OFFICIAL_PACKAGES."
    exit 0
fi

run apt-get update

# -------------------------------
# INSTALLATION
# -------------------------------
if [ ${#OFFICIAL_PACKAGES[@]} -gt 0 ]; then
    echo "Installation depuis les dépôts officiels : ${OFFICIAL_PACKAGES[*]}"
    run apt-get install -y "${OFFICIAL_PACKAGES[@]}"
fi

echo "Terminé."
