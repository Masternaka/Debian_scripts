#!/bin/bash

# --- Pas de set -e : gestion manuelle des erreurs pour éviter les faux positifs ---

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERREUR]${NC} $1"; }

# =============================================================================
# 1. Vérification des droits root
# =============================================================================
if [[ $EUID -ne 0 ]]; then
    log_error "Ce script doit être exécuté en tant que root (sudo $0)"
fi

# =============================================================================
# 2. Détection de la distribution
# =============================================================================
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    DISTRO="${ID}"
    DISTRO_BASE="${ID_LIKE:-$ID}"
else
    log_error "Impossible de détecter la distribution Linux."
fi

log_info "Distribution détectée : ${PRETTY_NAME}"

case "$DISTRO" in
    debian|ubuntu|linuxmint|pop|elementary|zorin)
        log_success "Distribution compatible."
        ;;
    *)
        if echo "$DISTRO_BASE" | grep -qiE "debian|ubuntu"; then
            log_warn "Distribution basée sur Debian/Ubuntu — poursuite du script."
        else
            log_error "Distribution non supportée : $DISTRO"
        fi
        ;;
esac

# =============================================================================
# 3. Vérification du module noyau zram
# =============================================================================
log_info "Vérification du module noyau zram..."
if ! modinfo zram &>/dev/null; then
    log_error "Le module noyau 'zram' n'est pas disponible sur ce système."
fi
log_success "Module zram disponible."

# =============================================================================
# 4. Vérification du support zstd par le noyau
#    zstd disponible à partir du noyau 5.3 — nécessite de charger zram d'abord
# =============================================================================
log_info "Vérification du support zstd par le noyau..."

COMPRESSION_ALGO="zstd"

# Chargement temporaire du module zram pour lire comp_algorithm
modprobe zram 2>/dev/null || true

if [[ -f /sys/block/zram0/comp_algorithm ]]; then
    if grep -q "zstd" /sys/block/zram0/comp_algorithm; then
        log_success "zstd supporté par le noyau."
    else
        log_warn "zstd non supporté par ce noyau — utilisation de lzo-rle à la place."
        COMPRESSION_ALGO="lzo-rle"
    fi
else
    log_warn "Impossible de vérifier comp_algorithm — zstd supposé supporté."
fi

# =============================================================================
# 5. Détection de zram-tools (sans le désactiver/désinstaller)
# =============================================================================
if dpkg -l zram-tools &>/dev/null 2>&1; then
    log_warn "Paquet zram-tools détecté. Ce script n'y touche plus, mais il peut entrer en conflit"
    log_warn "avec systemd-zram-generator (double configuration ZRAM : zramswap vs zram-generator)."
    log_warn "Vérifiez que vous n'activez pas deux mécanismes ZRAM simultanément."
fi

# =============================================================================
# 6. Installation de systemd-zram-generator (si pas déjà présent)
# =============================================================================
if dpkg -l systemd-zram-generator &>/dev/null 2>&1; then
    log_info "systemd-zram-generator déjà installé — mise à jour ignorée."
else
    log_info "Mise à jour des paquets et installation de systemd-zram-generator..."
    apt update -qq
    # stderr laissé visible pour ne pas masquer les vraies erreurs d'installation
    if ! apt install -y systemd-zram-generator > /dev/null; then
        log_error "Échec de l'installation de systemd-zram-generator."
    fi
    log_success "systemd-zram-generator installé."
fi

# =============================================================================
# 7. Écriture de la configuration zram-generator
#
#    zram-size = ram / 2  → syntaxe officielle du générateur (expression dynamique
#                            évaluée au démarrage, pas de calcul manuel en Mo)
#    compression-algorithm → zstd (ou lzo-rle si noyau trop ancien)
#    swap-priority         → 100
#    fs-type               → swap (type défini explicitement)
# =============================================================================
ZRAM_CONF_DIR="/etc/systemd/zram-generator.conf.d"
ZRAM_CONF="${ZRAM_CONF_DIR}/zram.conf"

mkdir -p "$ZRAM_CONF_DIR"
log_info "Écriture de la configuration dans ${ZRAM_CONF}..."

cat > "$ZRAM_CONF" <<EOF
# =============================================================
#  Configuration ZRAM — généré par install_zram.sh
#  Outil : systemd-zram-generator
# =============================================================

[zram0]

# Taille = 50% de la RAM (expression évaluée dynamiquement au démarrage)
zram-size = ram / 2

# Algorithme de compression
compression-algorithm = ${COMPRESSION_ALGO}

# Priorité du swap (100 = préféré par rapport au swap disque)
swap-priority = 100

# Type explicitement défini à swap
# Valeurs possibles : swap | ext2 | ext4 | btrfs | xfs | tmpfs ...
fs-type = swap
EOF

log_success "Fichier de configuration écrit (compression: ${COMPRESSION_ALGO})."

