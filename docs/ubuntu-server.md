# Configuration du Serveur Ubuntu (T420)

Ce document résume la procédure d'installation et de configuration d'Ubuntu Server 24.04 LTS sur un Lenovo ThinkPad T420.

## 1. Préparation du média d'installation

*   **Source** : Télécharger l'ISO [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/server).
*   **Outil** : Utiliser Rufus ou BalenaEtcher pour créer la clé USB bootable.
    *   *Astuce T420* : Si le boot échoue, refaire la clé avec Rufus en schéma de partition **MBR** (pour BIOS/Legacy).

## 2. Configuration du BIOS (T420)

Le T420 étant une machine ancienne, le BIOS peut être capricieux.

1.  **Accès** : Touche `F1` au démarrage.
2.  **Startup > UEFI/Legacy Boot** : Régler sur `Both` ou `UEFI Only` (avec `UEFI First`).
3.  **Boot Order** : Remonter `USB HDD` en premier.
4.  **Ports USB** : Utiliser les ports latéraux ou arrière (éviter le port jaune "Always On").

## 3. Installation de l'OS

Démarrer sur la clé (`F12`) et suivre l'installeur :

*   **Type** : Ubuntu Server (standard, pas minimized).
*   **Réseau** : Ethernet filaire (DHCP).
*   **Stockage** : "Use an entire disk" (Attention, efface tout).
*   **SSH** : **Cocher "Install OpenSSH Server"**.
*   **Snaps optionnels** : **Ne rien cocher** (pas de MicroK8s, pas de Nextcloud). Nous installerons nos propres outils pour maîtriser les ressources.

## 4. Configuration Post-Installation (Depuis le poste client)

Une fois le serveur redémarré, tout se gère depuis votre poste de travail (ex: T14) via SSH.

### Connexion SSH sans mot de passe

```bash
# Remplacer par l'IP réelle du T420
ssh-copy-id -i ~/.ssh/id_rsa.pub nicolab@<IP-DU-T420>
```

### Configuration de l'environnement (Starship + Alias)

Une fois le NAS monté (voir `setup_nas.sh`), vous pouvez configurer l'environnement shell standardisé (Prompt Starship + Alias centralisés) en lançant :

```bash
~/github/sre-lab-infrastructure/scripts/setup_server_env.sh
```

Ce script va :
1.  Installer **Starship**.
2.  Configurer `.bashrc` pour utiliser la configuration centralisée sur le NAS.

### Script d'initialisation système (init-t420.sh)

