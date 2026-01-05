# Guide de Configuration du Lab SRE

Ce guide détaille les étapes pour transformer un matériel standard en une plateforme d'apprentissage SRE complète.

## Étape 1 : Le Socle Infrastructure (Bare Metal)

La première étape consiste à préparer la machine physique qui hébergera nos services.

*   **OS** : Ubuntu Server 24.04 LTS.
*   **Machine** : Lenovo ThinkPad T420.
*   **Configuration** : Headless (sans écran), accès SSH uniquement.

👉 [Voir le guide détaillé d'installation du serveur](ubuntu-server.md)

## Étape 2 : L'Orchestrateur (Kubernetes)

Nous utilisons **K3s**, une distribution Kubernetes légère certifiée, idéale pour le Edge et les labs.

### Installation de K3s

Nous installons K3s en mode permissif pour le fichier de configuration (`644`), ce qui permet à l'utilisateur standard de lire la configuration sans être root.

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -
```

Ensuite, configurez l'accès pour l'utilisateur courant via un lien symbolique (pour bénéficier automatiquement des mises à jour de certificats) :

```bash
mkdir -p ~/.kube
ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

Vérification :
```bash
kubectl get nodes
```

## Étape 3 : GitOps avec ArgoCD

Pour pratiquer le SRE moderne, nous ne déployons rien manuellement. Nous utilisons **ArgoCD**.

1.  **Installer ArgoCD** dans le cluster K3s.
2.  **Connecter un repo Git** contenant les manifestes Kubernetes.
3.  **Sync** : ArgoCD déploie automatiquement les changements poussés sur Git.

## Étape 4 : Observabilité (Monitoring & Logging)

Un SRE doit voir ce qui se passe.

*   **Prometheus** : Collecte des métriques.
*   **Grafana** : Visualisation (Dashboards).
*   **Loki** : Agrégation des logs.

## Étape 5 : Automatisation (Ansible/Terraform)

*   Utiliser **Ansible** pour la configuration de l'OS (post-installation).
*   Utiliser **Terraform** si nous étendons le lab vers le Cloud (AWS/GCP) ou pour gérer des ressources Proxmox.
