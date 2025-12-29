#!/bin/bash

# Script pour déployer la configuration (Alias + Starship) sur le NAS

echo "📦 Déploiement de la configuration sur le NAS..."

# 1. Alias
cp "$HOME/github/sre-lab-infrastructure/shell/aliases.sh" "/mnt/nas/aliases.sh"
echo "   ✅ Alias copiés (/mnt/nas/aliases.sh)"

# 2. Starship Config
cp "$HOME/github/sre-lab-infrastructure/config/starship.toml" "/mnt/nas/starship.toml"
echo "   ✅ Config Starship copiée (/mnt/nas/starship.toml)"

# 3. Scripts d'installation (Kit de déploiement)
cp "$HOME/github/sre-lab-infrastructure/scripts/bootstrap_client.sh" "/mnt/nas/bootstrap_client.sh"
echo "   ✅ Scripts d'installation copiés (/mnt/nas/bootstrap_client.sh)"

echo "🚀 Déploiement terminé."
