#!/usr/bin/env bash

set -euo pipefail

# --- Couleurs ---------------------------------------------------------
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'

log_info()  { printf "${C_BLUE}[INFO]${C_RESET}  %s\n" "$1"; }
log_ok()    { printf "${C_GREEN}[OK]${C_RESET}    %s\n" "$1"; }
log_warn()  { printf "${C_YELLOW}[WARN]${C_RESET}  %s\n" "$1"; }
log_err()   { printf "${C_RED}[ERREUR]${C_RESET} %s\n" "$1" >&2; }

# --- Variables --------------------------------------------------------
readonly SOURCES_DIR="/etc/apt/sources.list.d"
readonly CODENAME_EXPECTED="trixie"
readonly BACKPORTS_SUITE="trixie-backports"
DRY_RUN=0

# --- Arguments ----------------------------------------------------------
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --help|-h)
            echo "Usage: $0 [--dry-run]"
            exit 0
            ;;
        *)
            log_err "Argument inconnu : $arg"
            exit 1
            ;;
    esac
done

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf "${C_YELLOW}[DRY-RUN]${C_RESET} %s\n" "$*"
    else
        "$@"
    fi
}

# --- Vérifications préalables -------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
    log_err "Ce script doit être exécuté en root (sudo)."
    exit 1
fi

if ! command -v apt-get &>/dev/null; then
    log_err "apt-get introuvable. Ce script est destiné à Debian/Ubuntu."
    exit 1
fi

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ "${VERSION_CODENAME:-}" != "$CODENAME_EXPECTED" ]]; then
        log_warn "Ce système ne semble pas être Debian 13 (trixie) — codename détecté : ${VERSION_CODENAME:-inconnu}."
        log_warn "Le script va continuer, mais vérifie que c'est bien voulu."
    fi
fi

shopt -s nullglob
sources_files=("$SOURCES_DIR"/*.sources)
shopt -u nullglob

if [[ ${#sources_files[@]} -eq 0 ]]; then
    log_err "Aucun fichier *.sources trouvé dans $SOURCES_DIR."
    log_err "Ce système n'utilise probablement pas le format DEB822."
    exit 1
fi

# --- Déjà activé ? --------------------------------------------------------
if grep -l "$BACKPORTS_SUITE" "${sources_files[@]}" &>/dev/null; then
    existing_file=$(grep -l "$BACKPORTS_SUITE" "${sources_files[@]}" | head -n1)
    log_ok "$BACKPORTS_SUITE est déjà activé dans $existing_file."
    log_info "Mise à jour des index APT par précaution..."
    run apt-get update
    exit 0
fi

# --- Détection du bloc principal (miroir non-security) ---------------------
# On cherche le premier fichier .sources contenant un bloc dont l'URI ne
# référence pas security.debian.org, et on en extrait Types/URIs/Components/Signed-By.
main_file=""
main_block=""

for f in "${sources_files[@]}"; do
    block="$(awk -v RS='' '
        $0 ~ /URIs:/ && $0 !~ /security\.debian\.org/ { print; exit }
    ' "$f")"
    if [[ -n "$block" ]]; then
        main_file="$f"
        main_block="$block"
        break
    fi
done

if [[ -z "$main_block" ]]; then
    log_err "Impossible de détecter le bloc du miroir principal dans $SOURCES_DIR."
    log_err "Vérifie manuellement tes fichiers *.sources."
    exit 1
fi

extract_field() {
    local field="$1"
    printf '%s\n' "$main_block" | grep -m1 "^${field}:" | sed -E "s/^${field}:[[:space:]]*//"
}

types=$(extract_field "Types")
uris=$(extract_field "URIs")
components=$(extract_field "Components")
signed_by=$(extract_field "Signed-By")

if [[ -z "$types" || -z "$uris" ]]; then
    log_err "Champs Types/URIs introuvables dans le bloc détecté de $main_file."
    exit 1
fi

if [[ -z "$signed_by" ]]; then
    log_warn "Aucun champ Signed-By détecté (clé peut-être intégrée inline) — il sera omis du bloc backports."
fi

log_info "Miroir principal détecté dans $main_file :"
log_info "  URIs:       $uris"
log_info "  Components: ${components:-<non détecté>}"
[[ -n "$signed_by" ]] && log_info "  Signed-By:  $signed_by"

# --- Construction du nouveau bloc ------------------------------------------
new_block="Types: ${types}
URIs: ${uris}
Suites: ${BACKPORTS_SUITE}"
[[ -n "$components" ]] && new_block+="
Components: ${components}"
[[ -n "$signed_by" ]] && new_block+="
Signed-By: ${signed_by}"

log_info "Bloc à ajouter à $main_file :"
echo "----------------------------------------"
printf '%s\n' "$new_block"
echo "----------------------------------------"

backup_file="${main_file}.bak.$(date +%Y%m%d%H%M%S)"
run cp "$main_file" "$backup_file"

if [[ "$DRY_RUN" -eq 1 ]]; then
    printf "${C_YELLOW}[DRY-RUN]${C_RESET} Ajout du bloc ci-dessus à la fin de %s\n" "$main_file"
else
    # S'assure qu'il y a une ligne vide de séparation avant le nouveau bloc
    printf '\n%s\n' "$new_block" >> "$main_file"
fi

log_ok "$BACKPORTS_SUITE ajouté dans $main_file (sauvegarde : $backup_file)."

# --- Mise à jour des index APT ----------------------------------------------
log_info "Mise à jour des index APT..."
run apt-get update

log_ok "Terminé. Les backports trixie sont activés."
echo
echo -e "${C_BLUE}Pour installer un paquet depuis backports (sans changer les autres) :${C_RESET}"
echo "  sudo apt-get install -t trixie-backports <nom-du-paquet>"
