# debian-scripts

Scripts Bash pour configurer et personnaliser une installation Debian 13 `trixie`.

## Utilisation rapide

Vérifier ce qui serait fait, sans appliquer de modification :

```bash
sudo bash "00 - super_script.sh" --dry-run
```

Lancer le flux principal :

```bash
sudo bash "00 - super_script.sh"
```

## Flux principal

Le script `00 - super_script.sh` lance, dans l'ordre :

1. `01 - systemd_services.sh`
2. `02 - zram_settings.sh`
3. `03 - flatpak_install.sh`
4. `04 - bash_tools.sh`
5. `07 - install_samba.sh`
6. `08 - install_backports.sh`
7. `09 - install_apt.sh`
8. `05 - install_alias.sh`
9. `06 - install_nerd_fonts.sh`

Les scripts root sont lancés avec sudo. Les scripts utilisateur sont lancés avec le compte utilisateur d'origine.

## Notes

- `08` active `trixie-backports`.
- `09` installe les paquets définis dans ses listes `OFFICIAL_PACKAGES` et `BACKPORT_PACKAGES`.
- Les listes de paquets de `09` sont vides par défaut.
- Consulte `CORRECTIF.md` pour l'analyse et les points d'amélioration restants.
