#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo "   Maintenance Debian Testing"
echo "=========================================="
echo

# Vérification des droits
if [[ $EUID -ne 0 ]]; then
    echo "Erreur : lance ce script avec sudo."
    exit 1
fi

# Vérification des paquets partiellement configurés
echo "==> Vérification de dpkg..."
dpkg --audit || true
echo

# Mise à jour de l'index APT
echo "==> Mise à jour des dépôts..."
apt update
echo

# Affichage des paquets pouvant être mis à jour
echo "==> Paquets disponibles pour mise à jour :"
apt list --upgradable 2>/dev/null || true
echo

read -rp "Continuer avec 'apt full-upgrade' ? [o/N] " answer

if [[ "$answer" != "o" && "$answer" != "O" ]]; then
    echo "Mise à jour annulée."
    exit 0
fi

echo
echo "==> Mise à jour du système..."
apt full-upgrade
echo

# Nettoyage
echo "==> Recherche des paquets devenus inutiles..."
apt autoremove
echo

echo "==> Nettoyage du cache APT..."
apt autoclean
echo

# Vérification finale
echo "==> Vérification finale..."
dpkg --audit || true

echo
echo "=========================================="
echo "Maintenance terminée."
echo "=========================================="
echo

echo "Redémarrage recommandé si un nouveau noyau"
echo "ou des composants système importants ont été installés."