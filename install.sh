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
