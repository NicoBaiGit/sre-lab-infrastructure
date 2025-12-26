#!/bin/bash

echo "=== Configuration de l'environnement Ubuntu Server (T420) ==="
echo "Ce script va configurer Starship et les Alias via le NAS."

# Vérification du montage NAS
if [ ! -d "/mnt/nas" ]; then
    echo "ERREUR: Le dossier /mnt/nas n'existe pas."
    echo "Veuillez d'abord lancer le script setup_nas.sh pour monter le partage."
    exit 1
fi

echo "-----------------------------------------------------"
echo "Début de la configuration..."

# 1. Installation de Starship
echo "[1/3] Installation de Starship (Prompt)..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo "Starship installé."
else
    echo "Starship est déjà installé."
fi

# 2. Configuration .bashrc (Alias)
echo "[2/3] Configuration des alias dans .bashrc..."
# Backup .bashrc
cp ~/.bashrc ~/.bashrc.bak
echo "Sauvegarde de .bashrc effectuée vers .bashrc.bak"

cat << 'EOF' >> ~/.bashrc

# --- Chargement des alias centralisés (SRE Lab) ---
NAS_ALIAS_FILE="/mnt/nas/aliases.sh"

if [ -f "$NAS_ALIAS_FILE" ]; then
    source "$NAS_ALIAS_FILE"
else
    echo "ATTENTION: Fichier d'alias introuvable sur le NAS ($NAS_ALIAS_FILE)"
fi
EOF

# 3. Configuration .bashrc (Starship)
echo "[3/3] Configuration de Starship dans .bashrc..."
cat << 'EOF' >> ~/.bashrc

# --- Starship Prompt (SRE Lab) ---
NAS_CONFIG_FILE="/mnt/nas/starship.toml"

if [ -f "$NAS_CONFIG_FILE" ]; then
    export STARSHIP_CONFIG="$NAS_CONFIG_FILE"
fi

# Initialisation
eval "$(starship init bash)"
EOF

echo "-----------------------------------------------------"
echo "Configuration terminée !"
echo "Veuillez recharger votre shell ou lancer : source ~/.bashrc"
