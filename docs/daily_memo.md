# Mémo Quotidien - SRE Lab

Ce document regroupe les commandes et informations essentielles pour l'utilisation quotidienne du Lab.

## 🚀 Démarrage / Arrêt

*   **Démarrer le Lab (WOL)** : `start_lab` (Alias vers script WOL)
*   **Arrêter le Lab** : `bye` (Arrête les services et ferme la session) ou `stop_lab`
*   **Connexion SSH** : `ssh user@192.168.x.x` (ou via alias si configuré)

## 📂 Gestion des Fichiers (NAS)

Le NAS est le point central. Il est monté sur `/mnt/nas` sur toutes les machines.
Le montage est géré automatiquement par `/etc/fstab` (configuré par `bootstrap_client.sh`).

*   **Credentials** : Stockés dans `~/.smbcredentials` (chmod 600).
*   **Alias partagés** : `/mnt/nas/aliases.sh`
*   **Config Starship** : `/mnt/nas/starship.toml`
*   **Scripts communs** : `/mnt/nas/scripts/`

Pour mettre à jour la configuration commune :
1.  Modifiez les fichiers dans votre repo Git local (`~/github/sre-lab-infrastructure`).
2.  Poussez vers le NAS : `deploy_env`

## 🛠️ Commandes Utiles (Alias)

| Alias | Commande réelle | Description |
| :--- | :--- | :--- |
| `ll` | `ls -alF` | Liste détaillée |
| `gs` | `git status` | Statut Git |
| `k` | `kubectl` | Raccourci Kubernetes |
| `kgp` | `kubectl get pods` | Lister les pods |
| `deploy_env` | `.../deploy_to_nas.sh` | Déploie la config locale vers le NAS |
| `update` | `apt update && upgrade` | Mise à jour système |

## ☸️ Kubernetes (k3s)

*   **Context** : `kuc <context>` pour changer de cluster.
*   **Logs** : `kl <pod>`
*   **Shell dans pod** : `kex <pod> -- /bin/bash`

## 🆘 En cas de problème

1.  **Le prompt ne s'affiche pas bien ?**
    *   Vérifiez que `/mnt/nas` est bien monté.
    *   Lancez `source ~/.bashrc`.

2.  **Les alias ne fonctionnent pas ?**
    *   Vérifiez si le fichier `/mnt/nas/aliases.sh` existe.
    *   Relancez le déploiement : `deploy_env`.

3.  **Problème de droits (sudo) ?**
    *   Relancez le script de bootstrap : `sudo ./bootstrap_client.sh`.
