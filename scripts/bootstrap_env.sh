#!/bin/bash
# Script générique pour initialiser l'environnement (WSL ou Linux) depuis le NAS
# Usage : Copiez ce script sur la machine cible et exécutez-le.

NAS_IP="192.168.1.2" # A adapter si besoin
NAS_SHARE="work"     # A adapter si besoin
MOUNT_POINT="/mnt/nas"

echo "=== Bootstrap Environnement SRE (WSL/Linux) ==="

# Détection de l'environnement
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
    IS_WSL=true
    echo "🖥️  Environnement détecté : WSL"
else
    IS_WSL=false
    echo "🐧 Environnement détecté : Linux Standard"
fi

# 1. Montage du NAS (Temporaire pour l'installation)
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "📂 Le NAS n'est pas monté. Tentative de montage..."
    sudo mkdir -p "$MOUNT_POINT"
    
    MOUNT_SUCCESS=false

    if [ "$IS_WSL" = true ]; then
        # --- Méthode WSL (drvfs) ---
        echo "   Tentative de montage via drvfs..."
        if sudo mount -t drvfs "\\\\$NAS_IP\\$NAS_SHARE" "$MOUNT_POINT"; then
            MOUNT_SUCCESS=true
        else
            echo "   ⚠️ Échec drvfs. Tentative de repli sur cifs..."
        fi
    fi

    if [ "$MOUNT_SUCCESS" = false ]; then
        # --- Méthode Linux / Repli WSL (cifs) ---
        echo "   Vérification de cifs-utils..."
        if ! command -v mount.cifs &> /dev/null; then
            echo "   Installation de cifs-utils..."
            sudo apt-get update && sudo apt-get install -y cifs-utils
        fi

        echo "   Tentative de montage via cifs..."
        read -p "   Utilisateur NAS : " NAS_USER
        read -s -p "   Mot de passe NAS : " NAS_PASS
        echo

        if sudo mount -t cifs "//$NAS_IP/$NAS_SHARE" "$MOUNT_POINT" -o "username=$NAS_USER,password=$NAS_PASS,vers=3.0"; then
            MOUNT_SUCCESS=true
        elif sudo mount -t cifs "//$NAS_IP/$NAS_SHARE" "$MOUNT_POINT" -o "username=$NAS_USER,password=$NAS_PASS,vers=2.0"; then
            MOUNT_SUCCESS=true
        else
            echo "❌ Échec du montage cifs."
        fi
    fi

    if [ "$MOUNT_SUCCESS" = false ]; then
        echo "❌ Impossible de monter le NAS. Arrêt."
        exit 1
    fi
    echo "✅ NAS monté avec succès."
fi

# 2. Lancement du script minimal (Alias + Starship)
SCRIPT_MINIMAL="$MOUNT_POINT/setup_shell_minimal.sh"
if [ -f "$SCRIPT_MINIMAL" ]; then
    echo "🚀 Lancement du script d'installation minimal..."
    bash "$SCRIPT_MINIMAL"
else
    echo "❌ Script setup_shell_minimal.sh introuvable sur le NAS ($SCRIPT_MINIMAL)."
    echo "   Avez-vous lancé 'deploy_env' depuis votre machine principale ?"
    exit 1
fi

# 3. Proposition de persistance (Montage permanent)
echo
read -p "💾 Voulez-vous configurer le montage permanent du NAS (/etc/fstab) ? (o/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Oo]$ ]]; then
    SCRIPT_NAS="$MOUNT_POINT/setup_nas.sh"
    if [ -f "$SCRIPT_NAS" ]; then
        echo "   Lancement de la configuration NAS..."
        # On copie le script localement pour l'exécuter (évite les soucis si on démonte)
        cp "$SCRIPT_NAS" ./setup_nas_local.sh
        chmod +x ./setup_nas_local.sh
        ./setup_nas_local.sh
        rm ./setup_nas_local.sh
    else
        echo "⚠️  Script setup_nas.sh introuvable sur le NAS."
    fi
fi

echo
echo "=== Terminé ! ==="
echo "N'oubliez pas de recharger votre shell : source ~/.bashrc"
