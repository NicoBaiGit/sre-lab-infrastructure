#!/bin/bash

# Configuration
SERVER_IP="192.168.1.120"
SSH_USER="nicolab"

echo "=== Arrêt du Lab SRE ==="
echo "Vérification de la présence du serveur ($SERVER_IP)..."

# Check if server is reachable first to avoid long timeout
if ping -c 1 -W 1 "$SERVER_IP" &> /dev/null; then
    echo "Serveur en ligne. Envoi de l'ordre d'extinction..."
    ssh -o ConnectTimeout=5 "$SSH_USER@$SERVER_IP" "sudo shutdown -h now"
    
    if [ $? -eq 0 ]; then
        echo "✅ Ordre d'extinction envoyé avec succès."
    else
        echo "❌ Erreur lors de l'envoi de l'ordre d'extinction."
    fi
else
    echo "ℹ️  Le serveur n'est pas accessible (probablement déjà éteint)."
fi
