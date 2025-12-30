#!/bin/bash

# ==================================================================================
# SRE Lab - Init Server (T420)
# ==================================================================================
# Ce script installe les outils de base et prépare le système (Swap off).
# A exécuter une seule fois après l'installation de l'OS.
# ==================================================================================

echo "🚀 Initialisation du serveur T420..."

# 1. Mise à jour du système
echo "📦 Mise à jour des paquets..."
sudo apt update && sudo apt upgrade -y

# 2. Installation des outils de base
echo "🛠️ Installation des outils (curl, git, htop, vim, neofetch)..."
sudo apt install -y curl git htop vim neofetch

# 3. Désactivation du Swap (Requis pour Kubernetes/K3s)
if grep -q " swap " /etc/fstab && ! grep -q "^#" /etc/fstab; then
    echo "🚫 Désactivation du Swap (Persistant)..."
    sudo swapoff -a
    # Commente la ligne swap dans fstab
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
else
    echo "✅ Swap déjà désactivé."
fi

echo "🎉 Serveur prêt ! Vous pouvez maintenant lancer le bootstrap."
