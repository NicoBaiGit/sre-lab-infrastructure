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

## � Mise à jour de la Configuration

### 1. Mettre à jour le NAS (Depuis le poste de Dev)
Si vous avez modifié des alias ou la config Starship dans le code source :
1.  `git pull` (pour être à jour)
2.  `deploy-lab` (alias pour `deploy_to_nas.sh`)

### 2. Mettre à jour un Client (WSL, Serveur...)
Si vous voulez récupérer la dernière version des scripts ou réparer la config sur une machine :
```bash
cd ~/github/sre-lab-infrastructure
git pull
./scripts/bootstrap_client.sh
```
*(Le script est idempotent : il peut être relancé sans danger pour mettre à jour fstab, installer les nouveaux outils comme keychain, etc.)*

## 🛠️ Liste des Alias (Référence)

| Catégorie | Alias | Commande | Description |
| :--- | :--- | :--- | :--- |
| **Navigation** | `..` | `cd ..` | Remonter d'un niveau |
| | `...` | `cd ../..` | Remonter de 2 niveaux |
| | `ll` | `ls -alF` | Liste détaillée |
| | `la` | `ls -A` | Liste presque tout |
| | `l` | `ls -CF` | Liste simple |
| **Git** | `gs` | `git status` | Statut |
| | `ga` | `git add` | Ajouter |
| | `gc` | `git commit` | Commiter |
| | `gp` | `git push` | Pousser |
| | `gl` | `git log ...` | Historique graphique |
| **Kubernetes** | `k` | `kubectl` | Base |
| | `kcc` | `kubectl config current-context` | Contexte actuel |
| | `kg` | `kubectl get` | Get |
| | `kgp` | `kubectl get pods` | Pods |
| | `kgs` | `kubectl get services` | Services |
| | `kga` | `kubectl get all -A` | Tout (tous namespaces) |
| | `kd` | `kubectl describe` | Décrire |
| | `kl` | `kubectl logs` | Logs |
| | `kex` | `kubectl exec -it` | Shell dans pod |
| **Système** | `update` | `apt update && upgrade` | Mise à jour APT |
| | `nano` | `vim` | Force l'habitude VIM ;) |
| **Lab SRE** | `start_lab` | `~/SCRIPTS/start_lab` | Démarrer (WOL) |
| | `bye` | `stop_lab; exit` | Arrêter et quitter |
| | `deploy-lab` | `.../deploy_to_nas.sh` | Déployer config sur NAS |

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
