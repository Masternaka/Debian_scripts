#!/bin/bash

# ============================================================
# Installation du support pour les AppImages sur Debian
# ============================================================

set -e

# ---------- 1. Dépendances communes ----------
echo "==> Vérification/installation des dépendances AppImage..."
sudo apt update
sudo apt install -y libfuse2 curl wget libnss3 libasound2 libxss1 libxtst6 libgtk-3-0 libgbm1

# ---------- 2. Définition des applications ----------
# Chaque entrée : "nom|url_ou_fonction|icône_url(facultatif)|dépendances_supplémentaires"
# - "nom" : utilisé pour le fichier AppImage, le dossier d'installation et le .desktop
# - "url_ou_fonction" : si commence par "http", c'est l'URL directe de l'AppImage
#                       sinon, c'est le nom d'une fonction personnalisée qui renvoie l'URL (ex: get_helixnotes_url)
# - "icône_url" : URL d'une icône PNG à utiliser (si vide, on essaiera d'extraire de l'AppImage)
# - "dépendances_supplémentaires" : paquets Debian supplémentaires (séparés par des espaces)

APPS=(
    # Helix Notes (extraction depuis la page officielle)
    "helixnotes|get_helixnotes_url|https://helixnotes.com/favicon.png|"
    # Exemple d'une autre application avec URL directe (remplacez par un vrai lien)
    # "anotherapp|https://example.com/app-latest-x86_64.AppImage|https://example.com/icon.png|libsomepkg"
)

# Fonction pour obtenir l'URL de Helix Notes (extraction dynamique)
get_helixnotes_url() {
    local page url
    page=$(curl -sL "https://helixnotes.com")
    url=$(echo "$page" | grep -Po 'href=["'\''']?\K[^"'\'' ]*\.AppImage[^"'\'' ]*' | head -1)
    if [ -z "$url" ]; then
        echo "Erreur: impossible de trouver le lien AppImage sur helixnotes.com" >&2
        return 1
    fi
    if [[ "$url" != http* ]]; then
        url="https://helixnotes.com/$url"
    fi
    echo "$url"
}

# ---------- 3. Fonction générique d'installation ----------
install_appimage() {
    local name="$1"
    local url_or_func="$2"
    local icon_url="$3"
    local extra_deps="$4"

    echo "============================================"
    echo "=> Installation de $name"
    echo "============================================"

    # Dépendances spécifiques
    if [ -n "$extra_deps" ]; then
        sudo apt install -y $extra_deps
    fi

    # Récupération de l'URL
    local download_url
    if [[ "$url_or_func" =~ ^https?:// ]]; then
        download_url="$url_or_func"
    else
        # Appeler la fonction personnalisée
        download_url=$($url_or_func)
        if [ -z "$download_url" ]; then
            echo "Erreur : impossible d'obtenir l'URL pour $name" >&2
            return 1
        fi
    fi

    # Téléchargement
    local appimage_file="${name}.AppImage"
    echo "Téléchargement de $appimage_file depuis $download_url ..."
    wget -O "$appimage_file" "$download_url"

    chmod +x "$appimage_file"

    # Intégration système (toujours activée dans cette version modulaire)
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    mv "$appimage_file" "$install_dir/$appimage_file"

    # Icône
    local icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
    mkdir -p "$icon_dir"
    local icon_file="$icon_dir/${name}.png"

    if [ -n "$icon_url" ]; then
        echo "Téléchargement de l'icône..."
        wget -q -O "$icon_file" "$icon_url"
    else
        # Essayer d'extraire l'icône de l'AppImage (bsdtar requis)
        if command -v bsdtar &>/dev/null; then
            local inner_icon
            inner_icon=$(bsdtar -tf "$install_dir/$appimage_file" 2>/dev/null | grep -iE '\.(png|svg)$' | grep -iE 'icon' | head -1)
            if [ -n "$inner_icon" ]; then
                bsdtar -xf "$install_dir/$appimage_file" -C "$icon_dir" --strip-components=1 "$inner_icon" 2>/dev/null
                find "$icon_dir" -name "*.png" -o -name "*.svg" | head -1 | xargs -I{} mv {} "$icon_file" 2>/dev/null
            fi
        fi
        if [ ! -f "$icon_file" ]; then
            echo "Aucune icône trouvée, utilisation d'une icône générique."
            wget -q -O "$icon_file" "https://upload.wikimedia.org/wikipedia/commons/3/3f/Transparent_1x1.png"
        fi
    fi

    # Fichier .desktop
    local desktop_file="$HOME/.local/share/applications/${name}.desktop"
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=$name
Comment=$name application
Exec=$install_dir/$appimage_file %U
Icon=$icon_file
Type=Application
Categories=Utility;
Terminal=false
EOF
    echo "=> $name installé avec succès."
}

# ---------- 4. Boucle d'installation ----------
echo "==> Début de l'installation de toutes les applications..."
for app in "${APPS[@]}"; do
    IFS='|' read -r name url_or_func icon_url extra_deps <<< "$app"
    install_appimage "$name" "$url_or_func" "$icon_url" "$extra_deps"
done

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
echo "==> Toutes les applications ont été traitées."