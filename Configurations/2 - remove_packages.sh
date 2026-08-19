#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------------------------
# Constantes et configuration
# ---------------------------------------------------------------------------

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_DIR="/var/log/system-scripts"
readonly LOG_FILE="${LOG_DIR}/$(date +%Y%m%d-%H%M%S)_-_remove_desktop_bloat.log"

# Couleurs
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Options
DRY_RUN=0
ASSUME_YES=0
DO_AUTOREMOVE=1
FORCED_DESKTOP=""

# Environnement de bureau détecté (rempli par detect_desktop_environment)
DETECTED_DESKTOP=""

# ---------------------------------------------------------------------------
# Listes de paquets non essentiels par environnement de bureau
# ---------------------------------------------------------------------------

# --- KDE Plasma ---
readonly KDE_REMOVE_PACKAGES=(
    # Jeux KDE
    kmahjongg
    kpat
    kmines
    ksudoku
    kbreakout
    kblocks
    kfourinline
    ktuberling
    knavalbattle
    kgoldrunner
    bovo
    granatier
    palapeli
    picmi

    # Éducation KDE
    kgeography
    khangman
    klettres
    kanagram
    kwordquiz
    ktouch
    marble

    # Applications multimédia redondantes
    kamoso
    minuet
    juk

    # Utilitaires peu utilisés en usage bureau standard
    khelpcenter
    kaddressbook
    kjournald
    ktnef
    kruler
    kcharselect
    kmag
    kmousetool
    kgpg

    # Outils réseau / démo rarement utilisés
    kget
    kdeconnect
)

# --- GNOME ---
readonly GNOME_REMOVE_PACKAGES=(
    # Jeux GNOME
    gnome-mahjongg
    gnome-mines
    gnome-sudoku
    gnome-chess
    gnome-klotski
    gnome-nibbles
    gnome-robots
    gnome-taquin
    gnome-tetravex
    gnome-2048
    quadrapassel
    aisleriot
    five-or-more
    four-in-a-row
    hitori
    iagno
    lightsoff
    swell-foop
    tali

    # Applications redondantes / peu utilisées
    gnome-maps
    gnome-music
    gnome-weather
    gnome-contacts
    gnome-clocks
    gnome-characters
    gnome-logs
    gnome-connections
    epiphany-browser
    totem
    simple-scan
    cheese

    # Utilitaires
    gnome-user-docs
    yelp
)

# --- XFCE ---
readonly XFCE_REMOVE_PACKAGES=(
    # Jeux
    gnome-mahjongg
    gnome-mines
    gnome-sudoku
    aisleriot

    # Applications redondantes / peu utilisées en usage courant
    xfburn
    parole
    ristretto
    xfce4-dict
    xfce4-notes-plugin
    orage
    mousepad
    gnote

    # Utilitaires
    xfce4-screensaver
)

# ---------------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------------

log() {
    local level="$1"
    shift
    local message="$*"
    local color=""

    case "$level" in
        INFO)  color="$COLOR_BLUE" ;;
        OK)    color="$COLOR_GREEN" ;;
        WARN)  color="$COLOR_YELLOW" ;;
        ERROR) color="$COLOR_RED" ;;
    esac

    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [${level}]${COLOR_RESET} ${message}"

    if [[ -d "$LOG_DIR" ]] || mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

die() {
    log ERROR "$*"
    exit 1
}

# Wrapper d'exécution respectant --dry-run
run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log INFO "[DRY-RUN] $*"
    else
        "$@"
    fi
}

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Détecte l'environnement de bureau (KDE Plasma, GNOME ou XFCE) et
désinstalle (purge) les paquets non essentiels qui lui sont associés.

Options:
  --dry-run             Simule les actions sans rien modifier
  --yes, -y              Ne demande pas de confirmation
  --no-autoremove        N'exécute pas 'apt-get autoremove' en fin de script
  --desktop=<de>         Force l'environnement (kde|gnome|xfce), ignore la détection auto
  -h, --help             Affiche cette aide

Exemples:
  ${SCRIPT_NAME} --dry-run
  ${SCRIPT_NAME} --yes
  ${SCRIPT_NAME} --desktop=kde --dry-run
EOF
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        die "Ce script doit être exécuté en tant que root (utilisez sudo)."
    fi
}

# Vérifie si un paquet est installé (guard function)
is_installed() {
    local package="$1"
    dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "^install ok installed$"
}

# Filtre la liste pour ne garder que les paquets réellement installés
filter_installed_packages() {
    local -n source_array="$1"
    local -n result_array="$2"
    result_array=()

    local pkg
    for pkg in "${source_array[@]}"; do
        if is_installed "$pkg"; then
            result_array+=("$pkg")
        fi
        # Paquets non installés ignorés silencieusement (comportement voulu)
    done
}

confirm() {
    local prompt="$1"

    if [[ "$ASSUME_YES" -eq 1 ]]; then
        return 0
    fi

    local reply
    read -r -p "$(echo -e "${COLOR_YELLOW}${prompt} [o/N]${COLOR_RESET} ")" reply
    [[ "$reply" =~ ^[oOyY]$ ]]
}

# ---------------------------------------------------------------------------
# Détection de l'environnement de bureau
# ---------------------------------------------------------------------------

