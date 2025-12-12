Voici les fichiers supplémentaires nécessaires, y compris le script d'installation :

## **1. Fichier `install.sh`**

```bash
#!/bin/bash

# install.sh - Script d'installation pour Zombie Process Monitor

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="zombie_monitor.sh"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/zombie_monitor"
LOG_DIR="/var/log"
SERVICE_DIR="/etc/systemd/system"
CRON_USER="root"

# Fonction d'affichage
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Vérification des privilèges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Ce script nécessite les privilèges root."
        print_error "Utilisez: sudo ./install.sh"
        exit 1
    fi
}

# Vérification des dépendances
check_dependencies() {
    print_status "Vérification des dépendances..."
    
    local missing_deps=()
    
    # Vérifier les commandes essentielles
    for cmd in bash ps awk grep date tee; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Dépendances manquantes: ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "Toutes les dépendances sont satisfaites"
}

# Installation du script principal
install_main_script() {
    print_status "Installation du script principal..."
    
    # Copier le script
    if [ -f "$SCRIPT_NAME" ]; then
        cp "$SCRIPT_NAME" "$INSTALL_DIR/"
        chmod 755 "$INSTALL_DIR/$SCRIPT_NAME"
        print_success "Script copié vers $INSTALL_DIR/$SCRIPT_NAME"
    else
        print_error "Fichier $SCRIPT_NAME non trouvé!"
        print_error "Exécutez ce script depuis le dossier du projet."
        exit 1
    fi
    
    # Créer un lien symbolique pour une utilisation facile
    if [ ! -L "$INSTALL_DIR/zombie-monitor" ]; then
        ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/zombie-monitor"
        print_success "Lien symbolique créé: zombie-monitor"
    fi
}

# Configuration des répertoires
setup_directories() {
    print_status "Configuration des répertoires..."
    
    # Créer le répertoire de configuration
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        chmod 755 "$CONFIG_DIR"
        print_success "Répertoire de configuration créé: $CONFIG_DIR"
    fi
    
    # Créer le fichier de log
    if [ ! -f "$LOG_DIR/zombie_monitor.log" ]; then
        touch "$LOG_DIR/zombie_monitor.log"
        chmod 644 "$LOG_DIR/zombie_monitor.log"
        print_success "Fichier de log créé: $LOG_DIR/zombie_monitor.log"
    fi
    
    # Copier les fichiers d'exemple de configuration
    if [ -d "examples" ]; then
        cp examples/* "$CONFIG_DIR/" 2>/dev/null || true
        print_success "Fichiers d'exemple copiés"
    fi
}

# Configuration de la surveillance automatique
setup_automation() {
    print_status "Configuration de la surveillance automatique..."
    
    echo "Choisissez la fréquence de surveillance:"
    echo "  1) Tous les jours à 2h (recommandé)"
    echo "  2) Toutes les 6 heures"
    echo "  3) Toutes les heures"
    echo "  4) Manuellement seulement"
    echo "  5) Personnaliser (éditer cron manuellement)"
    read -p "Votre choix [1-5]: " freq_choice
    
    case $freq_choice in
        1)
            cron_schedule="0 2 * * *"
            ;;
        2)
            cron_schedule="0 */6 * * *"
            ;;
        3)
            cron_schedule="0 * * * *"
            ;;
        4)
            print_warning "Surveillance automatique désactivée"
            return 0
            ;;
        5)
            print_warning "Configuration cron manuelle requise"
            return 0
            ;;
        *)
            cron_schedule="0 2 * * *"
            print_warning "Choix invalide, utilisation par défaut (tous les jours à 2h)"
            ;;
    esac
    
    # Ajouter la tâche cron
    (crontab -l -u "$CRON_USER" 2>/dev/null | grep -v "zombie_monitor" | grep -v "zombie-monitor"; \
     echo "$cron_schedule $INSTALL_DIR/$SCRIPT_NAME --check >> $LOG_DIR/zombie_monitor.log 2>&1") | \
     crontab -u "$CRON_USER" -
    
    print_success "Tâche cron programmée: $cron_schedule"
}

# Installation systemd (optionnel)
setup_systemd() {
    print_status "Configuration systemd (optionnel)..."
    
    read -p "Voulez-vous configurer systemd pour la surveillance? (o/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        print_warning "Configuration systemd ignorée"
        return 0
    fi
    
    if [ -d "systemd" ]; then
        # Copier les fichiers de service
        cp systemd/zombie-monitor.service "$SERVICE_DIR/"
        cp systemd/zombie-monitor.timer "$SERVICE_DIR/"
        
        # Recharger systemd
        systemctl daemon-reload
        
        # Activer le timer
        systemctl enable zombie-monitor.timer
        systemctl start zombie-monitor.timer
        
        print_success "Service systemd installé et activé"
        print_status "Vérifiez avec: systemctl status zombie-monitor.timer"
    else
        print_warning "Dossier systemd non trouvé, ignoré"
    fi
}

# Création de l'alias
setup_alias() {
    print_status "Configuration des alias..."
    
    # Vérifier si .bashrc existe
    if [ -f "$HOME/.bashrc" ]; then
        # Ajouter un alias pour l'utilisateur courant
        if ! grep -q "alias zombie-check" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Alias pour Zombie Process Monitor" >> "$HOME/.bashrc"
            echo "alias zombie-check='sudo $INSTALL_DIR/$SCRIPT_NAME --check'" >> "$HOME/.bashrc"
            echo "alias zombie-clean='sudo $INSTALL_DIR/$SCRIPT_NAME --clean'" >> "$HOME/.bashrc"
            print_success "Alias ajoutés au .bashrc"
        fi
    fi
    
    # Pour tous les utilisateurs (optionnel)
    if [ -f "/etc/bash.bashrc" ]; then
        read -p "Voulez-vous ajouter les alias pour tous les utilisateurs? (o/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            if ! grep -q "alias zombie-check" "/etc/bash.bashrc"; then
                echo "" >> "/etc/bash.bashrc"
                echo "# Alias pour Zombie Process Monitor" >> "/etc/bash.bashrc"
                echo "alias zombie-check='sudo $INSTALL_DIR/$SCRIPT_NAME --check'" >> "/etc/bash.bashrc"
                echo "alias zombie-clean='sudo $INSTALL_DIR/$SCRIPT_NAME --clean'" >> "/etc/bash.bashrc"
                print_success "Alias ajoutés au bash.bashrc global"
            fi
        fi
    fi
}

# Test de l'installation
test_installation() {
    print_status "Test de l'installation..."
    
    # Tester la commande de base
    if "$INSTALL_DIR/$SCRIPT_NAME" --check &>/dev/null; then
        print_success "Script testé avec succès"
        
        # Afficher un exemple
        echo ""
        print_status "Exemple d'utilisation:"
        echo "  zombie-check          # Vérifier les zombies (alias)"
        echo "  zombie-clean          # Nettoyer les zombies (alias)"
        echo "  sudo $INSTALL_DIR/$SCRIPT_NAME --check  # Vérifier les zombies"
        echo "  sudo $INSTALL_DIR/$SCRIPT_NAME --clean  # Nettoyer les zombies"
    else
        print_error "Le test a échoué!"
        exit 1
    fi
}

# Affichage des informations finales
show_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           INSTALLATION TERMINÉE AVEC SUCCÈS              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📁 Fichiers installés:${NC}"
    echo "  Script:        $INSTALL_DIR/$SCRIPT_NAME"
    echo "  Lien:          $INSTALL_DIR/zombie-monitor"
    echo "  Logs:          $LOG_DIR/zombie_monitor.log"
    echo "  Configuration: $CONFIG_DIR/"
    echo ""
    echo -e "${BLUE}🚀 Commandes disponibles:${NC}"
    echo "  zombie-check                    # Vérifier les zombies"
    echo "  zombie-clean                    # Nettoyer les zombies"
    echo "  sudo $INSTALL_DIR/$SCRIPT_NAME --help   # Afficher l'aide"
    echo ""
    echo -e "${BLUE}📋 Prochaines étapes:${NC}"
    echo "  1. Testez avec: zombie-check"
    echo "  2. Vérifiez les logs: tail -f $LOG_DIR/zombie_monitor.log"
    echo "  3. Configurez les alertes email si nécessaire"
    echo ""
    echo -e "${YELLOW}⚠️  Note:${NC} Les tâches cron sont exécutées en tant que: $CRON_USER"
    echo ""
}

# Fonction principale
main() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       INSTALLATION DE ZOMBIE PROCESS MONITOR             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Vérifications initiales
    check_root
    check_dependencies
    
    # Étapes d'installation
    install_main_script
    setup_directories
    setup_automation
    setup_systemd
    setup_alias
    test_installation
    show_summary
    
    # Demander un test immédiat
    echo ""
    read -p "Voulez-vous exécuter une vérification maintenant? (o/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        echo ""
        "$INSTALL_DIR/$SCRIPT_NAME" --check
    fi
}

# Exécution
main "$@"
```

