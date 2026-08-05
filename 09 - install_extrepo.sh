#!/usr/bin/env bash
#
# install-extrepo.sh
# Installation et configuration d'extrepo sur Debian 13 (Trixie)
#
# extrepo est l'outil officiel Debian pour activer des dépôts tiers
# vérifiés (Google Chrome, VS Code, Docker, etc.) sans avoir à gérer
# manuellement les clés GPG et les fichiers sources.list.
#
# Usage:
#   sudo ./install-extrepo.sh [OPTIONS] [DEPOT...]
#
# Options:
#   -n, --dry-run        Affiche les actions sans les exécuter
#   -c, --contrib         Active la policy "contrib" dans config.yaml
#   -f, --non-free         Active la policy "non-free" dans config.yaml
#   -s, --search TERME     Recherche un dépôt disponible et quitte
#   -h, --help              Affiche cette aide
#
# Exemples:
#   sudo ./install-extrepo.sh --contrib --non-free google_chrome vscode
#   sudo ./install-extrepo.sh --dry-run docker
#   ./install-extrepo.sh --search chrome
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Constantes et couleurs
# ---------------------------------------------------------------------------
readonly CONFIG_FILE="/etc/extrepo/config.yaml"
readonly SCRIPT_NAME="$(basename "$0")"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

DRY_RUN=false
ENABLE_CONTRIB=false
ENABLE_NONFREE=false
SEARCH_TERM=""
REPOS=()

# ---------------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------------
log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[ATTENTION]${NC} $*"; }
log_error()   { echo -e "${RED}[ERREUR]${NC} $*" >&2; }

