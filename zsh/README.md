## Installation ZSH (zinit + plugins)

### `installation_zsh.sh`
Script d’installation et de configuration **complète** de ZSH pour **Linux Mint / Ubuntu / Debian**.

### Ce que fait le script
- **Vérifie la distribution** (Ubuntu, Debian, Linux Mint uniquement).
- **Met à jour le système** (`apt update` / `apt upgrade`).
- **Installe les dépendances APT** (dont `zsh`, `git`, `curl`, `wget`, `build-essential`, `procps`, `file`, `fontconfig`, `unzip`…).
- **Installe Homebrew (Linuxbrew)** si absent, puis installe via Homebrew:
  - `bat`, `fzf`, `zoxide`, `eza`
- **Installe JetBrainsMono Nerd Font** (Nerd Fonts GitHub) dans:
  - `~/.local/share/fonts/JetBrainsMonoNerdFont`
- **Installe zinit** dans:
  - `${XDG_DATA_HOME:-~/.local/share}/zinit/zinit.git`
- **Génère un `~/.zshrc` complet** (avec sauvegarde automatique de l’ancien fichier).
- **Définit ZSH comme shell par défaut** via `chsh`.
- **Pré-charge les plugins zinit** (premier démarrage plus rapide).

### Plugins installés (zinit)
- `zsh-users/zsh-completions`
- `zsh-users/zsh-autosuggestions`
- `zsh-users/zsh-syntax-highlighting`
- `fdellwing/zsh-bat`
- `unixorn/fzf-zsh-plugin`
- `z-shell/zsh-zoxide`

### Installation
Prévoir un accès `sudo` (le script installe des paquets et peut modifier le shell par défaut).

```bash
chmod +x installation_zsh.sh
./installation_zsh.sh