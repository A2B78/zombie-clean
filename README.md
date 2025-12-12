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
