#!/usr/bin/env bash

set -u

# ==========================================================
# Debian Testing - Script de diagnostic
# ==========================================================

echo "=========================================================="
echo "          DIAGNOSTIC DEBIAN TESTING"
echo "=========================================================="
echo

# ----------------------------------------------------------
# Fonction d'affichage
# ----------------------------------------------------------

section() {
    echo
    echo "----------------------------------------------------------"
    echo "$1"
    echo "----------------------------------------------------------"
}

# ----------------------------------------------------------
# Vérification root
# ----------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "ERREUR : ce script doit être lancé avec sudo."
    echo
    echo "Exemple :"
    echo "  sudo $0"
    exit 1
fi

# ----------------------------------------------------------
# Informations système
# ----------------------------------------------------------

section "1. INFORMATIONS SYSTÈME"

echo "Hostname : $(hostname)"
echo "Date     : $(date)"
echo "Kernel   : $(uname -r)"
echo "Arch     : $(dpkg --print-architecture)"

if [[ -f /etc/debian_version ]]; then
    echo "Debian   : $(cat /etc/debian_version)"
fi

if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a 2>/dev/null
fi

# ----------------------------------------------------------
# Espace disque
# ----------------------------------------------------------

section "2. ESPACE DISQUE"

df -h /

echo
echo "Partition /boot :"

if mountpoint -q /boot; then
    df -h /boot
else
    echo "/boot fait partie de la partition racine."
fi

# ----------------------------------------------------------
# Vérification des systèmes de fichiers
# ----------------------------------------------------------

section "3. UTILISATION DES INODES"

df -ih /

# ----------------------------------------------------------
# DPKG audit
# ----------------------------------------------------------

section "4. DPKG --AUDIT"

dpkg --audit

if [[ $? -eq 0 ]]; then
    echo "Aucun problème détecté par dpkg --audit."
fi

# ----------------------------------------------------------
# Vérification APT
# ----------------------------------------------------------

section "5. APT CHECK"

apt-get check

if [[ $? -eq 0 ]]; then
    echo "APT ne détecte aucune dépendance cassée."
fi

# ----------------------------------------------------------
# Paquets en hold
# ----------------------------------------------------------

section "6. PAQUETS EN HOLD"

holds=$(apt-mark showhold)

if [[ -z "$holds" ]]; then
    echo "Aucun paquet en hold."
else
    echo "$holds"
fi

# ----------------------------------------------------------
# Paquets pouvant être supprimés
# ----------------------------------------------------------

section "7. AUTOREMOVE --DRY-RUN"

apt-get autoremove --dry-run

# ----------------------------------------------------------
# Paquets pouvant être mis à jour
# ----------------------------------------------------------

section "8. PAQUETS UPGRADABLES"

apt list --upgradable 2>/dev/null

# ----------------------------------------------------------
# Simulation d'un full-upgrade
# ----------------------------------------------------------

section "9. SIMULATION FULL-UPGRADE"

apt-get -s full-upgrade

# ----------------------------------------------------------
# Services échoués
# ----------------------------------------------------------

section "10. SERVICES EN ÉCHEC"

failed_services=$(systemctl --failed --no-legend)

if [[ -z "$failed_services" ]]; then
    echo "Aucun service en échec."
else
    systemctl --failed
fi

# ----------------------------------------------------------
# Services activés
# ----------------------------------------------------------

section "11. SERVICES ACTIFS EN ERREUR"

journalctl -p err -b --no-pager -n 50

# ----------------------------------------------------------
# Kernel
# ----------------------------------------------------------

section "12. KERNEL"

echo "Kernel actuellement utilisé :"
uname -r

echo
echo "Kernels installés :"

dpkg -l 'linux-image*' 2>/dev/null | \
    grep '^ii' || echo "Aucun paquet linux-image trouvé."

# ----------------------------------------------------------
# Paquets cassés
# ----------------------------------------------------------

section "13. PAQUETS AVEC ÉTAT ANORMAL"

dpkg -l | awk '
$1 ~ /^(..r|..H|..F|..U|..W|..t|..A|..C|..I)$/ {
    print
}
'

# ----------------------------------------------------------
# Journal APT
# ----------------------------------------------------------

section "14. DERNIÈRES OPÉRATIONS APT"

if [[ -f /var/log/apt/history.log ]]; then
    tail -n 80 /var/log/apt/history.log
else
    echo "Aucun historique APT trouvé."
fi

# ----------------------------------------------------------
# Erreurs du boot actuel
# ----------------------------------------------------------

section "15. ERREURS JOURNALCTL - BOOT ACTUEL"

journalctl -p err -b --no-pager

# ----------------------------------------------------------
# Erreurs du kernel
# ----------------------------------------------------------

section "16. ERREURS KERNEL"

journalctl -k -p err -b --no-pager

# ----------------------------------------------------------
# Paquets orphelins potentiels
# ----------------------------------------------------------

section "17. PAQUETS AUTOMATIQUEMENT INSTALLÉS"

echo "Nombre de paquets installés automatiquement :"

apt-mark showauto | wc -l

# ----------------------------------------------------------
# Sources APT
# ----------------------------------------------------------

section "18. SOURCES APT"

echo "Sources actuellement configurées :"
echo

grep -RhsE '^[[:space:]]*(deb|Types:)' \
    /etc/apt/sources.list \
    /etc/apt/sources.list.d/ \
    2>/dev/null || true

# ----------------------------------------------------------
# FIN
# ----------------------------------------------------------

echo
echo "=========================================================="
echo "             DIAGNOSTIC TERMINÉ"
echo "=========================================================="
echo
echo "Aucune modification n'a été effectuée par ce script."
echo