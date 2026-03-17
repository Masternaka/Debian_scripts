# Installation Samba Ubuntu

Ce dossier contient un script d'installation et de configuration de **Samba** pour Ubuntu/Debian.

## 📌 Ce que fait le script

Le script `installation_samba_ubuntu.sh` :

- Installe les paquets **samba** et **samba-common-bin**
- Sauvegarde l'ancien fichier de configuration `/etc/samba/smb.conf` (si existant)
- Génère un fichier `smb.conf` minimal avec un exemple de partage commenté
- Active et démarre les services **smbd** et **nmbd**
- Configure le pare-feu (si **ufw** ou **firewalld** est disponible) pour autoriser Samba

## ▶️ Utilisation

Ouvrez un terminal et exécutez :

```bash
sudo bash Debian_scripts/samba/installation_samba_ubuntu.sh
```

### 👇 Après l'installation

- Vérifiez la configuration :
  ```bash
testparm
```
- Ajoutez un utilisateur Samba :
  ```bash
sudo smbpasswd -a <utilisateur>
```
- Vérifiez le statut des services :
  ```bash
systemctl status smbd nmbd
```

## 📝 Personnaliser le partage

Le fichier `/etc/samba/smb.conf` contient un exemple de partage commenté. Pour ajouter un partage :

1) Décommentez et adaptez la section `[#partage]`
2) Créez le dossier de partage et ajustez les permissions
3) Redémarrez Samba :

```bash
sudo systemctl restart smbd nmbd
```

---

> Note : Ce script est conçu pour Ubuntu/Debian. Sur d'autres distributions, adaptez les commandes d'installation et de gestion de pare-feu.
