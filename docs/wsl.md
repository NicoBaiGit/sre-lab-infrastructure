# Configuration WSL pour SRE

Cette page documente les bonnes pratiques et la configuration recommandée pour un environnement de travail WSL (Windows Subsystem for Linux) optimisé pour un SRE.

## 1. Prérequis et Optimisation

Avant de lancer la configuration logicielle, il est recommandé d'optimiser l'instance WSL.

### Optimisation RAM
Par défaut, WSL peut consommer une grande partie de la RAM disponible sur l'hôte Windows.
Comme le T14 est utilisé principalement comme **poste de pilotage** (SSH, Kubectl, Git) et que les charges lourdes tournent sur le T420, nous pouvons limiter WSL pour laisser des ressources à Windows (Teams, Navigateur).

**Recommandation pour 16 Go de RAM totale :**
*   **4GB** : Suffisant pour du pilotage pur.
*   **6GB** : Confortable (permet de lancer quelques conteneurs Docker de test localement).

Fichier : `C:\Users\VotreUtilisateur\.wslconfig`
```ini
[wsl2]
memory=6GB
```
> Redémarrez WSL : `wsl --shutdown`

## 2. Installation Initiale

Pour récupérer le script d'automatisation, nous avons besoin de Git.

```bash
sudo apt-get update && sudo apt-get install -y git
```

## 3. Configuration Automatisée (Recommandé)

Nous utilisons un script de **Bootstrap universel** qui connecte votre machine (WSL, VM Linux, Serveur) au NAS centralisé et configure tout l'environnement.

Ce script détecte automatiquement l'environnement et va :

*   **Monter le NAS** (`/mnt/nas`) automatiquement (via `drvfs` sur WSL).
*   **Installer Starship** (Prompt moderne).
*   **Configurer votre `.bashrc`** pour charger les alias et la config depuis le NAS.
*   **Installer Keychain** pour gérer vos clés SSH.

### Procédure

1.  **Récupérer le code** :
    ```bash
    # Cloner (ou mettre à jour)
    if [ -d ~/github/sre-lab-infrastructure ]; then
        cd ~/github/sre-lab-infrastructure && git pull
    else
        git clone https://github.com/NicoBaiGit/sre-lab-infrastructure.git ~/github/sre-lab-infrastructure
    fi
    ```

2.  **Lancer le script** :
    ```bash
    ~/github/sre-lab-infrastructure/scripts/common/bootstrap_client.sh
    source ~/.bashrc
    ```

> **Note :** Le script est idempotent. Vous pouvez le relancer à tout moment.
> **Astuce :** Par la suite, utilisez simplement l'alias `reload` pour mettre à jour votre environnement.

## 4. Configuration Post-Installation (Manuelle)

Certaines étapes ne peuvent pas être automatisées car elles touchent à vos secrets ou à votre identité personnelle.

### 4.1 Récupération des Clés SSH
Le script installe l'agent SSH (`keychain`), mais vous devez lui fournir vos clés. Si vous avez déjà des clés sous Windows, copiez-les :

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Remplacez 'VotreUserWindows' par votre nom d'utilisateur Windows
cp /mnt/c/Users/VotreUserWindows/.ssh/id_rsa* ~/.ssh/

# Sécurisation des clés (Obligatoire)
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### 4.2 Identité Git
Configurez votre identité pour vos commits :

```bash
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@exemple.com"
```

### 4.3 Connexion SSH sans mot de passe (Vers le Serveur)
Pour ne pas avoir à saisir votre mot de passe à chaque connexion vers le T420, vous devez autoriser votre clé SSH sur le serveur.

**1. Copier la clé publique vers le serveur :**
```bash
# Remplacez par le nom de votre clé (ex: id_rsa.pub ou nicolas.bailleul.wrk.pub)
ssh-copy-id -i ~/.ssh/id_rsa.pub nicolab@192.168.1.120
```

**2. Configuration automatique (Optionnel mais recommandé) :**
Si votre clé ne s'appelle pas `id_rsa`, SSH ne la trouvera pas tout seul. Créez un fichier `config` pour lui dire quelle clé utiliser.

Fichier : `~/.ssh/config`
```ssh
Host t420 192.168.1.120
    HostName 192.168.1.120
    User nicolab
    IdentityFile ~/.ssh/votre_cle_privee
```
*(Remplacez `votre_cle_privee` par le nom de votre fichier de clé, sans .pub)*.

Désormais, `ssh t420` vous connectera instantanément.

## 5. Utilisation Quotidienne

Une fois installé, votre environnement est prêt.

*   **Démarrer le Lab** : `start_lab` (Allume le serveur via Wake-on-LAN).
*   **Arrêter le Lab** : `bye` (Éteint le serveur proprement).
*   **Mettre à jour** : `reload` (Met à jour les scripts et la config).

## 6. Sauvegarde de la session WSL (Référence)

Commandes PowerShell pour sauvegarder/restaurer votre environnement complet.

**Sauvegarde :**
```powershell
wsl --terminate Ubuntu
wsl --export Ubuntu C:\Sauvegardes\wsl_backup_ubuntu.tar
```

**Restauration :**
```powershell
wsl --import UbuntuRestored C:\WSL\UbuntuRestored C:\Sauvegardes\wsl_backup_ubuntu.tar
```

## 7. Dépannage

### Erreur au démarrage : Wsl/Service/0x8007273d

Si vous rencontrez l'erreur suivante au lancement de WSL :
> The attempted operation is not supported for the type of object referenced.
> Error code: Wsl/Service/0x8007273d

**Cause :**
Cette erreur est généralement causée par un conflit avec des logiciels tiers (Proxifier, VPN, etc.) qui modifient la pile réseau via des *Winsock Layered Service Providers (LSP)*.

**Solution :**
Il faut réinitialiser le catalogue Winsock.

1.  Ouvrir un terminal (PowerShell ou CMD) **en tant qu'administrateur**.
2.  Exécuter la commande :
    ```powershell
    netsh winsock reset
    ```
3.  **Redémarrer** l'ordinateur.

