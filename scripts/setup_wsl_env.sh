#!/bin/bash

echo "=== Configuration de l'environnement WSL pour SRE ==="
echo "Ce script va configurer votre environnement : Alias, kube-ps1, SSH, Git."

# --- Interactive Configuration ---
read -p "Entrez votre nom d'utilisateur Windows (ex: JeanDupont) : " WINDOWS_USER
read -p "Entrez le nom de votre clé SSH (ex: id_rsa ou nicolas.bailleul.wrk) : " SSH_KEY_NAME
read -p "Entrez votre Nom pour Git (ex: Jean Dupont) : " GIT_USER_NAME
read -p "Entrez votre Email pour Git (ex: jean.dupont@email.com) : " GIT_USER_EMAIL

echo "-----------------------------------------------------"
echo "Début de la configuration..."

# 1. Update and Install dependencies
echo "[1/5] Mise à jour du système et installation des dépendances..."
sudo apt-get update && sudo apt-get install -y wget git

# 2. Aliases
echo "[2/5] Configuration des alias dans .bashrc..."
# Backup .bashrc
cp ~/.bashrc ~/.bashrc.bak
echo "Sauvegarde de .bashrc effectuée vers .bashrc.bak"

cat << 'EOF' >> ~/.bashrc

# --- Custom Aliases ---
# Editor
alias nano="vim"

# Kubernetes
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

EOF

# 3. kube-ps1 Installation & Configuration
echo "[3/5] Installation de kube-ps1..."
if [ ! -f /usr/local/bin/kube-ps1.sh ]; then
    wget https://github.com/jonmosco/kube-ps1/archive/refs/tags/v0.9.0.tar.gz
    tar xzvf v0.9.0.tar.gz
    sudo cp kube-ps1-0.9.0/kube-ps1.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/kube-ps1.sh
    rm -rf kube-ps1-0.9.0 v0.9.0.tar.gz
    echo "kube-ps1 installé."
else
    echo "kube-ps1 déjà présent."
fi

echo "Configuration de kube-ps1 dans .bashrc..."
cat << 'EOF' >> ~/.bashrc

# --- kube-ps1 Configuration ---
source /usr/local/bin/kube-ps1.sh
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] $(kube_ps1)\$ '
EOF

# 4. SSH Configuration
echo "[4/5] Configuration SSH..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

WINDOWS_SSH_PATH="/mnt/c/Users/$WINDOWS_USER/.ssh"
if [ -d "$WINDOWS_SSH_PATH" ]; then
    echo "Recherche des clés dans $WINDOWS_SSH_PATH..."
    if [ -f "$WINDOWS_SSH_PATH/$SSH_KEY_NAME" ]; then
        echo "Copie des clés SSH depuis Windows..."
        cp "$WINDOWS_SSH_PATH/$SSH_KEY_NAME"* ~/.ssh/
        chmod 600 ~/.ssh/"$SSH_KEY_NAME"
        if [ -f ~/.ssh/"$SSH_KEY_NAME".pub ]; then
            chmod 644 ~/.ssh/"$SSH_KEY_NAME".pub
        fi
    else
        echo "ATTENTION: La clé $SSH_KEY_NAME est introuvable dans $WINDOWS_SSH_PATH."
    fi
else
    echo "ATTENTION: Dossier .ssh Windows introuvable ($WINDOWS_SSH_PATH). Copie ignorée."
fi

echo "Création de ~/.ssh/config..."
cat << EOF > ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/$SSH_KEY_NAME
    AddKeysToAgent yes
EOF