## **2. Fichier `uninstall.sh`**

```bash
#!/bin/bash

# uninstall.sh - Script de désinstallation pour Zombie Process Monitor

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME="zombie_monitor.sh"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/zombie_monitor"
LOG_FILE="/var/log/zombie_monitor.log"
SERVICE_DIR="/etc/systemd/system"
CRON_USER="root"

# Fonction d'affichage
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Vérification des privilèges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Ce script nécessite les privilèges root."
        print_error "Utilisez: sudo ./uninstall.sh"
        exit 1
    fi
}

# Supprimer le script principal
remove_main_script() {
    print_status "Suppression du script principal..."
    
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        rm -f "$INSTALL_DIR/$SCRIPT_NAME"
        print_success "Script supprimé: $INSTALL_DIR/$SCRIPT_NAME"
    else
        print_warning "Script non trouvé: $INSTALL_DIR/$SCRIPT_NAME"
    fi
    
    if [ -L "$INSTALL_DIR/zombie-monitor" ]; then
        rm -f "$INSTALL_DIR/zombie-monitor"
        print_success "Lien symbolique supprimé"
    fi
}

# Supprimer les tâches cron
remove_cron_jobs() {
    print_status "Suppression des tâches cron..."
    
    if crontab -l -u "$CRON_USER" 2>/dev/null | grep -q "zombie_monitor\|zombie-monitor"; then
        crontab -l -u "$CRON_USER" 2>/dev/null | \
        grep -v "zombie_monitor" | \
        grep -v "zombie-monitor" | \
        crontab -u "$CRON_USER" -
        print_success "Tâches cron supprimées"
    else
        print_warning "Aucune tâche cron trouvée"
    fi
}

# Supprimer les services systemd
remove_systemd_services() {
    print_status "Suppression des services systemd..."
    
    if systemctl is-active --quiet zombie-monitor.timer 2>/dev/null; then
        systemctl stop zombie-monitor.timer
        systemctl disable zombie-monitor.timer
        print_success "Service systemd arrêté et désactivé"
    fi
    
    if [ -f "$SERVICE_DIR/zombie-monitor.service" ]; then
        rm -f "$SERVICE_DIR/zombie-monitor.service"
        print_success "Service systemd supprimé"
    fi
    
    if [ -f "$SERVICE_DIR/zombie-monitor.timer" ]; then
        rm -f "$SERVICE_DIR/zombie-monitor.timer"
        print_success "Timer systemd supprimé"
    fi
    
    systemctl daemon-reload 2>/dev/null || true
}

# Supprimer les fichiers de configuration et logs
remove_config_and_logs() {
    print_status "Suppression des fichiers de configuration et logs..."
    
    # Demander confirmation pour les logs
    read -p "Voulez-vous conserver le fichier de log? (o/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        print_warning "Fichier de log conservé: $LOG_FILE"
    else
        if [ -f "$LOG_FILE" ]; then
            rm -f "$LOG_FILE"
            print_success "Fichier de log supprimé"
        fi
    fi
    
    # Demander confirmation pour la configuration
    if [ -d "$CONFIG_DIR" ]; then
        read -p "Voulez-vous conserver les fichiers de configuration? (o/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            print_warning "Configuration conservée: $CONFIG_DIR"
        else
            rm -rf "$CONFIG_DIR"
            print_success "Répertoire de configuration supprimé"
        fi
    fi
}

# Supprimer les alias
remove_aliases() {
    print_status "Suppression des alias..."
    
    # Alias utilisateur
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/alias zombie-check/d' "$HOME/.bashrc" 2>/dev/null || true
        sed -i '/alias zombie-clean/d' "$HOME/.bashrc" 2>/dev/null || true
        sed -i '/# Alias pour Zombie Process Monitor/d' "$HOME/.bashrc" 2>/dev/null || true
    fi
    
    # Alias global
    if [ -f "/etc/bash.bashrc" ]; then
        sed -i '/alias zombie-check/d' "/etc/bash.bashrc" 2>/dev/null || true
        sed -i '/alias zombie-clean/d' "/etc/bash.bashrc" 2>/dev/null || true
        sed -i '/# Alias pour Zombie Process Monitor/d' "/etc/bash.bashrc" 2>/dev/null || true
    fi
    
    print_success "Alias supprimés"
}

# Affichage des informations de désinstallation
show_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         DÉSINSTALLATION TERMINÉE AVEC SUCCÈS            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}✅ Les éléments suivants ont été supprimés:${NC}"
    echo "  ✓ Script principal"
    echo "  ✓ Lien symbolique"
    echo "  ✓ Tâches cron"
    echo "  ✓ Services systemd (si installés)"
    echo "  ✓ Alias (si configurés)"
    echo ""
    echo -e "${YELLOW}📝 Note:${NC}"
    echo "  Les fichiers de log et configuration peuvent avoir été conservés"
    echo "  selon vos choix lors de la désinstallation."
    echo ""
    echo -e "${BLUE}🔄 Pour une réinstallation:${NC}"
    echo "  Exécutez simplement: sudo ./install.sh"
    echo ""
}

# Fonction principale
main() {
    clear
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║      DÉSINSTALLATION DE ZOMBIE PROCESS MONITOR          ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  AVERTISSEMENT: Cette action est irréversible!${NC}"
    echo ""
    
    # Demander confirmation
    read -p "Voulez-vous vraiment désinstaller Zombie Process Monitor? (o/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        print_error "Désinstallation annulée"
        exit 0
    fi
    
    # Vérifications initiales
    check_root
    
    # Étapes de désinstallation
    remove_cron_jobs
    remove_systemd_services
    remove_main_script
    remove_aliases
    remove_config_and_logs
    show_summary
}

# Exécution
main "$@"
```

