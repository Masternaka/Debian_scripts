#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; exit 1; }

[[ $EUID -ne 0 ]] && error "Ce script doit être exécuté en root (sudo)."

echo -e "\n${BOLD}=== Installation de Samba — Ubuntu ===${RESET}\n"

# ── 1. Installation ───────────────────────────────────────────────────────────
info "Mise à jour des paquets..."
apt-get update -qq

info "Installation de samba et samba-common-bin..."
apt-get install -y samba samba-common-bin

success "Samba installé."

# ── 2. Sauvegarde + configuration smb.conf ────────────────────────────────────
SMB_CONF="/etc/samba/smb.conf"

if [[ -f "$SMB_CONF" ]]; then
    BACKUP="${SMB_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
    info "Sauvegarde de l'ancienne config : $BACKUP"
    cp "$SMB_CONF" "$BACKUP"
fi

info "Écriture d'un smb.conf minimal..."
cat > "$SMB_CONF" <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = Samba Server %v
   server role = standalone server
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   panic action = /usr/share/samba/panic-action %d
   server schannel = yes
   map to guest = bad user
   usershare allow guests = no

# ── Exemple de partage (décommenter et adapter) ──────────────────────────────
# [partage]
#    path = /srv/samba/partage
#    browsable = yes
#    writable = yes
#    guest ok = no
#    valid users = @samba
EOF
success "smb.conf configuré : $SMB_CONF"

# ── 3. Services ───────────────────────────────────────────────────────────────
info "Activation et démarrage des services smbd et nmbd..."
systemctl enable --now smbd nmbd
success "Services smbd et nmbd actifs."

# ── 4. Firewall (ufw) ─────────────────────────────────────────────────────────
echo
info "Configuration du firewall..."

if command -v ufw &>/dev/null; then
    UFW_STATUS=$(ufw status | head -1)
    info "ufw détecté — statut : $UFW_STATUS"
    ufw allow Samba
    success "Règles Samba ajoutées dans ufw."
    # S'assurer que ufw est actif
    if echo "$UFW_STATUS" | grep -q "inactive"; then
        warn "ufw est inactif. Activation..."
        ufw --force enable
        success "ufw activé."
    fi

elif command -v firewall-cmd &>/dev/null; then
    info "firewalld détecté (inhabituel sur Ubuntu, mais supporté)."
    systemctl enable --now firewalld
    firewall-cmd --permanent --add-service=samba
    firewall-cmd --reload
    success "Règles Samba ajoutées dans firewalld."

else
    warn "Aucun firewall reconnu — configuration manuelle requise."
    warn "Ports à ouvrir : TCP 139, TCP 445, UDP 137, UDP 138"
fi

# ── 5. Résumé ─────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}=== Installation terminée ===${RESET}"
echo -e "  • Fichier de config : ${CYAN}$SMB_CONF${RESET}"
echo -e "  • Ajouter un utilisateur Samba : ${CYAN}smbpasswd -a <utilisateur>${RESET}"
echo -e "  • Vérifier la config : ${CYAN}testparm${RESET}"
echo -e "  • Statut des services : ${CYAN}systemctl status smbd nmbd${RESET}"
echo