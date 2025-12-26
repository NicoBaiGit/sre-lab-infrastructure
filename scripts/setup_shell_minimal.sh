#!/bin/bash

echo "=== Configuration Minimaliste du Shell (Starship + Alias) ==="
echo "Ce script configure uniquement l'apparence et les alias, sans toucher à SSH/Git/Kube."

# 1. Configuration Sudoers (NOPASSWD)
echo "[1/4] Configuration des privilèges sudo (NOPASSWD)..."
if sudo grep -q "$USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/$USER 2>/dev/null; then
    echo "Privilèges sudo déjà configurés."
else
    echo "Configuration des droits sudo pour $USER..."
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER > /dev/null
    sudo chmod 0440 /etc/sudoers.d/$USER
    echo "✅ Droits sudo configurés."
fi

# 2. Update and Install dependencies
echo "[2/4] Installation des dépendances (curl, git)..."
sudo apt-get update && sudo apt-get install -y curl git

# 3. Aliases
echo "[3/4] Configuration des alias dans .bashrc..."
if grep -q "SRE Lab Aliases" ~/.bashrc; then
    echo "Les alias semblent déjà configurés dans .bashrc. Ignoré."
else
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