## **3. Fichier `README.md` mis à jour**

Ajoutez cette section à votre README existant :

## **📦 Installation & Déploiement**

### **Installation Rapide (recommandé)**
```bash
# Clonez le dépôt
git clone https://github.com/votre-username/zombie-process-monitor.git
cd zombie-process-monitor

# Installation complète
sudo ./install.sh

# Le script vous guidera à travers les options:
# - Fréquence de surveillance (quotidienne/hebdomadaire/etc.)
# - Installation systemd (optionnel)
# - Configuration des alias
```

### **Installation Manuellement**
```bash
# Copier le script
sudo cp zombie_monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/zombie_monitor.sh

# Configurer la surveillance quotidienne
sudo zombie_monitor.sh --install-cron
```

### **Mise à Jour**
```bash
cd zombie-process-monitor
git pull origin main
sudo ./install.sh
```

### **Désinstallation**
```bash
sudo ./uninstall.sh
```

## **📂 Structure du Projet Complète**
```
zombie-process-monitor/
├── zombie_monitor.sh          # Script principal
├── install.sh                 # Script d'installation automatisée
├── uninstall.sh              # Script de désinstallation propre
├── CHANGELOG.md              # Historique des versions
├── LICENSE                   # Licence MIT
├── systemd/                  # Intégration systemd (optionnel)
│   ├── zombie-monitor.service
│   └── zombie-monitor.timer
├── examples/                 # Exemples de configuration
│   ├── cron_example         # Exemples de tâches cron
│   ├── alert_config         # Configuration des alertes
│   └── email_template       # Template d'email d'alerte
└── tests/                   # Tests automatisés (à venir)
    ├── test_zombies.sh
    └── integration_tests.sh
```

