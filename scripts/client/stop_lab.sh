#!/bin/bash

# Configuration
SERVER_IP="192.168.1.120"
SSH_USER="nicolab"

echo "=== Arrêt du Lab SRE ==="

# Détection si on est déjà sur le serveur (évite le SSH loopback)
if [ "$(hostname)" = "t420" ] || (hostname -I 2>/dev/null | grep -q "$SERVER_IP"); then
    echo "💻 Exécution locale détectée. Extinction du serveur..."
    sudo shutdown -h now
    exit 0
fi

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