Pour les outils système de base (avant l'environnement shell), vous pouvez utiliser ce script :

```bash
#!/bin/bash
# Mise à jour
sudo apt update && sudo apt upgrade -y

# Outils de base
sudo apt install -y curl git htop vim neofetch

# Désactivation du Swap (Requis pour K8s)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "Serveur prêt !"
```

## 5. Optimisation "Headless" (Laptop Server)

Pour utiliser le portable comme un serveur (capot fermé, écran éteint, économie d'énergie).

### Ignorer la fermeture du capot

**Méthode 1 (Standard) :**
Éditer `/etc/systemd/logind.conf` :

```ini
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```
Puis : `sudo systemctl restart systemd-logind`

**Méthode 2 (Radicale - Si la méthode 1 échoue) :**
Si le T420 s'obstine à dormir (LED lune allumée), désactivez totalement la capacité de mise en veille du système :

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```
*Pour revenir en arrière un jour : remplacer `mask` par `unmask`.*

### Éteindre l'écran (Console Blanking)

Éditer `/etc/default/grub` et modifier la ligne :

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash consoleblank=60"
```
Puis : `sudo update-grub` et redémarrer.

### Désactiver les radios (Wi-Fi / Bluetooth)

Pour économiser de l'énergie et éviter les interférences, il est recommandé de couper les radios inutilisées sur un serveur connecté en Ethernet.

1.  **Installer rfkill** (si absent) :
    ```bash
    sudo apt update && sudo apt install -y rfkill
    ```

2.  **Couper le Wi-Fi et le Bluetooth** :
    ```bash
    sudo rfkill block wifi
    sudo rfkill block bluetooth
    ```

3.  **Vérifier l'état** :
    ```bash
    rfkill list
    ```
    *(Vous devez voir `Soft blocked: yes` pour Wireless LAN et Bluetooth)*.

## 6. Montage NAS Sécurisé (Pour Alias & Data)

Pour accéder à des fichiers partagés (ex: scripts d'alias centralisés) de manière sécurisée.

### Installation des outils
```bash
sudo apt-get update && sudo apt-get install -y cifs-utils
```

### Sécurisation des identifiants
Ne jamais mettre de mot de passe en clair dans `/etc/fstab`. Utilisez un fichier de credentials protégé.

> **Bonne pratique** : Créez un utilisateur dédié sur votre NAS (ex: `svc_linux`) avec des droits limités uniquement au dossier partagé `work` (lecture seule ou lecture/écriture selon besoin), plutôt que d'utiliser votre compte administrateur principal.

1.  **Créer le fichier** :
    ```bash
    nano ~/.smbcredentials
    ```
2.  **Ajouter le contenu** :
    ```ini
    username=svc_linux
    password=votre_mot_de_passe_dedie
    domain=WORKGROUP
    ```
3.  **Protéger le fichier** (lecture seule pour vous uniquement) :
    ```bash
    chmod 600 ~/.smbcredentials
    ```

### Configuration du montage (fstab)

1.  **Créer le point de montage** :
    ```bash
    sudo mkdir -p /mnt/nas
    ```

2.  **Éditer fstab** :
    ```bash
    sudo nano /etc/fstab
    ```
    Ajouter la ligne suivante (remplacez l'IP et le chemin) :
    ```text
    //192.168.1.X/work /mnt/nas cifs credentials=/home/votre_user/.smbcredentials,iocharset=utf8,vers=3.0,noperm 0 0
    ```

3.  **Tester** :
    ```bash
    sudo mount -a
    ls /mnt/nas
    ```

### Chargement des Alias
Ajoutez le même bloc de code dans votre `.bashrc` que pour WSL (voir section WSL) pour charger `alias.sh`.

## 7. Configuration Wake-on-LAN (Requis)

Pour que les scripts de démarrage (`start_lab.sh`) fonctionnent, le Wake-on-LAN (WoL) doit être correctement configuré sur le serveur.

⚠️ **Important** : Le Wake-on-LAN (WoL) nécessite impérativement une connexion **Ethernet filaire**. Le Wi-Fi du T420 ne supporte pas le réveil depuis l'extinction complète.

### 1. Configuration Réseau (Ethernet + Wi-Fi)
Si vous avez installé Ubuntu en Wi-Fi, l'interface Ethernet est peut-être inactive. Il faut la configurer via Netplan pour qu'elle obtienne une IP (nécessaire pour le WoL).

Éditer le fichier de config (ex: `/etc/netplan/50-cloud-init.yaml`) :
```yaml
network:
    version: 2
    ethernets:
        enp0s25:
            dhcp4: true
            optional: true
    wifis:
        wlp3s0:
            # ... votre config wifi existante ...
```
Puis appliquer : `sudo netplan apply`.

### 2. Configuration du BIOS (T420)
*   Redémarrer et appuyer sur `F1`.
*   Aller dans **Config > Network > Wake On LAN**.
*   Régler sur **AC and Battery** (ou AC Only).
*   Sauvegarder (`F10`).

### 3. Configuration Ubuntu (Persistante)
Par défaut, Ubuntu peut désactiver le WoL au prochain redémarrage. Il faut le forcer.

*   **Vérifier l'état actuel** :
    ```bash
    sudo ethtool enp0s25 | grep Wake-on
    # Doit afficher : Wake-on: g
    ```

*   **Activer et rendre persistant** :
    Créer un service systemd : `sudo nano /etc/systemd/system/wol.service`

    ```ini
    [Unit]
    Description=Enable Wake-on-LAN
    After=network.target

    [Service]
    Type=oneshot
    ExecStart=/sbin/ethtool -s enp0s25 wol g

    [Install]
    WantedBy=multi-user.target
    ```

*   **Activer le service** :
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable wol.service
    sudo systemctl start wol.service
    ```

## 8. Installation de Kubernetes (K3s)

Installation en une commande (plus léger que MicroK8s) :

```bash
curl -sfL https://get.k3s.io | sh -
```

Vérification : `sudo kubectl get nodes`
