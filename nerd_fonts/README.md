# Installation des Nerd Fonts

Ce script facilite l'installation des *Nerd Fonts* sur macOS et Linux.

## 🔧 Ce que fait le script

- Détecte le système (macOS ou Linux).
- Sur macOS :
  - Installe (ou vérifie) Homebrew.
  - Active le **tap** `homebrew/cask-fonts`.
  - Installe plusieurs polices Nerd Fonts via `brew install --cask`.
- Sur Linux :
  - Si Homebrew est déjà installé, il l'utilise pour installer les polices.
  - Sinon, propose deux options :
    1) Installer via Homebrew (recommandé).
    2) Installer manuellement (téléchargement + extraction + installation locale).

## 🚀 Utilisation

1. Ouvrez un terminal.
2. Allez dans le dossier du script :

```sh
cd ~/Desktop/Github/scripts/Nerd_fonts
```

3. Rendez le script exécutable (si ce n'est pas déjà le cas) :

```sh
chmod +x install_nerd_fonts.sh
```

4. Lancez le script :

```sh
./install_nerd_fonts.sh
```

## 📝 Notes

- Sur macOS, Homebrew est installé automatiquement si absent.
- Sur Linux, l'installation manuelle place les polices dans :
  `~/.local/share/fonts/NerdFonts` et met à jour le cache de polices.
- Après installation, redémarrez vos applications (ou votre session) pour que les nouvelles polices soient prises en compte.

## 📦 Polices installées

- JetBrains Mono Nerd Font
- Caskaydia Mono Nerd Font
- Fira Code Nerd Font
- Meslo LG Nerd Font

---

Si tu veux des variantes supplémentaires, tu peux ajuster le tableau `fonts` dans le script.