run_cmd() {
    # Exécute une commande, ou l'affiche seulement en mode dry-run
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

usage() {
    grep '^#' "$0" | sed -e 's/^#//' -e '1d'
    exit 0
}

check_root() {
    if [[ "$DRY_RUN" == false && $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté avec sudo (sauf en mode --dry-run ou --search)."
        exit 1
    fi
}

check_debian_version() {
    if [[ -f /etc/debian_version ]]; then
        local version
        version=$(cat /etc/debian_version)
        log_info "Version Debian détectée : ${version}"
    else
        log_warn "Impossible de confirmer qu'il s'agit bien de Debian. Poursuite quand même."
    fi
}

# ---------------------------------------------------------------------------
# Installation du paquet extrepo
# ---------------------------------------------------------------------------
install_extrepo() {
    if command -v extrepo &>/dev/null; then
        log_success "extrepo est déjà installé (idempotence respectée)."
        return 0
    fi

    log_info "Installation du paquet extrepo..."
    run_cmd apt-get update
    run_cmd apt-get install -y extrepo
    log_success "extrepo installé."
}

# ---------------------------------------------------------------------------
# Activation des policies contrib / non-free dans config.yaml
# ---------------------------------------------------------------------------
enable_policies() {
    if [[ "$ENABLE_CONTRIB" == false && "$ENABLE_NONFREE" == false ]]; then
        log_info "Aucune policy supplémentaire demandée (contrib/non-free). Seul 'main' restera actif."
        return 0
    fi

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Fichier de configuration introuvable : ${CONFIG_FILE}"
        log_error "extrepo est-il bien installé ?"
        exit 1
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Modification de ${CONFIG_FILE} pour activer :"
        [[ "$ENABLE_CONTRIB" == true ]] && echo "  - contrib"
        [[ "$ENABLE_NONFREE" == true ]] && echo "  - non-free"
        return 0
    fi

    local changed=false

    if [[ "$ENABLE_CONTRIB" == true ]]; then
        if grep -qE '^\s*#\s*-\s*contrib\s*$' "$CONFIG_FILE"; then
            sed -i -E 's/^\s*#\s*-\s*contrib\s*$/- contrib/' "$CONFIG_FILE"
            log_success "Policy 'contrib' activée."
            changed=true
        elif grep -qE '^\s*-\s*contrib\s*$' "$CONFIG_FILE"; then
            log_success "Policy 'contrib' déjà active (idempotence respectée)."
        else
            log_warn "Ligne 'contrib' introuvable dans ${CONFIG_FILE}, à vérifier manuellement."
        fi
    fi

    if [[ "$ENABLE_NONFREE" == true ]]; then
        if grep -qE '^\s*#\s*-\s*non-free\s*$' "$CONFIG_FILE"; then
            sed -i -E 's/^\s*#\s*-\s*non-free\s*$/- non-free/' "$CONFIG_FILE"
            log_success "Policy 'non-free' activée."
            changed=true
        elif grep -qE '^\s*-\s*non-free\s*$' "$CONFIG_FILE"; then
            log_success "Policy 'non-free' déjà active (idempotence respectée)."
        else
            log_warn "Ligne 'non-free' introuvable dans ${CONFIG_FILE}, à vérifier manuellement."
        fi
    fi

    if [[ "$changed" == true ]]; then
        log_info "Configuration mise à jour : ${CONFIG_FILE}"
    fi
}

# ---------------------------------------------------------------------------
# Recherche d'un dépôt (mode --search)
# ---------------------------------------------------------------------------
search_repo() {
    local term="$1"
    if ! command -v extrepo &>/dev/null; then
        log_error "extrepo n'est pas installé. Lancez d'abord le script sans --search."
        exit 1
    fi
    log_info "Recherche de dépôts correspondant à : ${term}"
    extrepo search "$term"
}

# ---------------------------------------------------------------------------
# Activation des dépôts demandés
# ---------------------------------------------------------------------------
enable_repos() {
    if [[ ${#REPOS[@]} -eq 0 ]]; then
        log_info "Aucun dépôt spécifié à activer. Utilisez 'extrepo search <terme>' pour explorer."
        return 0
    fi

    for repo in "${REPOS[@]}"; do
        log_info "Traitement du dépôt : ${repo}"

        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY-RUN] extrepo enable ${repo}"
            continue
        fi

        # Vérifie l'idempotence : le dépôt est-il déjà activé ?
        if [[ -f "/etc/apt/sources.list.d/extrepo_${repo}.sources" ]]; then
            log_success "Dépôt '${repo}' déjà activé (idempotence respectée)."
            continue
        fi

        if extrepo enable "$repo"; then
            log_success "Dépôt '${repo}' activé avec succès."
        else
            log_error "Échec de l'activation du dépôt '${repo}'. Vérifiez le nom avec 'extrepo search'."
        fi
    done
}

# ---------------------------------------------------------------------------
# Mise à jour des métadonnées extrepo et d'APT
# ---------------------------------------------------------------------------
update_and_refresh() {
    log_info "Mise à jour des métadonnées extrepo..."
    run_cmd extrepo update

    log_info "Mise à jour de la liste des paquets APT..."
    run_cmd apt-get update

    log_success "Terminé. Les dépôts activés sont disponibles via apt."
}

# ---------------------------------------------------------------------------
# Analyse des arguments
# ---------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--contrib)
                ENABLE_CONTRIB=true
                shift
                ;;
            -f|--non-free)
                ENABLE_NONFREE=true
                shift
                ;;
            -s|--search)
                SEARCH_TERM="${2:-}"
                if [[ -z "$SEARCH_TERM" ]]; then
                    log_error "--search nécessite un terme de recherche."
                    exit 1
                fi
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            -*)
                log_error "Option inconnue : $1"
                usage
                ;;
            *)
                REPOS+=("$1")
                shift
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Point d'entrée principal
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"

    echo -e "${BOLD}=== Installation et configuration d'extrepo — Debian 13 ===${NC}"
    echo

    if [[ -n "$SEARCH_TERM" ]]; then
        search_repo "$SEARCH_TERM"
        exit 0
    fi

    check_root
    check_debian_version
    install_extrepo
    enable_policies
    enable_repos
    update_and_refresh

    echo
    log_success "Script terminé avec succès."
    if [[ ${#REPOS[@]} -gt 0 && "$DRY_RUN" == false ]]; then
        log_info "Vous pouvez maintenant installer vos paquets, par exemple :"
        echo "  sudo apt install <nom-du-paquet>"
    fi
}

main "$@"