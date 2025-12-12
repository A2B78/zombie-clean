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
