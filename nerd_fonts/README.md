# Installation des Nerd Fonts

Ce script installe des *Nerd Fonts* sur **Linux** en téléchargeant les archives depuis les releases GitHub officielles et en les ajoutant à votre dossier de polices utilisateur.

## 🔧 Ce que fait le script

- Vérifie que le système est bien **Linux** (sinon, il s'arrête).
- Vérifie que les commandes nécessaires sont présentes : `curl`, `unzip` et `fc-cache`.
- Télécharge les archives `.zip` des polices depuis la dernière release de `ryanoasis/nerd-fonts`.
- Extrait les fichiers `.ttf` / `.otf` et les copie dans `~/.local/share/fonts/NerdFonts`.
- Met à jour le cache des polices (`fc-cache -fv`).

## 🚀 Utilisation

1. Ouvrez un terminal.
2. Allez dans le dossier du script :

```sh
cd ~/Desktop/Github/Debian_scripts/nerd_fonts
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

- Ce script est conçu pour **Linux uniquement** et renverra une erreur sur macOS (ou d'autres OS).
- Les polices sont installées dans :
  `~/.local/share/fonts/NerdFonts`.
- Après installation, redémarrez vos applications (ou votre session) pour voir les nouvelles polices.

## 📦 Polices installées

- JetBrains Mono Nerd Font
- Caskaydia Mono Nerd Font
- Fira Code Nerd Font
- Meslo LG Nerd Font

---

Si tu veux des variantes supplémentaires, tu peux ajuster le tableau `fonts` dans le script.