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

Configurez votre environnement en une commande :

### Sur WSL
```bash
~/github/sre-lab-infrastructure/scripts/setup_wsl_env.sh
source ~/.bashrc
```

### Sur le Serveur
```bash
~/github/sre-lab-infrastructure/scripts/setup_server_env.sh
source ~/.bashrc
```

## 🔄 Gestion de l'Environnement (GitOps)

Nous utilisons une approche "GitOps-lite" pour gérer la configuration du shell (Alias, Prompt) sur toutes les machines du lab.

### Flux de travail

1.  **Modification** : Editez les fichiers dans ce dépôt.
    *   Alias : `shell/aliases.sh`
    *   Prompt : `config/starship.toml`
2.  **Déploiement** : Depuis votre WSL, lancez la fonction `deploy_env` (définie dans les alias).
    *   Cela copie les fichiers vers le NAS (`/mnt/nas`).
3.  **Consommation** : Les machines (WSL, Serveurs) chargent la configuration depuis le NAS au démarrage du shell.

### Scripts d'installation

*   **WSL** : `scripts/setup_wsl_env.sh` (Installe Starship, configure Git/SSH, lie le .bashrc au NAS).
*   **Serveur (T420)** : `scripts/setup_server_env.sh` (Installe Starship, lie le .bashrc au NAS).
*   **NAS** : `scripts/setup_nas.sh` (Monte le partage NAS nécessaire pour accéder aux configs).

## 🛠️ Développement de la Documentation

Le site est généré avec [MkDocs](https://www.mkdocs.org/) et le thème [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

### Installation & Lancement

```bash
make install
make serve
```
Le site sera accessible sur `http://127.0.0.1:8000`.

