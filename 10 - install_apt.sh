#!/usr/bin/env bash

set -euo pipefail

BACKPORTS_SUITE="trixie-backports"
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
# PAQUETS À INSTALLER (à adapter)
# -------------------------------
OFFICIAL_PACKAGES=(

# Utilitaires
    ufw
    gufw
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
    debsecan
    fontconfig

# Utilitaires terminal
    btop
    fastfetch
    starship
    git
    curl
    wget
    ranger


# Sécurité
    keepassxc

# Multimédia
    strawberry
    vlc
    mpv

# Communication
    

# Office et notes
    

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
    neovim

# Langues
    libreoffice-l10n-fr
    firefox-l10n-fr
    thunderbird-l10n-fr 


)

BACKPORT_PACKAGES=(

# Kernel
linux-image-7.0.9+deb13-amd64
linux-headers-7.0.9+deb13-amd64

# Utilitaires
flameshot

# Office et notes
libreoffice


)

EXTREPO_PACKAGES=(

)

backports_enabled() {
    grep -Rqs "$BACKPORTS_SUITE" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null
}

extrepo_enabled() {
    # Vérifie qu'au moins un dépôt extrepo a été activé
    # (fichiers créés par 'extrepo enable' dans /etc/apt/sources.list.d)
    compgen -G "/etc/apt/sources.list.d/extrepo_*.sources" >/dev/null 2>&1
}

# -------------------------------
# MISE À JOUR
# -------------------------------
if [ ${#OFFICIAL_PACKAGES[@]} -eq 0 ] && [ ${#BACKPORT_PACKAGES[@]} -eq 0 ] && [ ${#EXTREPO_PACKAGES[@]} -eq 0 ]; then
    echo "Aucun paquet à installer. Remplis OFFICIAL_PACKAGES, BACKPORT_PACKAGES ou EXTREPO_PACKAGES."
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

if [ ${#BACKPORT_PACKAGES[@]} -gt 0 ]; then
    if ! backports_enabled; then
        echo "ERREUR : $BACKPORTS_SUITE n'est pas activé." >&2
        echo "Lance d'abord : sudo bash '08 - install_backports.sh'" >&2
        exit 1
    fi

    echo "Installation depuis les backports : ${BACKPORT_PACKAGES[*]}"
    run apt-get install -y -t "$BACKPORTS_SUITE" "${BACKPORT_PACKAGES[@]}"
fi

if [ ${#EXTREPO_PACKAGES[@]} -gt 0 ]; then
    if ! extrepo_enabled; then
        echo "ERREUR : Aucun dépôt extrepo n'est activé." >&2
        echo "Lance d'abord : sudo bash 'install-extrepo.sh' <nom-du-dépôt>" >&2
        exit 1
    fi

    echo "Installation depuis les dépôts extrepo : ${EXTREPO_PACKAGES[*]}"
    run apt-get install -y "${EXTREPO_PACKAGES[@]}"
fi

echo "Terminé."