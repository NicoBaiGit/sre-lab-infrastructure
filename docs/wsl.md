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

## 3. Configuration Automatisée (Recommandé)

Nous avons créé un script qui configure automatiquement :
*   Les dépendances (Git, Wget).
*   Le prompt **Starship** (remplace kube-ps1 pour une meilleure performance et intégration Git/K8s).
*   Les alias centralisés (chargés depuis le NAS ou Git).
*   La configuration SSH (récupération des clés depuis Windows).
*   La configuration Git.

Lancez simplement :

```bash
~/github/sre-lab-infrastructure/scripts/setup_wsl_env.sh
```

> **Note :** Ce script configure votre `.bashrc` pour charger les configurations centralisées.

## 4. Configuration Multi-WSL / Linux (Via NAS)

Si vous avez une seconde instance WSL, une VM Linux ou un autre PC, et que vous souhaitez récupérer uniquement la configuration du shell (Alias + Starship) sans impacter vos clés SSH, Git ou Kubernetes existants.

### Prérequis
Avoir déployé la configuration sur le NAS depuis votre machine principale :
```bash
deploy_env
```

### Installation sur la nouvelle machine
Copiez et exécutez ce script de "Bootstrap" sur votre nouvelle machine. Il va :
1. Détecter votre environnement (WSL ou Linux).
2. Monter temporairement le NAS (via `drvfs` ou `cifs`).
3. Appliquer la configuration shell minimaliste.
4. Vous proposer de rendre le montage du NAS permanent.

```bash
# Créer le script
nano bootstrap.sh
# (Collez le contenu de scripts/bootstrap_env.sh)

# Lancer
bash bootstrap.sh
```

Le script est disponible ici : [scripts/bootstrap_env.sh](../scripts/bootstrap_env.sh)

## 5. Configuration Manuelle (Référence)

Si vous préférez configurer manuellement ou comprendre ce que fait le script.

### Installation de Starship
Starship est un prompt cross-shell rapide et personnalisable.

```bash
curl -sS https://starship.rs/install.sh | sh -s -- -y
```

### Configuration du .bashrc

Ajoutez ceci à votre `.bashrc` pour charger Starship et les alias :

```bash
# --- Starship & Alias ---
eval "$(starship init bash)"
[ -f "/mnt/nas/aliases.sh" ] && source "/mnt/nas/aliases.sh"
```


Il existe deux façons de gérer vos alias et configurations :

