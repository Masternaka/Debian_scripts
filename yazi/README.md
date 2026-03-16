# Yazi (explorateur de fichiers terminal) - Installation et utilisation

Ce dossier contient les scripts et configurations pour installer et configurer **Yazi**, un explorateur de fichiers en terminal.

## Que fait le script `setup-yazi.sh` ?

Le script `setup-yazi.sh` :

- Installe les fichiers de configuration (`yazi.toml`, `keymap.toml`) dans `~/.config/yazi/`.
- Initialise un wrapper `y` pour lancer Yazi depuis votre shell tout en permettant de changer de dossier à la sortie.
- Peut installer des plugins via `ya pack` (si Yazi est déjà installé).

> Le script n'installe pas Yazi lui-même (il s'appuie sur `yazi` déjà disponible dans votre PATH). Assurez-vous d'avoir installé Yazi via votre gestionnaire de paquets ou `cargo`.

## Comment l'utiliser

1. Ouvrez un terminal.
2. Placez-vous dans le dossier `yazi` :

```bash
cd /path/to/Debian_scripts/yazi
```

3. Rendez le script exécutable et lancez-le :

```bash
chmod +x setup-yazi.sh
./setup-yazi.sh
```

4. Copiez/collez les fichiers de config dans `~/.config/yazi/` (si cela n'est pas déjà fait) :

```bash
mkdir -p ~/.config/yazi
cp yazi.toml ~/.config/yazi/
cp keymap.toml ~/.config/yazi/
```

5. Rechargez votre shell :

```bash
source ~/.bashrc   # ou ~/.zshrc, ~/.config/fish/config.fish
```

6. Lancez Yazi avec la commande :

```bash
y
```

## Personnalisation

- Éditez `~/.config/yazi/keymap.toml` pour ajuster les raccourcis (terminal, plugins, navigation, etc.).
- Ajoutez des plugins avec `ya pack -a <plugin>` (ex : `ya pack -a yazi-rs/plugins:zoxide`).

---

Pour plus de détails, consultez le fichier `Guide d'installation Yazi.md` dans ce dossier.
