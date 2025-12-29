#!/bin/bash

# ==================================================================================
# SRE Lab - Bootstrap Client (Universal)
# ==================================================================================
# Ce script est conçu pour être exécuté sur n'importe quelle machine "client" du lab
# (WSL, Ubuntu Server, VM, etc.) pour s'attacher à la configuration centralisée sur le NAS.
#
# Pré-requis :
# - Le NAS doit être accessible.
# - Le montage du NAS doit être effectué (ou le script tentera de le faire).
# ==================================================================================

NAS_MOUNT_POINT="/mnt/nas"
NAS_IP="192.168.1.2" # A ADAPTER SELON VOTRE RESEAU
NAS_SHARE_PATH="//192.168.1.2/work" # A ADAPTER

echo "🚀 Démarrage du Bootstrap Client SRE Lab..."

# 1. Vérification / Création du point de montage
if [ ! -d "$NAS_MOUNT_POINT" ]; then
    echo "📂 Création du point de montage $NAS_MOUNT_POINT..."
    sudo mkdir -p "$NAS_MOUNT_POINT"
fi

# 2. Vérification du montage
if mount | grep -q "$NAS_MOUNT_POINT"; then
    echo "✅ NAS déjà monté."
else
    echo "⚠️ NAS non monté. Configuration du montage automatique..."
    
    # Installation des dépendances CIFS
    if ! dpkg -l | grep -q cifs-utils; then
        echo "📦 Installation de cifs-utils..."
        sudo apt-get update && sudo apt-get install -y cifs-utils
    fi

    # Gestion des crédentials
    CRED_FILE="$HOME/.smbcredentials"
    if [ ! -f "$CRED_FILE" ]; then
        echo "🔐 Configuration des accès NAS (création de $CRED_FILE)"
        read -p "Utilisateur NAS : " NAS_USER
        read -s -p "Mot de passe NAS : " NAS_PASS
        echo ""
        cat <<EOF > "$CRED_FILE"
username=$NAS_USER
password=$NAS_PASS
EOF
        chmod 600 "$CRED_FILE"
    fi

    # Ajout à fstab si absent
    # On utilise l'UID/GID de l'utilisateur courant pour que les fichiers lui appartiennent
    CURRENT_UID=$(id -u)
    CURRENT_GID=$(id -g)
    # Utilisation de vers=2.0 pour une meilleure compatibilité (erreur 95 souvent liée à 3.0 sur certains setups)
    FSTAB_ENTRY="$NAS_SHARE_PATH $NAS_MOUNT_POINT cifs credentials=$CRED_FILE,uid=$CURRENT_UID,gid=$CURRENT_GID,iocharset=utf8,vers=2.0 0 0"
    
    if ! grep -q "$NAS_SHARE_PATH" /etc/fstab; then
        echo "📝 Ajout de l'entrée dans /etc/fstab..."
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
        # Rechargement de systemd pour prendre en compte fstab
        if command -v systemctl &> /dev/null; then
            sudo systemctl daemon-reload
        fi
    fi

    # Montage
    echo "📂 Montage du NAS..."
    sudo mount "$NAS_MOUNT_POINT"
    
    if mount | grep -q "$NAS_MOUNT_POINT"; then
        echo "   ✅ Montage réussi !"
    else
        echo "   ❌ Echec du montage. Vérifiez les logs (dmesg) ou les infos réseau."
        # On ne quitte pas forcément, car on peut vouloir configurer le reste même si le montage échoue temporairement
        # mais pour la config centralisée, c'est critique.
        exit 1
    fi
fi

# 3. Configuration du Shell (Bash)
echo "🐚 Configuration du Shell (.bashrc)..."

BASHRC="$HOME/.bashrc"
MARKER="# --- SRE LAB CENTRALIZED CONFIG ---"

if ! grep -q "$MARKER" "$BASHRC"; then
    echo "   Injection de la configuration dans $BASHRC..."
    cat <<EOT >> "$BASHRC"

$MARKER
# Cette section charge la configuration depuis le NAS centralisé.

# 1. Chargement des Alias communs
if [ -f "$NAS_MOUNT_POINT/aliases.sh" ]; then
    source "$NAS_MOUNT_POINT/aliases.sh"
fi

# 2. Configuration Starship (Prompt)
if command -v starship &> /dev/null; then
    export STARSHIP_CONFIG="$NAS_MOUNT_POINT/starship.toml"
    eval "\$(starship init bash)"
fi

# 3. Ajout des scripts du NAS au PATH (optionnel, ou via alias)
# export PATH=\$PATH:$NAS_MOUNT_POINT/scripts
$MARKER
EOT
    echo "   ✅ Configuration injectée."
else
    echo "   ✅ Configuration déjà présente dans .bashrc."
fi

# 4. Installation de Starship (si absent)
if ! command -v starship &> /dev/null; then
    echo "🌟 Installation de Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# 5. Configuration Sudoers (NOPASSWD)
# Attention : Sécurité. Uniquement pour le Lab.
echo "🔑 Configuration sudoers (NOPASSWD)..."
if ! sudo grep -q "$USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/$USER 2>/dev/null; then
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USER" > /dev/null
    echo "   ✅ Utilisateur $USER ajouté aux sudoers sans mot de passe."
else
    echo "   ✅ Sudoers déjà configuré."
fi

echo "🎉 Bootstrap terminé ! Veuillez recharger votre shell : source ~/.bashrc"
