# Gestion de l'Environnement de Travail (SRE Workstation)

Ce guide explique comment gérer, déployer et synchroniser votre environnement de travail (Shell, Alias, Outils) sur plusieurs machines (WSL, Serveurs Linux, VM) de manière centralisée via un NAS.

## 1. Architecture de la Configuration

L'objectif est d'avoir une expérience unifiée (même prompt, mêmes alias) quel que soit le terminal utilisé.

*   **Source de Vérité** : Ce dépôt Git (`sre-lab-infrastructure`).
*   **Point de Distribution** : Votre NAS (dossier partagé `/work`).
*   **Clients** : Vos instances WSL, vos serveurs Linux, vos VMs.
*   **Automatisation** : Un script unique `bootstrap_client.sh` gère la configuration de chaque client.

## 2. Workflow de Mise à Jour

Toute modification de configuration (nouvel alias, changement de thème Starship) doit suivre ce cycle :

1.  **Modifier** le fichier dans ce dépôt (ex: `shell/aliases.sh`).
2.  **Tester** localement.
3.  **Commiter & Pousser** sur Git.
4.  **Déployer** sur le NAS depuis votre poste principal :
    ```bash
    deploy_lab
    ```

## 3. Installation sur une Nouvelle Machine

Grâce au script de bootstrap universel, l'installation est standardisée.

### Méthode Recommandée (Git)
Si la machine a accès à Internet et Git :

1.  **Cloner le dépôt** :
    ```bash
    git clone https://github.com/NicoBaiGit/sre-lab-infrastructure.git ~/github/sre-lab-infrastructure
    ```
2.  **Lancer le bootstrap** :
    ```bash
    ~/github/sre-lab-infrastructure/scripts/common/bootstrap_client.sh
    ```

### Méthode Alternative (Sans Git / Offline)
Si la machine a accès au NAS mais pas à Git, ou pour un déploiement rapide :

1.  **Monter le NAS** (si ce n'est pas déjà fait) ou copier le script via SCP.
2.  **Lancer le script** directement depuis le NAS :
    ```bash
    /mnt/nas/bootstrap_client.sh
    ```

> **Ce que fait le script (Automatisé)** :
> *   Configure `sudo` sans mot de passe (pour le lab).
> *   Monte le NAS automatiquement (`cifs` ou `drvfs` selon l'OS).
> *   Installe `keychain` pour gérer vos clés SSH.
> *   Configure `.bashrc` pour charger les alias et Starship depuis le NAS.

## 4. Mises à jour des Clients

Pour mettre à jour la configuration sur n'importe quel client (récupérer les nouveaux alias, etc.) :

```bash
reload
```

> **Note :** Cet alias exécute `git pull` (si applicable) et relance le script de bootstrap pour s'assurer que tout est conforme.

## 5. Gestion SSH (Semi-Automatisée)

La gestion des agents SSH est **automatisée** via `keychain` (installé par le script). Vous ne taperez votre mot de passe de clé qu'une seule fois par redémarrage.

### Action Manuelle Requise
Le script ne peut pas deviner sur quels serveurs vous voulez vous connecter. Vous devez donc propager votre clé publique **une seule fois** vers chaque nouveau serveur cible :

```bash
ssh-copy-id user@mon-nouveau-serveur
```

Une fois cela fait, la connexion sera automatique grâce à l'agent.

## 6. Récapitulatif des Commandes

| Action | Commande | Contexte |
| :--- | :--- | :--- |
| **Mettre à jour le NAS** | `deploy_lab` | Poste Principal (après modif Git) |
| **Mettre à jour un client** | `reload` | N'importe quel client |
| **Démarrer le Lab** | `start_lab` | Allume le serveur (WOL) |
| **Arrêter le Lab** | `bye` | Éteint le serveur proprement |

## 7. Bonnes Pratiques

*   **Ne modifiez jamais** les fichiers directement sur le NAS. Ils seront écrasés au prochain `deploy_lab`.
*   **Alias Locaux** : Si vous avez besoin d'alias spécifiques à une machine, mettez-les dans `~/.bash_aliases`. Ils seront chargés avant la configuration commune.