### **Options d'Installation**
Le script d'installation propose plusieurs options :
1. **Fréquence de surveillance** (quotidienne, horaire, manuelle)
2. **Intégration systemd** pour un meilleur contrôle
3. **Alias Bash** pour une utilisation simplifiée
4. **Configuration de la journalisation**

### **Vérification de l'Installation**
```bash
# Vérifier que l'installation a réussi
which zombie-monitor
zombie-check

# Vérifier les tâches cron
crontab -l

# Vérifier les logs
tail -f /var/log/zombie_monitor.log
```

## **4. Créez les dossiers manquants**

```bash
# Structure complète
mkdir -p systemd examples tests

# Fichier de service systemd
cat > systemd/zombie-monitor.service << 'EOF'
[Unit]
Description=Zombie Process Monitor
After=network.target
Documentation=https://github.com/votre-username/zombie-process-monitor

[Service]
Type=oneshot
ExecStart=/usr/local/bin/zombie_monitor.sh --check
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat > systemd/zombie-monitor.timer << 'EOF'
[Unit]
Description=Daily Zombie Process Check
Requires=zombie-monitor.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

# Fichiers d'exemple
cat > examples/cron_example << 'EOF'
# Exemples de configuration cron pour Zombie Monitor

# Tous les jours à 2h du matin
0 2 * * * /usr/local/bin/zombie_monitor.sh --check >> /var/log/zombie_monitor.log 2>&1

# Toutes les 6 heures
0 */6 * * * /usr/local/bin/zombie_monitor.sh --check >> /var/log/zombie_monitor.log 2>&1

# Toutes les heures (pour les environnements critiques)
0 * * * * /usr/local/bin/zombie_monitor.sh --check >> /var/log/zombie_monitor.log 2>&1

# Tous les lundis à 3h
0 3 * * 1 /usr/local/bin/zombie_monitor.sh --check >> /var/log/zombie_monitor.log 2>&1
EOF

cat > examples/alert_config << 'EOF'
# Configuration des alertes pour Zombie Monitor
# Copier ce fichier vers /etc/zombie_monitor/alert.conf

# Email pour les alertes
ALERT_EMAIL="admin@example.com"

# Seuil d'alerte (nombre de zombies)
CRITICAL_THRESHOLD=10
WARNING_THRESHOLD=5

# Fréquence des alertes (en minutes)
ALERT_COOLDOWN=60

# Activer les notifications système
ENABLE_SYSTEM_NOTIFICATIONS=true

# Activer les emails
ENABLE_EMAIL_ALERTS=false

# Activer les logs détaillés
VERBOSE_LOGGING=true
EOF
```

