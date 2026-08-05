# Analyse actuelle des scripts Debian

Ce document reflète l'état actuel du dossier `debian-scripts` après relecture des scripts `00` à `09`.

Validation effectuée :

```bash
for f in ./*.sh; do bash -n "$f" && printf 'OK %s\n' "$f"; done
```

Résultat : tous les scripts passent la vérification syntaxique Bash.

Important : cette validation ne lance pas les scripts et ne modifie pas le système. Elle confirme seulement qu'il n'y a pas d'erreur de syntaxe évidente.

---

## État général

La structure globale est bonne :

- les scripts sont séparés par responsabilité;
- `00 - super_script.sh` orchestre les scripts root et utilisateur, incluant maintenant `08` et `09`;
- les scripts critiques utilisent majoritairement `set -euo pipefail`;
- les commandes APT utilisent `apt-get`, ce qui est approprié pour des scripts;
- Flatpak est maintenant installé si absent;
- Flathub est configuré côté utilisateur;
- Samba sauvegarde `smb.conf` et valide la configuration avec `testparm`;
- `01` et `02` n'utilisent plus `eval`.

Les améliorations restantes concernent surtout la sécurité d'exécution automatisée, l'idempotence, la documentation, et l'uniformisation des options.

---

## Points prioritaires à améliorer

### 1. Garder les listes APT configurables et utiles

`08 - install_backports.sh` et `09 - install_apt.sh` sont maintenant intégrés au flux principal.

Le rôle est cohérent :

- `08` active `trixie-backports`;
- `09` installe ensuite des paquets officiels ou backports.

Le point restant : les listes de `09` sont vides par défaut, donc `09` ne fait rien tant qu'elles ne sont pas remplies.

Recommandation :

- remplir `OFFICIAL_PACKAGES` et `BACKPORT_PACKAGES`;
- ou permettre de lire ces listes depuis un fichier externe.

### 2. Continuer à uniformiser les options

Tous les scripts appelés par `00` acceptent maintenant `--dry-run`.

Le point restant : les options ne sont pas encore totalement uniformes.

Recommandation :

- ajouter `--yes` quand une confirmation est attendue;
- documenter précisément `--force` pour les actions destructives;
- garder `--help` partout.

### 3. Réduire les décisions automatiques en non-interactif

Certains scripts continuent automatiquement quand ils sont appelés depuis `00`.

Exemples :

- `03 - flatpak_install.sh` confirme automatiquement l'installation des applications Flatpak en non-interactif;
- `07 - install_samba.sh` remplace automatiquement `smb.conf` en non-interactif après sauvegarde;
- `07` peut activer `ufw` automatiquement si `firewalld` n'est pas disponible.

Recommandation :

- ajouter une option globale `--yes` ou `--assume-yes`;
- faire échouer les scripts destructifs en non-interactif si `--yes` ou `--force` n'est pas fourni;
- appeler explicitement `07 - install_samba.sh --force` depuis `00` si ce comportement est voulu.

### 4. Éviter les alias trop intrusifs dans `04`

`04 - bash_tools.sh` ajoute plusieurs alias qui remplacent des commandes standards :

```bash
alias cat='batcat --paging=never --style=plain'
alias grep='rg --color=auto'
alias find='fd'
```

C'est pratique pour un usage personnel, mais cela peut surprendre dans un shell quotidien, surtout pour `find` et `grep`.

Recommandation :

- rendre ces alias optionnels;
- ou ne définir que des alias non destructifs (`bat`, `rg`, `fd`, `ll`, `la`);
- ou placer les alias intrusifs dans un bloc séparé clairement nommé.

### 5. Maintenir `README.md` et `WIKI.md`

`README.md` et `WIKI.md` ont été réécrits pour refléter le flux actuel.

Recommandation :

- les maintenir à jour à chaque changement de flux;
- documenter les listes de paquets réelles quand `09` sera rempli.

---

## Analyse par script

### `00 - super_script.sh`

Rôle : script principal d'orchestration.

Points positifs :

- journalisation dans `/var/log`;
- résumé final;
- séparation root/utilisateur;
- `04 - bash_tools.sh` est maintenant correctement lancé dans la phase root.
- `08` et `09` sont intégrés au flux principal;
- `--dry-run` est transmis aux scripts appelés.

Points à améliorer :

- ajouter une option `--yes` pour les exécutions non interactives assumées;
- éviter `sudo bash` pour les scripts root quand `00` est déjà root, même si ce n'est pas bloquant;
- améliorer l'arrêt du processus de maintien sudo avec un trap plus ciblé.

### `01 - systemd_services.sh`

Rôle : installer et activer `fstrim`, `bluetooth`, `firewalld`.

Points positifs :

- `--dry-run` présent;
- plus de `eval`;
- logique idempotente pour les services déjà actifs;
- avertissement si `ufw` est actif.

Points à améliorer :

- ne pas activer Bluetooth automatiquement si aucun adaptateur n'est détecté, ou demander confirmation;
- éviter de lancer `apt-get update` séparément pour chaque paquet si plusieurs paquets sont installés;
- préciser que le choix réseau principal du projet est `firewalld`.

### `02 - zram_settings.sh`

Rôle : configurer zram via `systemd-zram-generator`.

Points positifs :

- `--dry-run` présent;
- sauvegarde de configuration existante;
- plus de `eval`;
- configuration claire.

Points à améliorer :

- vérifier que l'algorithme `zstd` est disponible avant de l'écrire;
- documenter l'impact du choix `ram / 2`;
- en mode `--dry-run`, éviter tout comportement qui dépend d'un état système non vérifié.