1.  **Méthode Centralisée (Ma configuration)** : Je charge mes alias depuis mon NAS pour les partager entre WSL et mes serveurs (voir [Section 7](#7-centralisation-des-alias-nas)).
2.  **Méthode Autonome (Pour démarrer)** : Vous pouvez tout configurer localement en utilisant le script fourni (voir [Section 6](#6-script-dautomatisation)) ou en copiant le bloc ci-dessous.

Voici le contenu de référence (ajouté automatiquement par le script) :

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

## 7. Centralisation des Alias (NAS)

Pour partager vos alias entre plusieurs machines (WSL, Serveur Ubuntu, etc.), vous pouvez stocker un fichier de configuration sur un NAS.

### Configuration WSL (Montage)

WSL monte automatiquement les lecteurs réseaux Windows s'ils sont mappés, mais un montage manuel est plus robuste.

1.  **Créer le point de montage** :
    ```bash
## 6. Montage NAS (Script Automatisé)

Pour accéder aux fichiers partagés et aux alias centralisés, nous utilisons un script qui configure automatiquement le montage du NAS (compatible WSL et Ubuntu Server).

### Script `setup_nas.sh`

Ce script gère :
*   L'installation des dépendances (`cifs-utils`).
*   La création sécurisée du fichier d'identifiants (`~/.smbcredentials`).
*   La détection de l'environnement (WSL vs Linux Natif).
*   La configuration persistante dans `/etc/fstab`.

**Utilisation :**
```bash
./scripts/setup_nas.sh
```

## 7. Centralisation des Alias (Git + NAS)

Pour maintenir une configuration cohérente entre WSL et le serveur T420, nous utilisons une approche "GitOps" :
1.  **Source de vérité** : Le fichier `shell/aliases.sh` dans le dépôt Git.
2.  **Distribution** : Le NAS sert de point de partage.
3.  **Consommation** : WSL et le T420 chargent le fichier depuis le NAS (ou Git localement).

### 1. Création du fichier d'alias
Créez `shell/aliases.sh` dans votre projet :

```bash
# --- SRE Lab Utils ---
alias bye='~/SCRIPTS/stop_lab; exit'
alias start_lab='~/SCRIPTS/start_lab'

# Fonction pour déployer les alias sur le NAS
deploy_aliases() {
    cp "$HOME/github/sre-lab-infrastructure/shell/aliases.sh" "/mnt/nas/aliases.sh"
    echo "✅ Alias déployés sur le NAS (/mnt/nas/aliases.sh)"
}

# --- System ---
alias update='sudo apt update && sudo apt upgrade -y'
# ... ajoutez vos autres alias ici ...
```

### 2. Configuration WSL (.bashrc)
Ajoutez ceci à votre `~/.bashrc` pour charger les alias (priorité au Git local) :

```bash
# --- Chargement des alias centralisés (SRE Lab) ---
NAS_ALIAS_FILE="/mnt/nas/aliases.sh"
LOCAL_ALIAS_FILE="$HOME/github/sre-lab-infrastructure/shell/aliases.sh"

if [ -f "$LOCAL_ALIAS_FILE" ]; then
    # Priorité au fichier local (Git) si on est dans le repo
    source "$LOCAL_ALIAS_FILE"
elif [ -f "$NAS_ALIAS_FILE" ]; then
    # Sinon on charge depuis le NAS
    source "$NAS_ALIAS_FILE"
fi
```

### 3. Configuration T420 (.bashrc)
Sur le serveur, ajoutez ceci pour charger les alias depuis le NAS :

```bash
# --- Chargement des alias centralisés (SRE Lab) ---
NAS_ALIAS_FILE="/mnt/nas/aliases.sh"
if [ -f "$NAS_ALIAS_FILE" ]; then
    source "$NAS_ALIAS_FILE"
fi
```

### Workflow de mise à jour
1.  Modifiez `shell/aliases.sh` dans VS Code.
2.  Testez sur WSL (ouvrez un nouveau terminal).
3.  Déployez sur le NAS :
    ```bash
    deploy_aliases
    ```
4.  Le T420 aura les nouveaux alias à sa prochaine connexion.


## 5. Workflow SRE (Démarrage & Arrêt)

Pour simplifier l'utilisation du lab, nous utilisons des scripts automatisés pour gérer le cycle de vie du serveur T420.

### Script de Démarrage (`start_lab.sh`)

Ce script utilise PowerShell (depuis WSL) pour envoyer le "Magic Packet" WoL, car le broadcast UDP est bloqué par le NAT de WSL2.

Fichier : `~/scripts/start_lab.sh`

```bash
#!/bin/bash

# Configuration
MAC_ADDR="00:21:CC:70:E9:BA"      # MAC Ethernet du T420
SERVER_IP="192.168.1.120"         # IP Statique du T420
SSH_USER="nicolab"

echo "=== Démarrage de la Session Lab SRE ==="

# 1. Démarrage du serveur (Wake-on-LAN via PowerShell)
echo "[1/3] Envoi du Magic Packet (WoL)..."
powershell.exe -Command "
\$mac = '$MAC_ADDR'
\$macBytes = \$mac -split '[:-]' | ForEach-Object { [byte]('0x' + \$_) }
\$packet = [byte[]](,0xFF * 6) + \$macBytes * 16
\$client = New-Object System.Net.Sockets.UdpClient
\$client.Connect(([System.Net.IPAddress]::Broadcast), 9)
\$client.Send(\$packet, \$packet.Length)
\$client.Close()
"

# 2. Attente de la disponibilité
echo "[2/3] Attente du démarrage du serveur ($SERVER_IP)..."
START_TIME=$(date +%s)
TIMEOUT=120 

while ! ping -c 1 -W 1 "$SERVER_IP" &> /dev/null; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    if [ $ELAPSED -gt $TIMEOUT ]; then
        echo "Erreur : Timeout."
        exit 1
    fi
    printf "."
    sleep 1
done

echo ""
echo "[3/3] Serveur prêt !"
echo "-------------------------------------------------------"
echo "IP : $SERVER_IP"
echo "SSH : ssh $SSH_USER@$SERVER_IP"
echo "-------------------------------------------------------"
```

### Script d'Arrêt (`stop_lab.sh`)

Ce script éteint proprement le serveur via SSH.

Fichier : `~/scripts/stop_lab.sh`

```bash
#!/bin/bash
SERVER_IP="192.168.1.120"
SSH_USER="nicolab"

echo "=== Arrêt du Lab SRE ==="
if ping -c 1 -W 1 "$SERVER_IP" &> /dev/null; then
    echo "Envoi de l'ordre d'extinction..."
    ssh -o ConnectTimeout=5 "$SSH_USER@$SERVER_IP" "sudo shutdown -h now"
else
    echo "Le serveur est déjà éteint ou inaccessible."
fi
```

### Installation des Raccourcis et Alias

Pour une utilisation fluide, nous créons des raccourcis et un alias `bye`.

1.  **Créer le dossier de scripts et les liens symboliques :**
    ```bash
    mkdir -p ~/SCRIPTS
    ln -sf ~/github/sre-lab-infrastructure/scripts/start_lab.sh ~/SCRIPTS/start_lab
    ln -sf ~/github/sre-lab-infrastructure/scripts/stop_lab.sh ~/SCRIPTS/stop_lab
    chmod +x ~/github/sre-lab-infrastructure/scripts/*.sh
    ```

2.  **Configurer l'alias `bye` dans `.bashrc` :**
    Ajoutez cette ligne à la fin de votre `~/.bashrc` :
    ```bash
    alias bye='~/SCRIPTS/stop_lab; exit'
    ```
    Rechargez la configuration : `source ~/.bashrc`

### Utilisation Quotidienne

1.  **Démarrer le lab :**
    ```bash
    ~/SCRIPTS/start_lab
    ```
2.  **Travailler...**
3.  **Finir la session (Éteindre et fermer) :**
    ```bash
    bye
    ```

