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

<a href="wsl/" class="card">
  <span class="card-icon">💻</span>
  <h3>01. Poste de Travail</h3>
  <p>Configuration de l'environnement de développement sur WSL2. Shell, Outils, et Automatisation.</p>
</a>

<a href="ubuntu-server/" class="card">
  <span class="card-icon">🖥️</span>
  <h3>02. Le Serveur</h3>
  <p>Installation et préparation du Lenovo T420. OS, Réseau, et Sécurité.</p>
</a>

<a href="setup-lab/" class="card">
  <span class="card-icon">🚀</span>
  <h3>03. Guide du Lab</h3>
  <p>Déploiement de Kubernetes (K3s), ArgoCD, et de la stack d'observabilité.</p>
</a>

</div>

## ⚡ Démarrage Rapide

Vous avez déjà cloné le repo ? Configurez votre environnement en une commande :

=== "Sur WSL"

    ```bash
    ~/github/sre-lab-infrastructure/scripts/setup_wsl_env.sh
    source ~/.bashrc
    ```

=== "Sur le Serveur"

    ```bash
    ~/github/sre-lab-infrastructure/scripts/setup_server_env.sh
    source ~/.bashrc
    ```

## 🛠️ Technologies

*   **Orchestration** : K3s
*   **GitOps** : ArgoCD
*   **Monitoring** : Prometheus, Grafana
*   **OS** : Ubuntu Server 24.04, WSL2
*   **Shell** : Bash, Starship

