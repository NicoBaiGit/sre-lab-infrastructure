#!/bin/bash

# Configuration
# Remplacer par l'adresse MAC de l'interface Ethernet du T420
MAC_ADDR="00:21:CC:70:E9:BA" 
# Remplacer par l'adresse IP statique ou réservée du T420
SERVER_IP="192.168.1.120"      
# Utilisateur SSH sur le serveur
SSH_USER="nicolab"               

# Fonction de nettoyage (arrêt du serveur)
cleanup() {
    echo ""
    echo "=== Fin de session détectée ==="
    echo "Arrêt du serveur T420 en cours..."
    # On tente d'éteindre le serveur via SSH
    # Nécessite que la clé SSH soit configurée (ssh-copy-id)
    ssh -o ConnectTimeout=5 "$SSH_USER@$SERVER_IP" "sudo shutdown -h now"
    
    if [ $? -eq 0 ]; then
        echo "Ordre d'extinction envoyé avec succès."
    else
        echo "Erreur lors de l'envoi de l'ordre d'extinction. Le serveur est peut-être déjà éteint ou inaccessible."
    fi
}

# Vérification des dépendances
if ! command -v wakeonlan &> /dev/null; then
    echo "'wakeonlan' n'est pas installé."
    read -p "Voulez-vous l'installer maintenant ? (O/n) " choice
    case "$choice" in 
      y|Y|o|O|"" ) 
        echo "Installation de wakeonlan..."
        sudo apt-get update && sudo apt-get install -y wakeonlan
        ;;
      * ) 
        echo "Installation annulée. Le script ne peut pas continuer sans wakeonlan."
        exit 1
        ;;
    esac
fi

# Intercepter les signaux de sortie (EXIT, SIGINT=Ctrl+C, SIGTERM)
# trap cleanup EXIT SIGINT SIGTERM

echo "=== Démarrage de la Session Lab SRE ==="

# 1. Démarrage du serveur (Wake-on-LAN)
echo "[1/3] Envoi du Magic Packet (WoL) à $MAC_ADDR..."

WOL_SENT=false

# Méthode 1 : PowerShell (Windows) - Recommandé pour WSL2 (contourne le NAT)
# On teste d'abord si powershell.exe est exécutable pour éviter les erreurs "Exec format error"
if command -v powershell.exe &> /dev/null && powershell.exe -Command "exit" &> /dev/null; then
    powershell.exe -Command "
    \$mac = '$MAC_ADDR'
    \$macBytes = \$mac -split '[:-]' | ForEach-Object { [byte]('0x' + \$_) }
    \$packet = [byte[]](,0xFF * 6) + \$macBytes * 16
    \$client = New-Object System.Net.Sockets.UdpClient
    \$client.Connect(([System.Net.IPAddress]::Broadcast), 9)
    \$client.Send(\$packet, \$packet.Length)
    \$client.Close()
    " 2> /dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✅ WoL envoyé via Windows (PowerShell)."
        WOL_SENT=true
    fi
fi

# Méthode 2 : wakeonlan (Linux) - Fallback
if [ "$WOL_SENT" = "false" ]; then
    echo "   ⚠️ PowerShell indisponible. Utilisation de 'wakeonlan' (Linux native)..."
    wakeonlan "$MAC_ADDR"
fi

# 2. Attente de la disponibilité
echo "[2/3] Attente du démarrage du serveur ($SERVER_IP)..."
START_TIME=$(date +%s)
TIMEOUT=120 # 2 minutes timeout

while ! ping -c 1 -W 1 "$SERVER_IP" &> /dev/null; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $TIMEOUT ]; then
        echo ""
        echo "Erreur : Le serveur n'a pas répondu après $TIMEOUT secondes."
        exit 1
    fi
    
    printf "."
    sleep 1
done

echo ""
echo "Serveur en ligne !"

# 3. Session active
echo "[3/3] Serveur prêt !"
echo "-------------------------------------------------------"
echo "Le serveur est allumé et accessible."
echo "IP : $SERVER_IP"
echo "SSH : ssh $SSH_USER@$SERVER_IP"
echo "-------------------------------------------------------"

