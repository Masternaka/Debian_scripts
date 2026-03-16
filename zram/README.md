# Activation de ZRAM (Debian / Ubuntu / dérivés)

Ce dossier contient un script (`activation_zram.sh`) qui configure et active **ZRAM** en tant que swap compressé dans les distributions basées sur Debian/Ubuntu.

## Que fait le script ?

Le script `activation_zram.sh` :

- Vérifie qu'il est exécuté avec des droits `root` (sudo).
- Détecte la distribution Linux et vérifie la compatibilité (Debian/Ubuntu/derivés).
- Vérifie que le module noyau `zram` est disponible.
- Vérifie si le noyau supporte la compression `zstd` et bascule en `lzo-rle` si nécessaire.
- Installe `systemd-zram-generator` si nécessaire (via `apt`).
- Génère une configuration `systemd-zram-generator` (`/etc/systemd/zram-generator.conf.d/zram.conf`) :
  - taille ZRAM = 50 % de la RAM
  - algorithme de compression (`zstd` ou `lzo-rle`)
  - priorité swap élevée (100)
  - type de filesystem swap explicite
- Diminue la priorité des swaps disque/fichier existants (prio `-10`) pour favoriser ZRAM.
- Tente d'appliquer immédiatement la nouvelle priorité sur les swaps actifs (hors ZRAM).
- Recharge `systemd` et active `dev-zram0.swap`.
- Affiche un récapitulatif de la configuration et des swaps actifs.

> Le script modifie `/etc/fstab` et les paramètres du swap : vérifiez les sauvegardes et la configuration avant de l'exécuter.

## Comment l'utiliser

1. Ouvrez un terminal.
2. Placez-vous dans le dossier `zram` :

```bash
cd /path/to/Debian_scripts/zram
```

3. Lancez le script avec `sudo` :

```bash
sudo ./activation_zram.sh
```

4. Vérifiez que le swap ZRAM est actif :

```bash
swapon --show
zramctl
```

## Notes importantes

- Le script préfère `zstd` si le noyau le supporte, sinon il utilise `lzo-rle`.
- Si vous utilisez déjà un gestionnaire ZRAM (comme `zram-tools` ou `systemd-zram-generator` configuré ailleurs), il peut y avoir des conflits. Le script affiche un avertissement dans ce cas.

---

Pour plus d'informations, consultez le script `activation_zram.sh` lui-même, qui est largement commenté.
