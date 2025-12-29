# Gestion de l'Environnement de Travail (SRE Workstation)

Ce guide explique comment gérer, déployer et synchroniser votre environnement de travail (Shell, Alias, Outils) sur plusieurs machines (WSL, Serveurs Linux, VM) de manière centralisée via un NAS.

## 1. Architecture de la Configuration

L'objectif est d'avoir une expérience unifiée (même prompt, mêmes alias) quel que soit le terminal utilisé, tout en respectant les spécificités de chaque machine (clés SSH différentes, configs Git pro/perso).

*   **Source de Vérité** : Ce dépôt Git (`sre-lab-infrastructure`).
*   **Point de Distribution** : Votre NAS (dossier partagé `/work`).
*   **Clients** : Vos instances WSL, vos serveurs Linux, vos VMs.

## 2. Workflow de Mise à Jour

Toute modification de configuration (nouvel alias, changement de thème Starship) doit suivre ce cycle :

1.  **Modifier** le fichier dans ce dépôt (ex: `shell/aliases.sh`).
2.  **Tester** localement (`source shell/aliases.sh`).
3.  **Commiter & Pousser** sur Git.
4.  **Déployer** sur le NAS depuis votre poste principal.

### Commande de Déploiement (Poste Principal)
Depuis votre WSL principal (celui qui a le repo Git) :

```bash
deploy_env
```
> Cette commande copie les fichiers de config et les scripts d'installation vers le NAS.

## 3. Scénarios d'Installation

Choisissez le scénario correspondant à votre besoin sur la nouvelle machine.

### Cas A : Nouvelle Machine (Besoin juste du Shell/Alias)
*Cible : Serveur Linux, VM temporaire, WSL secondaire.*

Vous voulez récupérer votre confort (Starship, Alias `k`, `ll`...) sans écraser la configuration système (SSH, Git User).

1.  **Copier le script de bootstrap** (via `scp` ou clé USB) :
    ```bash
    # Exemple depuis votre poste principal vers un serveur
    scp ~/github/sre-lab-infrastructure/scripts/bootstrap_client.sh user@machine:~/
    ```
2.  **Lancer le script sur la cible** :
    ```bash
    bash bootstrap_client.sh
    ```
    *   Il monte le NAS (et configure fstab).
    *   Il installe Starship et injecte les alias.
    *   Il configure `sudo` sans mot de passe (optionnel).

### Cas B : Nouveau Poste de Travail Principal (Full Setup)
*Cible : Nouvelle installation WSL vierge où vous allez développer.*

1.  **Cloner le repo** :
    ```bash
    git clone https://github.com/NicoBaiGit/sre-lab-infrastructure.git ~/github/sre-lab-infrastructure
    ```
2.  **Lancer le bootstrap** :
    ```bash
    ~/github/sre-lab-infrastructure/scripts/bootstrap_client.sh
    ```

## 4. Récapitulatif des Commandes

| Action | Commande | Contexte |
| :--- | :--- | :--- |
| **Mettre à jour le NAS** | `deploy_env` | Poste Principal (avec Git) |
| **Recharger la config** | `source ~/.bashrc` | N'importe quelle machine |
| **Installer sur un serveur** | `bash bootstrap_client.sh` | Nouvelle machine (via SCP) |
| **Démarrer le Lab** | `start_lab` | Allume le serveur (Wake-on-LAN) |
| **Arrêter le Lab** | `bye` (ou `~/SCRIPTS/stop_lab`) | Éteint le serveur proprement |

## 5. Dépannage SSH (Mot de passe demandé)

Si les scripts comme `stop_lab` ou la connexion SSH vous demandent un mot de passe alors que tout devrait être automatique :

1.  **Vérifier l'agent SSH** :
    ```bash
    ssh-add -l
    ```
    *Si vide ("The agent has no identities"), ajoutez votre clé :* `ssh-add ~/.ssh/id_rsa`

2.  **Vérifier la clé sur le serveur** :
    Assurez-vous d'avoir copié votre clé publique sur le serveur cible :
    ```bash
    ssh-copy-id user@serveur
    ```

## 6. Bonnes Pratiques

*   **Ne modifiez jamais** les fichiers directement sur le NAS. Ils seront écrasés au prochain `deploy_env`. Modifiez toujours dans le dépôt Git.
*   **Alias Locaux** : Si vous avez besoin d'alias spécifiques à une machine qui ne doivent pas être partagés, mettez-les dans `~/.bash_aliases` ou à la fin de votre `.bashrc` (après le bloc SRE Lab). Ils seront prioritaires.
*   **Sudo** : Le script de bootstrap configure `sudo` sans mot de passe pour faciliter l'administration. Si c'est un serveur de prod critique, vérifiez si c'est conforme à votre politique de sécurité.
