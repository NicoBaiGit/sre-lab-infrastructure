# Configuration de Vault et External Secrets

Ce guide détaille les étapes manuelles nécessaires pour initialiser Vault et le configurer pour fonctionner avec External Secrets Operator dans le cluster Kubernetes.

## 1. Initialisation de Vault

Une fois l'application Vault déployée par ArgoCD, le pod sera en état "Running" mais non prêt car il est scellé (sealed).

### Initialiser le coffre
Exécuter la commande suivante pour générer les clés de déchiffrement (Unseal Keys) et le Token Root.
**⚠️ IMPORTANT : Sauvegardez ces informations précieusement (ex: gestionnaire de mots de passe).**

```bash
kubectl exec -ti vault-0 -n security -- vault operator init
```

### Déverrouiller (Unseal) Vault
Vault a besoin de 3 clés (par défaut) pour être déverrouillé. Répétez la commande suivante 3 fois avec 3 clés différentes obtenues à l'étape précédente.

```bash
kubectl exec -ti vault-0 -n security -- vault operator unseal <UNSEAL_KEY_1>
kubectl exec -ti vault-0 -n security -- vault operator unseal <UNSEAL_KEY_2>
kubectl exec -ti vault-0 -n security -- vault operator unseal <UNSEAL_KEY_3>
```

## 2. Configuration de l'Intégration Kubernetes

Une fois Vault déverrouillé, il faut configurer l'authentification pour que les pods Kubernetes (via External Secrets) puissent lire les secrets.

Connectez-vous au pod Vault :
```bash
kubectl exec -ti vault-0 -n security -- sh
```

Dans le shell du pod, exécutez les commandes suivantes :

### Connexion Admin
```bash
# Utilisez le Root Token obtenu lors de l'initialisation
export VAULT_TOKEN=<ROOT_TOKEN>
```

### Activer le moteur de secrets KV v2
```bash
vault secrets enable -path=secret kv-v2
```

### Créer le secret pour Grafana
C'est ici que l'on définit le mot de passe admin de Grafana.
```bash
vault kv put secret/grafana password="MonSuperMotDePasseAdmin"
```

### Activer l'authentification Kubernetes
```bash
vault auth enable kubernetes

vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

### Créer la politique de lecture (Policy)
Cette politique autorise la lecture des secrets dans le chemin `secret/data/*`.

```bash
vault policy write external-secrets - <<EOF
path "secret/data/*" {
  capabilities = ["read"]
}
EOF
```

### Créer le rôle Kubernetes
Ce rôle lie le ServiceAccount `external-secrets` (dans le namespace `security`) à la politique créée ci-dessus.

```bash
vault write auth/kubernetes/role/external-secrets \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=security \
    policies=external-secrets \
    ttl=24h
```

## 3. Vérification

Une fois ces étapes terminées :
1. L'opérateur External Secrets va s'authentifier auprès de Vault.
2. Il va lire le secret `secret/grafana`.
3. Il va créer un secret Kubernetes natif nommé `grafana-admin` dans le namespace `monitoring`.
4. Grafana utilisera ce secret pour définir le mot de passe de l'utilisateur `admin`.

Vous pouvez vérifier la création du secret avec :
```bash
kubectl get secret grafana-admin -n monitoring
```
