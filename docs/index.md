---
hide:
  - navigation
  - toc
---

<div class="hero-section">
  <div class="hero-title">SRE Lab Infrastructure</div>
  <div class="hero-subtitle">
    Plateforme d'apprentissage et d'expérimentation pour le Site Reliability Engineering.
    <br>
    Infrastructure as Code • Kubernetes • GitOps • Observabilité
  </div>
</div>

<div class="grid-cards">

<a href="architecture.md" class="card">
  <span class="card-icon">🏗️</span>
  <h3>00. Architecture</h3>
  <p>Vue d'ensemble du Lab, flux de données, et stratégie de centralisation NAS.</p>
</a>

<a href="wsl.md" class="card">
  <span class="card-icon">💻</span>
  <h3>01. Poste de Travail</h3>
  <p>Configuration de l'environnement de développement sur WSL2. Shell, Outils, et Automatisation.</p>
</a>

<a href="ubuntu-server.md" class="card">
  <span class="card-icon">🖥️</span>
  <h3>02. Le Serveur</h3>
  <p>Installation et préparation du Lenovo T420. OS, Réseau, et Sécurité.</p>
</a>

<a href="setup-lab.md" class="card">
  <span class="card-icon">🚀</span>
  <h3>03. Guide du Lab</h3>
  <p>Déploiement de Kubernetes (K3s), ArgoCD, et de la stack d'observabilité.</p>
</a>

</div>

## 🌍 Contexte du Lab

Ce projet vise à créer une infrastructure SRE domestique robuste, centralisée et reproductible.

### Matériel
*   **Poste Principal** : Lenovo T14 (Windows 11, 16Go RAM) hébergeant plusieurs sessions WSL2.
*   **Serveur Lab** : Lenovo T420 (Ubuntu Server) pour héberger les charges de travail (K3s).
*   **Stockage Central** : NAS Synology.

### Philosophie : "Centralisation NAS"
L'objectif est d'avoir une expérience unifiée sur toutes les machines (WSL, Serveurs, VM) :

*   **Configuration Unique** : Les alias, le prompt (Starship) et les scripts sont stockés sur le NAS.
*   **Bootstrap Universel** : N'importe quelle machine peut rejoindre le lab en exécutant un script unique qui monte le NAS et configure le shell.
*   **Gestion à distance** : Le lab peut être démarré (WOL) et arrêté depuis n'importe quel point du réseau.

---

## 📅 Chronologie de mise en œuvre (De A à Z)

Pour reconstruire ce lab depuis zéro, suivez ces étapes dans l'ordre :

### 1. Initialisation du NAS (Le Cœur)
Le NAS doit être opérationnel et exposer un partage SMB (ex: `work`).

### 2. Préparation du Poste de Travail (WSL)
C'est votre tour de contrôle.

*   *Action* : Installer WSL sur le T14.
*   *Action* : Cloner ce dépôt Git.
*   *Action* : Lancer le bootstrap (`scripts/common/bootstrap_client.sh`).
    *   *Effet* : Ce script va **monter le NAS** (`/mnt/nas`) et configurer le shell.
*   *Action* : Initialiser le contenu du NAS (Premier déploiement).
    *   Commande : `deploy_lab` (ou `./scripts/nas/deploy_to_nas.sh`)
    *   *Note* : À faire une seule fois pour peupler le NAS vide.
*   *Voir* : [01. Poste de Travail](wsl.md)

### 3. Installation du Serveur (T420)
Le moteur du lab.

*   *Action* : Installer Ubuntu Server sur le T420.
*   *Action* : Configurer le réseau et le SSH.
*   *Action* : Lancer le bootstrap pour récupérer la config commune (Alias, Starship).
*   *Voir* : [02. Le Serveur](ubuntu-server.md)

### 4. Déploiement du Lab SRE
La couche applicative.

*   *Action* : Installer K3s sur le T420.
*   *Action* : Déployer ArgoCD et la stack de monitoring.
*   *Voir* : [03. Guide du Lab](setup-lab.md)

---

## ⚡ Démarrage Rapide (Maintenance)

Une fois le lab installé, voici les commandes courantes :

=== "Nouveau Client (WSL/Serveur)"

    ```bash
    # 1. Cloner le repo (si pas fait)
    git clone https://github.com/NicoBaiGit/sre-lab-infrastructure.git ~/github/sre-lab-infrastructure

    # 2. Lancer le bootstrap
    ~/github/sre-lab-infrastructure/scripts/common/bootstrap_client.sh
    
    # 3. Recharger
    source ~/.bashrc
    ```

=== "Mise à jour NAS"

    ```bash
    # Depuis votre poste principal
    deploy_lab
    ```

## 🛠️ Technologies

*   **Orchestration** : K3s
*   **GitOps** : ArgoCD
*   **Monitoring** : Prometheus, Grafana
*   **OS** : Ubuntu Server 24.04, WSL2
*   **Shell** : Bash, Starship

