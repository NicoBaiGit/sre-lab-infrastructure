#!/bin/bash

# Configuration
NAS_IP="192.168.1.2"
NAS_SHARE="work"
NAS_USER="work"
MOUNT_POINT="/mnt/nas"
CRED_FILE="$HOME/.smbcredentials"

echo "=== Configuration du montage NAS ($NAS_IP/$NAS_SHARE) ==="

# 1. Installation des dépendances
echo "[1/4] Installation de cifs-utils..."
if ! dpkg -l | grep -q cifs-utils; then
    sudo apt-get update && sudo apt-get install -y cifs-utils
else
    echo "cifs-utils est déjà installé."
fi

# 2. Gestion des identifiants (Sécurisé)
echo "[2/4] Configuration des identifiants..."
if [ -f "$CRED_FILE" ]; then
    echo "Le fichier $CRED_FILE existe déjà."
    read -p "Voulez-vous le remplacer ? (o/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "On garde les identifiants existants."
    else
        rm "$CRED_FILE"
    fi
fi

if [ ! -f "$CRED_FILE" ]; then
    read -s -p "Entrez le mot de passe pour l'utilisateur NAS '$NAS_USER' : " NAS_PASSWORD
    echo
    cat <<EOF > "$CRED_FILE"
username=$NAS_USER
password=$NAS_PASSWORD
domain=WORKGROUP
EOF
    chmod 600 "$CRED_FILE"
    echo "Fichier d'identifiants créé et protégé."
fi

# 3. Création du point de montage
echo "[3/4] Création du point de montage $MOUNT_POINT..."
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# 4. Configuration fstab (Persistance)
echo "[4/4] Configuration de /etc/fstab..."

# Détection de l'environnement (WSL ou Linux Natif)
if grep -q "Microsoft" /proc/version || grep -q "WSL" /proc/version; then
    IS_WSL=true
    echo "Environnement détecté : WSL"
else
    IS_WSL=false
    echo "Environnement détecté : Linux Natif"
fi

# Nettoyage de l'ancienne entrée si elle existe
if grep -q "$NAS_IP/$NAS_SHARE" /etc/fstab || grep -q "$NAS_IP\\\\$NAS_SHARE" /etc/fstab; then
    echo "Nettoyage de l'ancienne entrée dans /etc/fstab..."
    # On supprime les lignes contenant l'IP et le partage (format slash ou backslash)
    sudo sed -i "\|${NAS_IP}.*${NAS_SHARE}|d" /etc/fstab
fi

if [ "$IS_WSL" = true ]; then
    # --- Configuration WSL (drvfs) ---
    echo "Configuration pour WSL (via drvfs)..."
    # Note: drvfs n'utilise pas le fichier credentials cifs, il utilise les identifiants Windows ou demande au montage.
    # Pour automatiser, on peut passer user/pass en clair (moins sécure) ou compter sur le fait que Windows a déjà accès.
    # Ici, on va tenter de monter sans credentials explicites (Windows Auth) ou avec user/pass si besoin.
    
    # On lit le mot de passe depuis le fichier credentials pour l'injecter si besoin
    if [ -f "$CRED_FILE" ]; then
        source "$CRED_FILE"
        # FSTAB pour WSL : on utilise le format UNC Windows avec des backslashes échappés
        # Format : \\192.168.1.2\work /mnt/nas drvfs defaults 0 0
        FSTAB_ENTRY="\\\\\\\\$NAS_IP\\\\$NAS_SHARE $MOUNT_POINT drvfs defaults,uid=$(id -u),gid=$(id -g) 0 0"
        
        # Note : drvfs ne supporte pas bien l'injection de credentials via fstab comme cifs.
        # Si Windows a déjà accès au NAS (lecteur mappé ou identifiants enregistrés dans Windows), ça marchera tout seul.
        echo "⚠️  Sous WSL, assurez-vous d'avoir accédé au NAS au moins une fois depuis l'Explorateur Windows"
        echo "    et d'avoir coché 'Mémoriser mes identifiants'."
    fi

else
    # --- Configuration Linux Natif (cifs) ---
    echo "Configuration pour Linux Natif (cifs)..."
    
    # On récupère l'UID et le GID de l'utilisateur courant
    USER_UID=$(id -u)
    USER_GID=$(id -g)

    # Détection automatique de la version SMB
    echo "Détection de la version SMB supportée..."
    DETECTED_VERS=""
    for v in "3.0" "2.0" "1.0"; do
        echo -n "Test de la version $v... "
        ERR_MSG=$(sudo mount -t cifs "//$NAS_IP/$NAS_SHARE" "$MOUNT_POINT" -o "credentials=$CRED_FILE,iocharset=utf8,uid=$USER_UID,gid=$USER_GID,noperm,vers=$v" 2>&1)
        if [ $? -eq 0 ]; then
            echo "OK !"
            DETECTED_VERS="$v"
            sudo umount "$MOUNT_POINT"
            break
        else
            echo "Échec."
        fi
    done

    if [ -z "$DETECTED_VERS" ]; then
        echo "❌ Impossible de trouver une version SMB compatible."
        exit 1
    fi

    FSTAB_ENTRY="//$NAS_IP/$NAS_SHARE $MOUNT_POINT cifs credentials=$CRED_FILE,iocharset=utf8,uid=$USER_UID,gid=$USER_GID,noperm,vers=$DETECTED_VERS 0 0"
fi

echo "Ajout de la nouvelle entrée dans /etc/fstab..."
echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null

# Test du montage
echo "Tentative de montage..."
sudo mount -a

if mountpoint -q "$MOUNT_POINT"; then
    echo "✅ Succès ! Le NAS est monté dans $MOUNT_POINT"
    ls -la "$MOUNT_POINT" | head -n 5
else
    echo "❌ Erreur : Le montage a échoué. Vérifiez les logs ou les identifiants."
fi
