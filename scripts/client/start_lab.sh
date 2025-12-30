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
# Recherche de l'exécutable PowerShell (PowerShell 7 'pwsh.exe' ou Windows PowerShell 'powershell.exe')
PS_BIN=""
if command -v pwsh.exe &> /dev/null; then
    PS_BIN="pwsh.exe"
    echo "   ℹ️  PowerShell 7 détecté ($PS_BIN)."
elif command -v powershell.exe &> /dev/null; then
    PS_BIN="powershell.exe"
    echo "   ℹ️  Windows PowerShell détecté ($PS_BIN)."
fi

if [ -n "$PS_BIN" ]; then
    # Tentative d'envoi du Magic Packet via PowerShell
    $PS_BIN -Command "
    \$mac = '$MAC_ADDR'
    \$macBytes = \$mac -split '[:-]' | ForEach-Object { [byte]('0x' + \$_) }
    \$packet = [byte[]](,0xFF * 6) + \$macBytes * 16
    \$client = New-Object System.Net.Sockets.UdpClient
    \$client.Connect(([System.Net.IPAddress]::Broadcast), 9)
    \$client.Send(\$packet, \$packet.Length)
    \$client.Close()
    " > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "   ✅ WoL envoyé via Windows ($PS_BIN)."
        WOL_SENT=true
    else
        echo "   ⚠️ Erreur lors de l'exécution de $PS_BIN (Vérifiez votre config WSL Interop)."
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

