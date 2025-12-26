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

EOF

# 3. Starship Installation (Prompt Moderne : Git + K8s)
echo "[3/5] Installation de Starship (Prompt)..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo "Starship installé."
else
    echo "Starship est déjà installé."
fi

echo "Configuration de Starship dans .bashrc..."
cat << 'EOF' >> ~/.bashrc

# --- Starship Prompt (SRE Lab) ---
# Définition de la source de configuration (Git Local ou NAS)
NAS_CONFIG_FILE="/mnt/nas/starship.toml"
LOCAL_CONFIG_FILE="$HOME/github/sre-lab-infrastructure/config/starship.toml"

if [ -f "$LOCAL_CONFIG_FILE" ]; then
    export STARSHIP_CONFIG="$LOCAL_CONFIG_FILE"
elif [ -f "$NAS_CONFIG_FILE" ]; then
    export STARSHIP_CONFIG="$NAS_CONFIG_FILE"
fi

# Initialisation
eval "$(starship init bash)"

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

# 5. Git Configuration
echo "[5/5] Configuration Git..."
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global core.editor "vim"
git config --global init.defaultBranch main

echo "-----------------------------------------------------"
echo "Configuration terminée !"
echo "Veuillez recharger votre shell ou lancer : source ~/.bashrc"

