# --- SRE Lab Aliases ---
# Ce fichier est centralisé sur Git et distribué via le NAS.

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# --- Git ---
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# --- Kubernetes (k3s/kubectl) ---
alias k='kubectl'
alias kcc='kubectl config current-context'
alias kg='kubectl get'
alias kga='kubectl get all --all-namespaces'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias ksgp='kubectl get pods -n kube-system'
alias kuc='kubectl config use-context'
alias kgc='kubectl config get-contexts'
alias kd='kubectl describe'
alias kaf='kubectl apply -f'
alias krm='kubectl delete'
alias kl='kubectl logs'
alias kpf='kubectl port-forward'
alias kex='kubectl exec -it'

# --- Editor ---
alias nano="vim"

# --- SRE Lab Utils ---
alias bye='/mnt/nas/stop_lab.sh; exit'
alias start_lab='/mnt/nas/start_lab.sh'
alias deploy_env='/mnt/nas/deploy_to_nas.sh'

# --- System ---
alias update='sudo apt update && sudo apt upgrade -y'cd 

# --- Deploy ---
alias deploy-lab='/mnt/nas/deploy_to_nas.sh'

# --- SSH Agent (Keychain) ---
# Charge automatiquement les clés SSH au démarrage du shell (demande le mot de passe une seule fois par reboot)
if command -v keychain &> /dev/null; then
    # Détection automatique des clés privées (contiennent "PRIVATE KEY")
    SSH_KEYS=$(grep -l "PRIVATE KEY" ~/.ssh/* 2>/dev/null | grep -v ".pub$")
    
    if [ -n "$SSH_KEYS" ]; then
        eval $(keychain --eval --agents ssh --quick --quiet $SSH_KEYS)
    else
        eval $(keychain --eval --agents ssh --quick --quiet)
    fi
fi