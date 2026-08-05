# Rapport d'Analyse des Scripts Debian

Ce document présente l'analyse détaillée des scripts de personnalisation Debian (`00` à `09`) présents dans le dossier de travail. L'objectif est de valider leur fonctionnement en mode autonome ou orchestré via `00 - super_script.sh`, d'identifier les anomalies ou bugs potentiels et de proposer des pistes d'amélioration.

---

## 1. Synthèse Générale

Bien que tous les scripts passent avec succès la validation syntaxique (`bash -n`), **l'exécution globale du flux principal via `00 - super_script.sh` n'est pas entièrement garantie par défaut** et présente plusieurs risques majeurs de blocage ou d'altération système.

### Points Bloquants Majeurs détectés :

1. **Échec automatique sur `05`** : Le script `05 - install_alias.sh` plante immédiatement si le répertoire `debian_dotfiles` ou son fichier d'alias n'est pas préalablement créé dans le répertoire personnel de l'utilisateur, ce qui interrompt l'orchestrateur.
2. **Échec sur `08` (Systèmes non DEB822)** : Si la configuration APT du système utilise le fichier traditionnel `/etc/apt/sources.list` plutôt que le format moderne DEB822 (`*.sources` dans `/etc/apt/sources.list.d/`), le script `08 - install_backports.sh` plante et interrompt le flux.
3. **Risque de verrouillage réseau dans `07`** : Le script Samba force l'activation de `ufw` si celui-ci est inactif. Sur une machine distante (serveur dédié, VPS), cela peut couper définitivement la connexion SSH de l'administrateur.

---

## 2. Analyse Script par Script

### [00 - super_script.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/00%20-%20super_script.sh)

- **Rôle** : Orchestrateur principal.
- **Usage Autonome** : Oui. Doit obligatoirement être lancé avec `sudo` depuis un utilisateur standard (pour hériter de `$SUDO_USER`).
- **Usage depuis un autre script** : Non applicable (c'est le point d'entrée).
- **Bugs & Risques** :
  - Si l'un des scripts appelés échoue, l'orchestrateur s'arrête immédiatement. C'est sécurisant mais contraignant pour les scripts non critiques (comme les polices ou les alias).

---

### [01 - systemd_services.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/01%20-%20systemd_services.sh)

- **Rôle** : Activation de services de base (`fstrim`, `bluetooth`, `firewalld`).
- **Usage Autonome** : Oui, requiert `sudo` (`check_root`).
- **Usage depuis `00`** : Oui (exécuté en root).
- **Bugs & Risques** :
  - **Lenteur d'exécution** : Si plusieurs paquets sont absents, le script exécute `apt-get update -qq` pour chacun d'eux de manière séquentielle, ralentissant grandement l'exécution.
  - **Option `--help` absente** : L'analyseur d'arguments est rudimentaire (il ne gère que `$1 == "--dry-run"`).
  - **Conflit de pare-feu** : Active `firewalld` même si `ufw` est détecté comme actif, ce qui peut créer des conflits de règles.

---

### [02 - zram_settings.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/02%20-%20zram_settings.sh)

- **Rôle** : Configuration de zram via `systemd-zram-generator`.
- **Usage Autonome** : Oui, requiert `sudo`.
- **Usage depuis `00`** : Oui (exécuté en root).
- **Bugs & Risques** :
  - Même limitation de l'analyseur d'arguments (pas de `--help`).
  - Utilise l'algorithme `zstd` par défaut sans vérifier au préalable si le noyau actuel le supporte (généralement le cas sous Debian 13).

---

### [03 - flatpak_install.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/03%20-%20flatpak_install.sh)

- **Rôle** : Installation de Flatpak, Flathub et d'applications en mode utilisateur.
- **Usage Autonome** : Oui, requiert `sudo` mais aussi la variable `$SUDO_USER` (doit être lancé via `sudo ./script.sh`).
- **Usage depuis `00`** : Oui.
- **Bugs & Risques** :
  - **Blocage interactif** : Si lancé depuis `00` dans un terminal interactif, la fonction `confirm_installation` demandera une confirmation manuelle (`y/N`), interrompant l'automatisation.
  - **Auto-confirmation risquée** : En mode non interactif, le script procède à toutes les installations sans validation.

---

### [04 - bash_tools.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/04%20-%20bash_tools.sh)

- **Rôle** : Installation d'outils CLI modernes (`bat`, `eza`, `ripgrep`, etc.) et mise à jour de `.bashrc`.
- **Usage Autonome** : Oui, requiert `sudo` et la variable `$SUDO_USER`.
- **Usage depuis `00`** : Oui (exécuté en root).
- **Bugs & Risques** :
  - **Alias destructifs** : Redéfinir la commande système `find` par `fd` via `alias find='fd'` est très risqué car leurs syntaxes ne sont pas compatibles. Cela peut casser le fonctionnement d'autres scripts ou dérouter l'utilisateur.
  - **Absence de mise à jour** : Si Starship est installé après la première exécution du script, relancer le script ne mettra pas à jour la configuration car il détecte la présence globale du bloc et ignore la modification.