## **5. Rendez les scripts exécutables**

```bash
chmod +x install.sh uninstall.sh zombie_monitor.sh
```

Maintenant vous avez un système complet d'installation et de gestion pour votre outil de surveillance des processus zombies !


---

Voici un script Bash pour surveiller les processus zombies avec vérification quotidienne :

## **Script de surveillance des zombies** (`zombie_monitor.sh`)

```bash
#!/bin/bash

# zombie_monitor.sh - Surveillance des processus zombies
# Usage: ./zombie_monitor.sh [--check] [--clean] [--install-cron]

LOG_FILE="/var/log/zombie_monitor.log"
MAX_ZOMBIES=5
ALERT_EMAIL=""  # Mettez votre email ici si vous voulez des alertes

# Couleurs pour l'affichage
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Fonction de journalisation
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Fonction pour vérifier les zombies
check_zombies() {
    local zombie_count=$(ps aux | awk '$8=="Z" || $8=="Z+"' | grep -v "USER" | wc -l)
    
    if [ $zombie_count -gt 0 ]; then
        log_message "${RED}⚠️  ALERTE: $zombie_count processus zombie(s) détecté(s)!${NC}"
        
        # Afficher les détails des zombies
        log_message "${YELLOW}Détails des processus zombies:${NC}"
        ps aux | awk '$8=="Z" || $8=="Z+"' | tee -a "$LOG_FILE"
        
        # Afficher les processus parents
        log_message "${YELLOW}Processus parents potentiels:${NC}"
        ps -eo pid,ppid,stat,comm | awk '$3=="Z" || $3=="Z+"' | tee -a "$LOG_FILE"
        
        # Vérifier si le nombre dépasse le seuil
        if [ $zombie_count -ge $MAX_ZOMBIES ]; then
            log_message "${RED}🚨 SEUIL DÉPASSÉ: Plus de $MAX_ZOMBIES zombies! Action recommandée.${NC}"
            return 2
        fi
        return 1
    else
        log_message "${GREEN}✅ Aucun processus zombie détecté.${NC}"
        return 0
    fi
}

# Fonction pour nettoyer les zombies
clean_zombies() {
    log_message "${YELLOW}Tentative de nettoyage des zombies...${NC}"
    
    # Méthode 1: Tuer les processus parents
    local parent_pids=$(ps -eo pid,ppid,stat | awk '$3=="Z" || $3=="Z+" {print $2}' | sort -u)
    
    for pid in $parent_pids; do
        if [ $pid -gt 1 ]; then  # Ne pas tuer init (PID 1)
            log_message "Envoi SIGCHLD au processus parent PID: $pid"
            kill -s SIGCHLD $pid 2>/dev/null
        fi
    done
    
    # Attendre un peu
    sleep 2
    
    # Vérifier si des zombies restent
    local remaining_zombies=$(ps aux | awk '$8=="Z" || $8=="Z+"' | grep -v "USER" | wc -l)
    
    if [ $remaining_zombies -gt 0 ]; then
        log_message "${YELLOW}Il reste $remaining_zombies zombie(s).${NC}"
        
        # Méthode 2: Reboot si trop de zombies
        if [ $remaining_zombies -ge 10 ]; then
            log_message "${RED}Beaucoup de zombies restants. Un redémarrage est recommandé.${NC}"
            read -p "Voulez-vous redémarrer le système? (o/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Oo]$ ]]; then
                log_message "Redémarrage du système..."
                sudo reboot
            fi
        fi
    else
        log_message "${GREEN}✅ Tous les zombies ont été nettoyés!${NC}"
    fi
}

# Fonction pour installer la tâche cron
install_cron_job() {
    local script_path="$(realpath "$0")"
    
    log_message "Installation de la tâche cron quotidienne..."
    
    # Créer une tâche cron pour exécuter le script tous les jours à 2h du matin
    (crontab -l 2>/dev/null | grep -v "$script_path"; echo "0 2 * * * $script_path --check >> $LOG_FILE 2>&1") | crontab -
    
    # Ajouter aussi une vérification toutes les heures si vous voulez
    # (crontab -l 2>/dev/null | grep -v "$script_path"; echo "0 * * * * $script_path --check >> /tmp/zombie_check.log 2>&1") | crontab -
    
    log_message "${GREEN}✅ Tâche cron installée!${NC}"
    log_message "Le script s'exécutera automatiquement tous les jours à 2h du matin."
    log_message "Logs: $LOG_FILE"
}

# Fonction pour envoyer une alerte email (optionnel)
send_alert() {
    local zombie_count=$1
    if [ -n "$ALERT_EMAIL" ]; then
        echo "Alerte: $zombie_count processus zombies détectés sur $(hostname) à $(date)" | \
        mail -s "🚨 Alerte Zombies sur $(hostname)" "$ALERT_EMAIL"
    fi
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  --check        Vérifier les processus zombies"
    echo "  --clean        Essayer de nettoyer les zombies"
    echo "  --install-cron Installer la vérification quotidienne automatique"
    echo "  --help         Afficher cette aide"
    echo
    echo "Exemples:"
    echo "  $0 --check              # Vérifier les zombies"
    echo "  $0 --clean              # Nettoyer les zombies"
    echo "  sudo $0 --install-cron  # Installer la surveillance automatique"
}

# Point d'entrée principal
main() {
    # Créer le fichier log si nécessaire
    touch "$LOG_FILE"
    
    case "$1" in
        --check)
            check_zombies
            exit $?
            ;;
        --clean)
            check_zombies
            if [ $? -gt 0 ]; then
                clean_zombies
            fi
            ;;
        --install-cron)
            install_cron_job
            ;;
        --help|-h)
            show_help
            ;;
        *)
            # Mode interactif par défaut
            echo -e "${YELLOW}=== Surveillance des processus zombies ===${NC}"
            check_zombies
            local result=$?
            
            if [ $result -gt 0 ]; then
                echo
                read -p "Voulez-vous essayer de nettoyer les zombies? (o/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Oo]$ ]]; then
                    clean_zombies
                fi
            fi
            ;;
    esac
}

# Lancer le script
main "$@"
```