# =============================================================================
# 8. Abaissement de la priorité de TOUS les swaps disque/fichier
#    Objectif : le ZRAM (priorité 100) doit toujours être utilisé en premier,
#    quel que soit le type de swap classique (fichier ou partition).
# =============================================================================
FSTAB="/etc/fstab"

if grep -qE '^[^#].*\sswap\s' "$FSTAB"; then
    log_info "Entrées swap détectées dans /etc/fstab."

    # Validation préalable de /etc/fstab pour éviter de casser le boot
    if ! mount -a -f &>/dev/null; then
        log_error "/etc/fstab contient déjà des erreurs. Abandon des modifications sur ce fichier."
    else
        log_info "/etc/fstab validé avec succès (mount -a -f)."
    fi

    log_info "Abaissement de la priorité des swaps disque/fichier à -10 (hors ZRAM)..."

    # Sauvegarde horodatée pour ne pas écraser l'original si le script est relancé
    FSTAB_BAK="${FSTAB}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$FSTAB" "$FSTAB_BAK"
    log_info "Sauvegarde créée : ${FSTAB_BAK}"

    # Pour chaque ligne swap (hors zram), si aucune priorité n'est définie, on ajoute ,pri=-10
    # Exemple de ligne ciblée : UUID=... none swap sw 0 0
    sed -i -E '/^\s*#/! {/swap/ && !/zram/ && !/pri=/{s/(sw)/\1,pri=-10/}}' "$FSTAB"

    # Revalidation après modification
    if mount -a -f &>/dev/null; then
        log_success "Priorité des entrées swap disque/fichier abaissée à -10 (hors ZRAM) dans /etc/fstab."
    else
        log_warn "/etc/fstab modifié mais mount -a -f signale une erreur. Pensez à vérifier manuellement le fichier."
    fi
else
    log_info "Aucune entrée swap disque/fichier détectée dans /etc/fstab — aucune modification nécessaire."
fi

# Réapplication immédiate des priorités sur les swaps ACTIFS (hors ZRAM)
if command -v swapon &>/dev/null; then
    log_info "Ajustement immédiat de la priorité des swaps actifs (hors ZRAM) à -10..."
    # On lit /proc/swaps pour lister les périphériques/fichiers actifs, et on exclut /dev/zram*
    awk 'NR>1 {print $1}' /proc/swaps | grep -v '^/dev/zram' | while read -r SWAP_DEV; do
        if swapoff "$SWAP_DEV" 2>/dev/null; then
            if swapon -p -10 "$SWAP_DEV" 2>/dev/null; then
                log_success "Swap ${SWAP_DEV} réactivé avec priorité -10."
            else
                log_warn "Impossible de réactiver ${SWAP_DEV} avec priorité -10 — il sera pris en compte au prochain démarrage."
            fi
        else
            log_warn "Impossible de désactiver temporairement ${SWAP_DEV} — priorité non ajustée immédiatement."
        fi
    done
else
    log_warn "Commande swapon introuvable — impossibilité d'ajuster immédiatement les swaps actifs."
fi

# =============================================================================
# 9. Rechargement de systemd et activation du zram
# =============================================================================
log_info "Rechargement de systemd..."
systemctl daemon-reload

log_info "Activation du périphérique zram0..."
if systemctl start dev-zram0.swap; then
    log_success "Périphérique zram0 activé comme swap."
else
    log_error "Échec de l'activation de zram0. Vérifiez : journalctl -xe"
fi

# =============================================================================
# 10. Récapitulatif — taille lue depuis zramctl (valeur réelle du noyau)
# =============================================================================
sleep 1

TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))

# Lecture de la taille réelle allouée par le noyau via zramctl
if command -v zramctl &>/dev/null; then
    ZRAM_REAL_SIZE=$(zramctl --noheadings --output DISKSIZE /dev/zram0 2>/dev/null || echo "N/A")
else
    ZRAM_REAL_SIZE="N/A (zramctl non disponible)"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   ZRAM configuré avec succès !${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "  ${BLUE}Compression${NC}  : ${COMPRESSION_ALGO}"
echo -e "  ${BLUE}Taille swap${NC}  : ${ZRAM_REAL_SIZE}  (50% de ${TOTAL_RAM_MB} Mo)"
echo -e "  ${BLUE}Priorité${NC}     : 100  (swapfile abaissé à -10)"
echo -e "  ${BLUE}Type${NC}         : swap  (défini via fs-type)"
echo ""

log_info "Périphériques zram actifs :"
if command -v zramctl &>/dev/null; then
    zramctl
else
    log_warn "zramctl non disponible."
fi

echo ""
log_info "Partitions swap actives (ordre d'utilisation) :"
swapon --show

echo ""
log_success "Installation terminée. Le zram swap sera actif à chaque démarrage."