---

### [05 - install_alias.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/05%20-%20install_alias.sh)

- **Rôle** : Chargement du fichier `.bash_aliases` depuis un dossier dotfiles externe.
- **Usage Autonome** : Oui, en tant qu'utilisateur standard (sans `sudo`).
- **Usage depuis `00`** : Oui, exécuté via `sudo -u "$SUDO_USER"`.
- **Bugs & Risques** :
  - **⚠️ Bug Critique de blocage** : Le script échoue et renvoie un code d'erreur `1` si le fichier `~/debian_dotfiles/bash/.bash_aliases` n'existe pas. Cela provoque le plantage et l'arrêt immédiat de l'orchestrateur `00`.

---

### [06 - install_nerd_fonts.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/06%20-%20install_nerd_fonts.sh)

- **Rôle** : Téléchargement et installation des Nerd Fonts côté utilisateur.
- **Usage Autonome** : Oui, à lancer sans `sudo`. (Si lancé en root, installe les polices pour root).
- **Usage depuis `00`** : Oui, exécuté via `sudo -u "$SUDO_USER"`.
- **Bugs & Risques** :
  - **Pas d'idempotence** : Télécharge, extrait et copie les polices à chaque exécution du script, même si elles sont déjà présentes. Cela consomme beaucoup de bande passante inutilement.
  - La documentation/aide interne fait mention de `sudo apt` au lieu de `sudo apt-get` utilisé ailleurs.

---

### [07 - install_samba.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/07%20-%20install_samba.sh)

- **Rôle** : Installation et configuration minimale de Samba.
- **Usage Autonome** : Oui, requiert `sudo`.
- **Usage depuis `00`** : Oui (exécuté en root).
- **Bugs & Risques** :
  - **⚠️ Risque Réseau Critique** : Si `ufw` est inactif sur la machine, le script force son activation (`ufw --force enable`). Cela peut instantanément verrouiller et bloquer un accès SSH distant si les règles SSH ne sont pas configurées dans UFW au préalable.
  - Écrit silencieusement par-dessus le fichier `smb.conf` en mode non interactif, même sans l'option `--force`.

---

### [08 - install_backports.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/08%20-%20install_backports.sh)

- **Rôle** : Activation du dépôt `trixie-backports` au format DEB822.
- **Usage Autonome** : Oui, requiert `sudo`.
- **Usage depuis `00`** : Oui (exécuté en root).
- **Bugs & Risques** :
  - **⚠️ Bug de compatibilité** : Si le système n'utilise pas le format DEB822 (`*.sources` dans `/etc/apt/sources.list.d/`), le script échoue avec un code d'erreur `1`, ce qui bloque l'orchestrateur `00`.

---

### [09 - install_apt.sh](file:///Users/gchapdelaine/Desktop/Codeberg/debian-scripts/09%20-%20install_apt.sh)

- **Rôle** : Installation sélective de paquets système et backports.
- **Usage Autonome** : Oui, requiert `sudo`.
- **Usage depuis `00`** : Oui (exécuté en root).
- **Bugs & Risques** :
  - Par défaut, les listes de paquets sont vides, le script ne fait donc rien d'autre qu'un message d'information.
  - Sécurité correcte : Il refuse de lancer l'installation de paquets backports si le script `08` n'a pas été exécuté préalablement.

---

## 3. Recommandations et améliorations prioritaires

1. **Rendre le script `05` résilient** : Remplacer l'erreur fatale par un simple avertissement si le fichier d'alias dotfiles est introuvable, ou créer un fichier vide.
2. **Fiabiliser le script `08`** : Détecter et gérer les systèmes qui utilisent le format traditionnel `/etc/apt/sources.list` plutôt que de planter en l'absence de fichiers `.sources`.
3. **Sécuriser l'activation du pare-feu dans `07`** : Supprimer l'activation automatique forcée de UFW ou ajouter une vérification pour éviter de bloquer l'accès SSH distant.
4. **Optimiser les installations APT dans `01`** : Regrouper les requêtes `apt-get install` et limiter les `apt-get update` redondants.
5. **Rendre les alias de `04` moins intrusifs** : Commenter ou isoler l'alias `find='fd'` et `grep='rg'` pour éviter de casser des scripts existants.
6. **Ajouter l'idempotence au script `06`** : Vérifier la présence des fichiers de polices dans le dossier local avant de déclencher le téléchargement depuis GitHub.
