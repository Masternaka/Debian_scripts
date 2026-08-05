#!/bin/bash

#===============================================================================
# Installation automatique : Brave, Vivaldi, Fresh
# Téléchargement depuis les dépôts/serveurs officiels
#===============================================================================

set -e

# Couleurs
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Vérification des droits root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Ce script doit être exécuté en tant que root (sudo).${NC}"
   exit 1
fi

# Détection de la distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}Impossible de détecter la distribution.${NC}"
        exit 1
    fi
}

# Installation des dépendances communes
install_deps() {
    case $DISTRO in
        ubuntu|debian)
            apt update && apt install -y curl wget gnupg apt-transport-https
            ;;
        fedora)
            dnf install -y curl wget gnupg
            ;;
        *)
            echo -e "${YELLOW}Distribution non prise en charge directement. Essayez l'installation manuelle.${NC}"
            ;;
    esac
}

# ---------- Brave ----------
install_brave() {
    echo -e "${GREEN}>>> Installation de Brave...${NC}"
    case $DISTRO in
        ubuntu|debian)
            curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | \
                gpg --dearmor -o /usr/share/keyrings/brave-browser-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
                https://brave-browser-apt-release.s3.brave.com/ stable main" > \
                /etc/apt/sources.list.d/brave-browser-release.list
            apt update && apt install -y brave-browser
            ;;
        fedora)
            dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
            rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            dnf install -y brave-browser
            ;;
        *)
            echo -e "${YELLOW}Brave : installation non automatisée pour $DISTRO.${NC}"
            echo "Visitez https://brave.com/download/"
            ;;
    esac
}

# ---------- Vivaldi ----------
install_vivaldi() {
    echo -e "${GREEN}>>> Installation de Vivaldi...${NC}"
    case $DISTRO in
        ubuntu|debian)
            wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | \
                gpg --dearmor -o /usr/share/keyrings/vivaldi-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/vivaldi-archive-keyring.gpg arch=amd64] \
                https://repo.vivaldi.com/stable/deb/ stable main" > \
                /etc/apt/sources.list.d/vivaldi.list
            apt update && apt install -y vivaldi-stable
            ;;
        fedora)
            dnf config-manager --add-repo https://repo.vivaldi.com/archive/vivaldi-fedora.repo
            dnf install -y vivaldi-stable
            ;;
        *)
            echo -e "${YELLOW}Vivaldi : installation non automatisée pour $DISTRO.${NC}"
            echo "Visitez https://vivaldi.com/download/"
            ;;
    esac
}

# ---------- Fresh ----------
install_fresh() {
    echo -e "${GREEN}>>> Installation de Fresh (getfresh.dev)...${NC}"
    if command -v curl &>/dev/null; then
        curl -fsSL https://getfresh.dev/install.sh | bash
    else
        wget -qO- https://getfresh.dev/install.sh | bash
    fi
}

# ---------- Principal ----------
main() {
    detect_distro
    echo -e "${YELLOW}Distribution détectée : $DISTRO${NC}"
    install_deps

    echo
    echo "Que souhaitez-vous installer ?"
    echo "1) Brave uniquement"
    echo "2) Vivaldi uniquement"
    echo "3) Fresh uniquement"
    echo "4) Les trois"
    echo "5) Quitter"
    read -p "Votre choix [1-5] : " choice

    case $choice in
        1) install_brave ;;
        2) install_vivaldi ;;
        3) install_fresh ;;
        4) install_brave; install_vivaldi; install_fresh ;;
        5) echo "Annulé."; exit 0 ;;
        *) echo -e "${RED}Choix invalide.${NC}"; exit 1 ;;
    esac

    echo -e "${GREEN}Terminé.${NC}"
}

main "$@"