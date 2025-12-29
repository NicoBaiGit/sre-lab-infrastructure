<div align="center">

# SRE Lab Infrastructure

**Plateforme d'apprentissage et d'expérimentation pour le Site Reliability Engineering.**

Infrastructure as Code • Kubernetes • GitOps • Observabilité

[📖 Lire la Documentation Complète](https://NicoBaiGit.github.io/sre-lab-infrastructure/)

</div>

---

## 📚 Contenu

| 💻 **Poste de Travail** | 🖥️ **Le Serveur** | 🚀 **Guide du Lab** |
|:---:|:---:|:---:|
| Configuration WSL2, Shell, Outils | Installation T420, OS, Réseau | K3s, ArgoCD, Monitoring |
| [Voir la doc](docs/wsl.md) | [Voir la doc](docs/ubuntu-server.md) | [Voir la doc](docs/setup-lab.md) |

## ⚡ Démarrage Rapide

### 1. Initialisation du NAS (Serveur Central)
Assurez-vous que le NAS est prêt et accessible.
```bash
# Depuis votre poste principal (WSL)
./scripts/deploy_to_nas.sh
```

### 2. Bootstrap d'un nouveau client (WSL, Serveur, VM)
Ce script connecte la machine au NAS et configure le shell.
```bash
# Sur la machine cible
./scripts/bootstrap_client.sh
source ~/.bashrc
```

## 🔄 Gestion de l'Environnement (Centralisé)

Nous utilisons le NAS comme source de vérité pour la configuration du shell (Alias, Prompt) sur toutes les machines du lab.

### Flux de travail

1.  **Modification** : Editez les fichiers dans ce dépôt.
    *   Alias : `shell/aliases.sh`
    *   Prompt : `config/starship.toml`
2.  **Déploiement** : Depuis votre WSL, lancez `deploy_env`.
    *   Cela copie les fichiers vers le NAS (`/mnt/nas`).
3.  **Consommation** : Les machines (WSL, Serveurs) chargent la configuration depuis le NAS au démarrage du shell.

### Scripts d'installation

*   **Bootstrap Universel** : `scripts/bootstrap_client.sh` (Script unique pour WSL et Serveur. Monte le NAS, installe Starship, configure le shell).
*   **Déploiement** : `scripts/deploy_to_nas.sh` (Copie la configuration locale vers le NAS).

## 🛠️ Développement de la Documentation

Le site est généré avec [MkDocs](https://www.mkdocs.org/) et le thème [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

### Installation & Lancement

```bash
make install
make serve
```
Le site sera accessible sur `http://127.0.0.1:8000`.