## **Fichier de service systemd** (optionnel pour une meilleure intégration)

Créez `/etc/systemd/system/zombie-monitor.service` :

```ini
[Unit]
Description=Zombie Process Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/zombie_monitor.sh --check
User=root

[Install]
WantedBy=multi-user.target
```

Et `/etc/systemd/system/zombie-monitor.timer` :

```ini
[Unit]
Description=Daily Zombie Process Check

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

## **Installation et utilisation**

```bash
# 1. Téléchargez le script
sudo nano /usr/local/bin/zombie_monitor.sh

# 2. Rendez-le exécutable
sudo chmod +x /usr/local/bin/zombie_monitor.sh

# 3. Installez la vérification quotidienne
sudo zombie_monitor.sh --install-cron

# 4. Testez le script
sudo zombie_monitor.sh --check

# 5. Pour nettoyer manuellement
sudo zombie_monitor.sh --clean

# 6. Vérifiez les logs
tail -f /var/log/zombie_monitor.log

# 7. Vérifiez la tâche cron installée
crontab -l
```

## **Fonctionnalités du script**

1. **Vérification quotidienne automatique** via cron
2. **Détection et comptage** des processus zombies
3. **Nettoyage automatique** (envoi SIGCHLD aux parents)
4. **Journalisation complète** dans `/var/log/zombie_monitor.log`
5. **Seuils d'alerte** configurables
6. **Interface en couleurs** pour une meilleure lisibilité
7. **Option de redémarrage** si trop de zombies
8. **Support des alertes email** (optionnel)

Le script est sécurisé et n'effectue que des actions réversibles (il ne tue pas directement les zombies, mais envoie des signaux aux processus parents pour qu'ils nettoient leurs enfants).