# Normalise une chaîne de DE brute vers kde|gnome|xfce|"" (inconnu)
normalize_desktop_name() {
    local raw="$1"
    raw="${raw,,}"  # lowercase

    case "$raw" in
        *kde*|*plasma*)
            echo "kde"
            ;;
        *gnome*)
            echo "gnome"
            ;;
        *xfce*)
            echo "xfce"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Tentative de détection via XDG_CURRENT_DESKTOP (et variables associées)
detect_via_xdg() {
    local candidates=(
        "${XDG_CURRENT_DESKTOP:-}"
        "${XDG_SESSION_DESKTOP:-}"
        "${DESKTOP_SESSION:-}"
    )

    local candidate normalized
    for candidate in "${candidates[@]}"; do
        [[ -z "$candidate" ]] && continue
        normalized="$(normalize_desktop_name "$candidate")"
        if [[ -n "$normalized" ]]; then
            echo "$normalized"
            return 0
        fi
    done

    return 1
}

# Fallback : détection via présence des paquets meta task-*-desktop
detect_via_meta_packages() {
    if is_installed "task-kde-desktop"; then
        echo "kde"
        return 0
    fi

    if is_installed "task-gnome-desktop"; then
        echo "gnome"
        return 0
    fi

    if is_installed "task-xfce-desktop"; then
        echo "xfce"
        return 0
    fi

    return 1
}

detect_desktop_environment() {
    local result=""

    if result="$(detect_via_xdg)"; then
        log INFO "Environnement de bureau détecté via XDG_CURRENT_DESKTOP : ${result}"
        DETECTED_DESKTOP="$result"
        return 0
    fi

    log WARN "Détection via variables XDG infructueuse, tentative via paquets meta..."

    if result="$(detect_via_meta_packages)"; then
        log INFO "Environnement de bureau détecté via paquet meta : ${result}"
        DETECTED_DESKTOP="$result"
        return 0
    fi

    DETECTED_DESKTOP=""
    return 1
}

# ---------------------------------------------------------------------------
# Logique métier
# ---------------------------------------------------------------------------

# Renvoie le nom du tableau de paquets associé à un DE donné
get_package_array_name() {
    local desktop="$1"

    case "$desktop" in
        kde)   echo "KDE_REMOVE_PACKAGES" ;;
        gnome) echo "GNOME_REMOVE_PACKAGES" ;;
        xfce)  echo "XFCE_REMOVE_PACKAGES" ;;
        *)     echo "" ;;
    esac
}

purge_desktop_packages() {
    local desktop="$1"
    local array_name
    array_name="$(get_package_array_name "$desktop")"

    if [[ -z "$array_name" ]]; then
        log WARN "Aucune liste de paquets définie pour l'environnement '${desktop}'. Arrêt propre."
        exit 0
    fi

    local -a to_remove=()
    filter_installed_packages "$array_name" to_remove

    if [[ "${#to_remove[@]}" -eq 0 ]]; then
        log OK "Aucun paquet non essentiel de '${desktop}' n'est installé. Rien à faire."
        return 0
    fi

    log INFO "Paquets ${desktop^^} suivants seront purgés (${#to_remove[@]}) :"
    printf '  - %s\n' "${to_remove[@]}"

    if ! confirm "Confirmer la purge de ces paquets ?"; then
        log WARN "Opération annulée par l'utilisateur."
        return 1
    fi

    log INFO "Purge des paquets en cours..."
    run apt-get purge -y "${to_remove[@]}"
    log OK "Paquets ${desktop^^} non essentiels purgés avec succès."
}

autoremove_packages() {
    if [[ "$DO_AUTOREMOVE" -eq 0 ]]; then
        log INFO "Étape autoremove ignorée (--no-autoremove)."
        return 0
    fi

    if ! confirm "Exécuter 'apt-get autoremove --purge' pour nettoyer les dépendances orphelines ?"; then
        log INFO "Autoremove ignoré."
        return 0
    fi

    log INFO "Nettoyage des dépendances orphelines..."
    run apt-get autoremove --purge -y
    log OK "Dépendances orphelines nettoyées."
}

# ---------------------------------------------------------------------------
# Point d'entrée
# ---------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --yes|-y)
                ASSUME_YES=1
                shift
                ;;
            --no-autoremove)
                DO_AUTOREMOVE=0
                shift
                ;;
            --desktop=*)
                FORCED_DESKTOP="${1#--desktop=}"
                FORCED_DESKTOP="${FORCED_DESKTOP,,}"
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Option inconnue : $1 (voir --help)"
                ;;
        esac
    done

    if [[ -n "$FORCED_DESKTOP" ]]; then
        case "$FORCED_DESKTOP" in
            kde|gnome|xfce) ;;
            *) die "Valeur invalide pour --desktop : '${FORCED_DESKTOP}' (attendu: kde|gnome|xfce)" ;;
        esac
    fi
}

main() {
    parse_args "$@"
    check_root

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log WARN "Mode --dry-run activé : aucune modification ne sera appliquée."
    fi

    log INFO "Démarrage de la désinstallation des paquets de bureau non essentiels."

    if [[ -n "$FORCED_DESKTOP" ]]; then
        log INFO "Environnement de bureau forcé via --desktop : ${FORCED_DESKTOP}"
        DETECTED_DESKTOP="$FORCED_DESKTOP"
    elif ! detect_desktop_environment; then
        log WARN "Impossible de détecter l'environnement de bureau (KDE, GNOME ou XFCE). Arrêt propre."
        exit 0
    fi

    purge_desktop_packages "$DETECTED_DESKTOP"
    autoremove_packages

    log OK "Script terminé."
}

main "$@"
