#!/usr/bin/env bash
#
# install-icon-fonts.sh
# Installe Font Awesome (Free) et Material Design Icons sur Debian 13 (Trixie)
#
# Usage:
#   ./install-icon-fonts.sh [--dry-run]
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
DRY_RUN=false
FONT_DIR="${HOME}/.local/share/fonts"
TMP_DIR="$(mktemp -d)"

FA_VERSION="6.7.2"
FA_URL="https://github.com/FortAwesome/Font-Awesome/releases/download/${FA_VERSION}/fontawesome-free-${FA_VERSION}-desktop.zip"

MDI_REPO="https://github.com/Templarian/MaterialDesign-Webfont"
MDI_RAW="https://raw.githubusercontent.com/Templarian/MaterialDesign-Webfont/master/fonts"

# ---------------------------------------------------------------------------
# Couleurs / logging
# ---------------------------------------------------------------------------
readonly C_RESET='\033[0m'
readonly C_INFO='\033[0;36m'
readonly C_OK='\033[0;32m'
readonly C_WARN='\033[0;33m'
readonly C_ERR='\033[0;31m'

log_info()  { echo -e "${C_INFO}[INFO]${C_RESET}  $*"; }
log_ok()    { echo -e "${C_OK}[ OK ]${C_RESET}  $*"; }
log_warn()  { echo -e "${C_WARN}[WARN]${C_RESET}  $*"; }
log_err()   { echo -e "${C_ERR}[FAIL]${C_RESET}  $*" >&2; }

# ---------------------------------------------------------------------------
# Wrapper d'exécution (respecte --dry-run)
# ---------------------------------------------------------------------------
run() {
    if [[ "${DRY_RUN}" == true ]]; then
        echo -e "${C_WARN}[DRY-RUN]${C_RESET} $*"
    else
        "$@"
    fi
}

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Dépendances requises
# ---------------------------------------------------------------------------
check_dependencies() {
    local deps=(curl unzip fc-cache)
    local missing=()

    for dep in "${deps[@]}"; do
        command -v "${dep}" &>/dev/null || missing+=("${dep}")
    done

    if (( ${#missing[@]} > 0 )); then
        log_warn "Dépendances manquantes : ${missing[*]}"
        run sudo apt update
        run sudo apt install -y curl unzip fontconfig
    fi
}

# ---------------------------------------------------------------------------
# Font Awesome (Free desktop fonts, via GitHub release)
# ---------------------------------------------------------------------------
install_font_awesome() {
    log_info "Installation de Font Awesome ${FA_VERSION}..."

    if fc-list | grep -qi "Font Awesome 6 Free"; then
        log_ok "Font Awesome déjà installé, aucune action requise."
        return 0
    fi

    local zip_path="${TMP_DIR}/fontawesome.zip"
    local extract_dir="${TMP_DIR}/fontawesome"

    run curl -sSL "${FA_URL}" -o "${zip_path}"
    run mkdir -p "${extract_dir}"
    run unzip -qo "${zip_path}" -d "${extract_dir}"

    local otf_dir
    otf_dir=$(find "${extract_dir}" -type d -name "otfs" | head -n1)

    if [[ -z "${otf_dir}" && "${DRY_RUN}" == false ]]; then
        log_err "Impossible de localiser les polices .otf dans l'archive Font Awesome."
        return 1
    fi

    run mkdir -p "${FONT_DIR}/font-awesome"
    run bash -c "cp '${otf_dir}'/*.otf '${FONT_DIR}/font-awesome/'"

    log_ok "Font Awesome installé dans ${FONT_DIR}/font-awesome"
}

# ---------------------------------------------------------------------------
# Material Design Icons (webfont TTF, via GitHub raw)
# ---------------------------------------------------------------------------
install_material_design_icons() {
    log_info "Installation de Material Design Icons..."

    if fc-list | grep -qi "Material Design Icons"; then
        log_ok "Material Design Icons déjà installé, aucune action requise."
        return 0
    fi

    run mkdir -p "${FONT_DIR}/material-design-icons"
    run curl -sSL "${MDI_RAW}/materialdesignicons-webfont.ttf" \
        -o "${FONT_DIR}/material-design-icons/materialdesignicons-webfont.ttf"

    log_ok "Material Design Icons installé dans ${FONT_DIR}/material-design-icons"
}

# ---------------------------------------------------------------------------
# Rafraîchissement du cache de polices
# ---------------------------------------------------------------------------
refresh_font_cache() {
    log_info "Rafraîchissement du cache fontconfig..."
    run fc-cache -f "${FONT_DIR}"
    log_ok "Cache de polices mis à jour."
}

# ---------------------------------------------------------------------------
# Parsing des arguments
# ---------------------------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--dry-run]"
                exit 0
                ;;
            *)
                log_err "Argument inconnu : $1"
                exit 1
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"

    [[ "${DRY_RUN}" == true ]] && log_warn "Mode --dry-run activé : aucune modification réelle ne sera effectuée."

    check_dependencies
    install_font_awesome
    install_material_design_icons
    refresh_font_cache

    log_ok "Installation terminée. Vérifie avec : fc-list | grep -Ei 'font awesome|material design'"
}

main "$@"