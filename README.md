# **Zombie Process Monitor - Surveillance de Processus Zombies**

![Bash](https://img.shields.io/badge/Bash-Script-blue.svg)
![Linux](https://img.shields.io/badge/Platform-Linux%2FUnix-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Status](https://img.shields.io/badge/Status-Stable-brightgreen.svg)

Un script Bash intelligent pour détecter, surveiller et nettoyer les processus zombies sur les systèmes Linux. Parfait pour les administrateurs système et les développeurs souhaitant maintenir la stabilité de leurs serveurs.

## 🧟 **Le Problème des Zombies**

Les processus zombies sont des processus qui ont terminé leur exécution mais dont l'entrée reste dans la table des processus parce que le processus parent n'a pas lu leur statut de sortie. Bien qu'ils ne consomment pas de ressources CPU ou mémoire, un grand nombre de zombies peut indiquer des problèmes logiciels et éventuellement bloquer de nouveaux processus.

## ✨ **Fonctionnalités Principales**

### 🔍 **Détection Avancée**
- **Scan automatique** des processus zombies
- **Comptage précis** avec seuils configurables
- **Identification** des processus parents responsables
- **Journalisation détaillée** avec horodatage

### 🛠️ **Nettoyage Intelligent**
- Tentative de nettoyage via **SIGCHLD** aux parents
- **Redémarrage sécurisé** recommandé si nécessaire
- **Actions réversibles** (pas de `kill -9` agressif)
- **Multiples méthodes** de récupération

### ⚙️ **Automatisation**
- **Installation en un clic** de la surveillance quotidienne
- **Intégration Cron** pour vérifications automatiques
- **Notifications** configurables (email, logs système)
- **Rapports détaillés** dans `/var/log/zombie_monitor.log`

### 🎯 **Interface Utilisateur**
- **Sortie en couleurs** pour une meilleure lisibilité
- **Mode interactif** et **mode silencieux**
- **Options CLI** complètes
- **Messages d'alerte** clairs et actionnables

## 🚀 **Installation Rapide**

```bash
# Téléchargement et installation
git clone https://github.com/A2B78/zombie-clean.git
cd zombie-clean
sudo ./install.sh

# Ou installation manuelle
sudo cp zombie_monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/zombie_monitor.sh
sudo zombie_monitor.sh --install-cron
```

## 📖 **Utilisation**

### Vérification simple
```bash
sudo zombie_monitor.sh --check
```

### Nettoyage automatique
```bash
sudo zombie_monitor.sh --clean
```

### Installation de la surveillance automatique
```bash
sudo zombie_monitor.sh --install-cron
```

### Mode interactif
```bash
sudo zombie_monitor.sh
```

## ⚙️ **Configuration**

Personnalisez les paramètres dans le script :
```bash
LOG_FILE="/var/log/zombie_monitor.log"  # Fichier de log
MAX_ZOMBIES=5                            # Seuil d'alerte
ALERT_EMAIL=""                           # Email pour notifications
CHECK_INTERVAL="daily"                   # daily, hourly, weekly
```

## 🕐 **Planification Automatique**

Le script peut être configuré pour s'exécuter automatiquement :

### Via Cron (recommandé)
```bash
# Tous les jours à 2h du matin
0 2 * * * /usr/local/bin/zombie_monitor.sh --check

# Toutes les heures
0 * * * * /usr/local/bin/zombie_monitor.sh --check
```

### Via Systemd Timer (optionnel)
```bash
sudo systemctl enable zombie-monitor.timer
sudo systemctl start zombie-monitor.timer
```

## 📊 **Exemple de Sortie**

```
[2024-01-15 14:30:00] ⚠️  ALERTE: 8 processus zombie(s) détecté(s)!
[2024-01-15 14:30:00] Détails des processus zombies:
root      1234  0.0  0.0      0     0 ?        Z    Jan10   0:00 [sh]
[2024-01-15 14:30:00] 🚨 SEUIL DÉPASSÉ: Plus de 5 zombies! Action recommandée.
```

## 🛡️ **Pourquoi Utiliser Ce Script?**

| Avantage | Description |
|----------|-------------|
| **Prévention** | Détecte les problèmes avant qu'ils n'affectent le système |
| **Automatisation** | Plus besoin de vérifications manuelles |
| **Journalisation** | Historique complet pour le débogage |
| **Sécurité** | Actions non-destructives et réversibles |
| **Personnalisable** | Adaptable à différents environnements |

## 📁 **Structure des Fichiers**

```
zombie-clean/
├── zombie_monitor.sh          # Script principal
├── install.sh                 # Script d'installation
├── uninstall.sh              # Script de désinstallation
├── systemd/                  # Fichiers systemd (optionnel)
│   ├── zombie-monitor.service
│   └── zombie-monitor.timer
├── README.md                 # Ce fichier
└── LICENSE                   # Licence MIT
```

## 🔧 **Compatibilité**

- ✅ **Ubuntu** 16.04+
- ✅ **Debian** 9+
- ✅ **CentOS** 7+
- ✅ **RHEL** 7+
- ✅ **Fedora** 30+
- ✅ Toute distribution avec Bash 4.0+

## 🤝 **Contribuer**

Les contributions sont les bienvenues ! Voici comment aider :

1. **Fork** le projet
2. Créer une **branche** (`git checkout -b feature/AmazingFeature`)
3. **Commit** vos changements (`git commit -m 'Add AmazingFeature'`)
4. **Push** vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une **Pull Request**

## 📝 **Journal des Changements**

Consultez [CHANGELOG.md](CHANGELOG.md) pour l'historique des modifications.

## ⚠️ **Limitations**

- Nécessite les **privilèges root** pour certaines opérations
- Ne peut pas forcer la suppression des zombies sans redémarrage
- Dépend de `ps`, `awk`, `grep` (présents sur tous les systèmes Linux)

## 📚 **En Savoir Plus**

- [Linux Process States](https://man7.org/linux/man-pages/man5/proc.5.html)
- [Zombie Processes Explained](https://en.wikipedia.org/wiki/Zombie_process)
- [Linux Signals](https://man7.org/linux/man-pages/man7/signal.7.html)

## 📄 **Licence**

Distribué sous licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

## 👨‍💻 **Auteur**

**Votre Nom**
- GitHub: [@votre-username](https://github.com/votre-username)
- Site Web: votre-site.com

## ⭐ **Support**

Si ce projet vous a été utile, pensez à :
1. **Donner une étoile** ⭐ au dépôt
2. **Partager** avec vos collègues
3. **Soumettre** des issues ou feature requests

---

**💡 Conseil Pro:** Combinez ce script avec un outil de monitoring comme Nagios ou Zabbix pour une surveillance complète de votre infrastructure !

**🚀 Gardez vos systèmes propres et sans zombies !**
