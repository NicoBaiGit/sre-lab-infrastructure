# Configuration WSL pour SRE

Cette page documente les bonnes pratiques et la configuration recommandée pour un environnement de travail WSL (Windows Subsystem for Linux) optimisé pour un SRE.

## 1. Prérequis et Optimisation

Avant de lancer la configuration logicielle, il est recommandé d'optimiser l'instance WSL.

### Optimisation RAM
Par défaut, WSL peut consommer une grande partie de la RAM disponible sur l'hôte Windows. Il est recommandé de limiter cette consommation (ex: 8 Go).

Fichier : `C:\Users\VotreUtilisateur\.wslconfig`
```ini
[wsl2]
memory=8GB
```
> Redémarrez WSL : `wsl --shutdown`

### Gestion des privilèges (Sudoers)
Pour éviter de saisir le mot de passe à chaque commande `sudo` :

```bash
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
```

## 2. Mise à jour et Dépendances

Mettez à jour le système et installez les paquets nécessaires (utilisés par le script d'automatisation).

```bash
sudo apt-get update && sudo apt-get install -y wget git
```

## 3. Configuration du Shell (.bashrc)

Cette section couvre les alias, le prompt Kubernetes (`kube-ps1`) et l'agent SSH.

### Installation de kube-ps1
Outil pour afficher le contexte Kubernetes dans le prompt.

```bash
wget https://github.com/jonmosco/kube-ps1/archive/refs/tags/v0.9.0.tar.gz
tar xzvf v0.9.0.tar.gz
sudo cp kube-ps1-0.9.0/kube-ps1.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/kube-ps1.sh
rm -rf kube-ps1-0.9.0 v0.9.0.tar.gz
```

### Modification du .bashrc
Ajoutez le contenu suivant à la fin de votre fichier `~/.bashrc` pour configurer les alias, le prompt et l'agent SSH.

```bash
# --- Configuration SRE ---

# 1. Alias
alias nano="vim"
alias k='kubectl'
alias kcc='kubectl config current-context'
alias kg='kubectl get'
alias kga='kubectl get all --all-namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias ksgp='kubectl get pods -n kube-system'
alias kuc='kubectl config use-context'
alias kgc='kubectl config get-contexts'
alias kd='kubectl describe'
alias kaf='kubectl apply -f'
alias krm='kubectl delete'
alias kl='kubectl logs'
alias kpf='kubectl port-forward'
alias kex='kubectl exec -it'

# 2. Prompt Kubernetes (kube-ps1)
source /usr/local/bin/kube-ps1.sh
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] $(kube_ps1)\$ '

# 3. Agent SSH automatique
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval `ssh-agent -s` > /dev/null
fi
ssh-add ~/.ssh/id_rsa 2>/dev/null
```
> **Note :** Remplacez `id_rsa` par le nom de votre clé privée si elle est différente.

Rechargez la configuration : `source ~/.bashrc`

## 4. Configuration SSH et Git

### Copie des clés depuis Windows
Récupérez vos clés SSH existantes depuis votre profil Windows.

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Remplacez 'VotreUserWindows' et 'id_rsa' par vos informations
cp /mnt/c/Users/VotreUserWindows/.ssh/id_rsa* ~/.ssh/
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Fichier Config SSH
Créez `~/.ssh/config` pour l'authentification automatique (ex: GitHub).

```ssh
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
    AddKeysToAgent yes
```
Permissions : `chmod 600 ~/.ssh/config`

### Configuration Git
```bash
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@exemple.com"
```

## 5. Sauvegarde de la session WSL

Commandes PowerShell pour sauvegarder/restaurer votre environnement.

**Sauvegarde :**
```powershell
wsl --terminate Ubuntu
wsl --export Ubuntu C:\Sauvegardes\wsl_backup_ubuntu.tar
```

**Restauration :**
```powershell
wsl --import UbuntuRestored C:\WSL\UbuntuRestored C:\Sauvegardes\wsl_backup_ubuntu.tar
```

## 6. Script d'automatisation

Un script interactif est disponible pour réaliser les étapes 2, 3 et 4 automatiquement.

1.  Créez le fichier `setup_wsl.sh`.
2.  Copiez le contenu du script `scripts/setup_wsl_env.sh`.
3.  Exécutez :
    ```bash
    chmod +x setup_wsl.sh
    ./setup_wsl.sh
    ```