### `03 - flatpak_install.sh`

Rôle : installer Flatpak, configurer Flathub, installer des applications Flatpak côté utilisateur.

Points positifs :

- installe `flatpak` si absent;
- configure Flathub pour l'utilisateur réel;
- installe les applications en mode `--user`;
- options `--help`, `--dry-run`, `--list`;
- retry sur les installations.

Points à améliorer :

- ajouter une option `--yes` pour rendre l'automatisation explicite;
- éviter la confirmation automatique en non-interactif sans option claire;
- rendre la liste d'applications configurable dans un fichier séparé;
- éviter les emojis si tu veux une sortie strictement portable;
- vérifier que la session utilisateur Flatpak est utilisable après installation du paquet.

### `04 - bash_tools.sh`

Rôle : installer des outils CLI modernes et configurer `.bashrc`.

Points positifs :

- lancé en root depuis `00`;
- utilise `apt-get`;
- ne fait plus `apt upgrade -y`;
- modifie explicitement le `.bashrc` de l'utilisateur réel;
- sauvegarde `.bashrc`.
- `--dry-run` présent.

Points à améliorer :

- rendre les alias intrusifs optionnels (`cat`, `grep`, `find`);
- prévoir une méthode de mise à jour du bloc existant, pas seulement "présent ou absent";
- vérifier l'existence de `eza`, `duf`, etc. selon la version Debian ciblée;
- éviter de figer la ligne Starship si Starship est installé après la première exécution.

### `05 - install_alias.sh`

Rôle : charger un fichier d'alias externe dans `.bashrc`.

Points positifs :

- idempotence via marqueur;
- sauvegarde `.bashrc`.
- `--dry-run` présent;
- option `--file` présente.

Points à améliorer :

- le chemin `~/debian_dotfiles/bash/.bash_aliases` est très spécifique;
- vérifier explicitement le résultat de `getent passwd "$SUDO_USER"`;
- préserver la propriété du `.bashrc` si le script est lancé avec sudo;

### `06 - install_nerd_fonts.sh`

Rôle : télécharger et installer des Nerd Fonts.

Points positifs :

- vérifie `curl`, `unzip`, `fc-cache`;
- installe dans le dossier utilisateur;
- nettoie les fichiers temporaires.
- `--dry-run` et `--list` présents;
- shebang uniformisé.

Points à améliorer :

- éviter de retélécharger les polices déjà installées;
- épingler une version Nerd Fonts au lieu d'utiliser `latest`;
- vérifier les checksums si l'objectif est une installation robuste;
- remplacer les hints `sudo apt install` par `sudo apt-get install` pour cohérence script.

### `07 - install_samba.sh`

Rôle : installer Samba, écrire une configuration minimale, configurer le pare-feu.

Points positifs :

- sauvegarde `smb.conf`;
- confirmation en interactif;
- option `--force`;
- validation avec `testparm`;
- support `firewalld` et `ufw`.
- `--dry-run` présent.

Points à améliorer :

- éviter de remplacer `smb.conf` en non-interactif sans `--force`;
- éviter d'activer `ufw` automatiquement sans confirmation, surtout sur machine distante;
- proposer une option pour seulement installer Samba sans écrire une configuration minimale;
- documenter clairement qu'aucun partage réel n'est créé par défaut.

### `08 - install_backports.sh`

Rôle : activer `trixie-backports` au format DEB822.

Points positifs :

- idempotent;
- sauvegarde le fichier `.sources`;
- `--dry-run` présent;
- réutilise miroir, composants et clé du bloc principal.

Points à améliorer :

- gérer le cas où le système utilise encore `/etc/apt/sources.list`;
- vérifier que le bloc détecté est bien un dépôt Debian officiel, pas un dépôt tiers;
- améliorer la lecture DEB822 pour les champs multi-lignes;
- documenter que ce script est spécifique à Debian 13/trixie;
- décider s'il doit être appelé par `00`.

### `09 - install_apt.sh`

Rôle : installer des paquets depuis les dépôts officiels ou backports.

Points positifs :

- ne modifie plus les dépôts;
- utilise `apt-get`;
- vérifie que `trixie-backports` est actif avant d'installer des paquets backports;
- séparation claire entre `OFFICIAL_PACKAGES` et `BACKPORT_PACKAGES`.
- `--dry-run` présent;
- évite `apt-get update` si les listes sont vides.

Points à améliorer :

- les listes de paquets sont vides, donc le script ne fait actuellement rien après `apt-get update`;
- permettre de lire les listes depuis un fichier externe;
- documenter qu'il faut lancer `08` avant d'utiliser `BACKPORT_PACKAGES` si `09` est lancé seul.

---

## Améliorations transversales

- Uniformiser les options : `--help`, `--dry-run`, `--yes`, `--force` quand pertinent.
- Uniformiser les shebangs en `#!/usr/bin/env bash`.
- Réduire les comportements automatiques destructifs en non-interactif.
- Centraliser les listes configurables : Flatpak, paquets APT, polices.
- Maintenir la documentation d'utilisation dans `README.md`.
- Maintenir la documentation détaillée dans `WIKI.md`.
- Ajouter une section "ce que le script modifie" pour chaque script.

---

## Priorité recommandée

1. Rendre les alias intrusifs de `04` optionnels.
2. Empêcher `07` de remplacer `smb.conf` en non-interactif sans `--force`.
3. Rendre les listes Flatpak/APT/polices configurables hors du code.
4. Remplir ou externaliser les listes de paquets de `09`.
