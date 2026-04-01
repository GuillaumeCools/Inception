# Inception

## 📋 Description

Projet d'infrastructure système qui consiste à créer une infrastructure complète avec Docker et Docker Compose. Ce projet met en place un serveur web NGINX avec TLS, WordPress avec PHP-FPM, et une base de données MariaDB, le tout orchestré via Docker Compose.

## 🏗️ Architecture

L'infrastructure est composée de 3 services Docker :

- **NGINX** : Serveur web avec SSL/TLS (port 443)
- **WordPress** : CMS avec PHP-FPM
- **MariaDB** : Base de données SQL

Tous les services communiquent via un réseau Docker personnalisé (`inception`) et utilisent des volumes persistants pour stocker les données.

## 📁 Structure du projet

```
inception/
├── Makefile                    # Commandes de gestion du projet
├── secrets/                    # Fichiers de secrets (credentials)
└── srcs/
    ├── .env                    # Variables d'environnement
    ├── docker-compose.yml      # Configuration des services
    └── requirements/
        ├── mariadb/           # Configuration MariaDB
        ├── nginx/             # Configuration NGINX
        ├── wordpress/         # Configuration WordPress
        └── tools/             # Scripts et outils
```

## ⚙️ Prérequis

- Docker
- Docker Compose
- Make

## 🚀 Installation et utilisation

### Configuration initiale

1. Créer le fichier `.env` dans le dossier `srcs/` avec les variables nécessaires
2. Créer le fichier `secrets/credentials.txt` avec les credentials

### Commandes disponibles

```bash
# Créer les dossiers et démarrer tous les services
make

# Démarrer les conteneurs
make up

# Arrêter les conteneurs
make down

# Voir les logs en temps réel
make logs

# Afficher le statut des conteneurs
make status

# Redémarrer les conteneurs
make restart

# Nettoyage (conteneurs + volumes)
make clean

# Nettoyage complet (conteneurs + images + données)
make fclean

# Reconstruire tout depuis zéro
make re
```

## 🔐 Sécurité

- Connexions HTTPS uniquement (TLS)
- Secrets Docker pour les credentials sensibles
- Pas de mots de passe en clair dans les fichiers de configuration
- Volumes avec permissions appropriées

## 📊 Volumes persistants

Les données sont stockées dans des volumes Docker persistants :
- `mariadb_data` : Données de la base de données
- `wordpress_data` : Fichiers WordPress

Par défaut, les volumes sont montés dans `/home/gcools/data/`

## 🌐 Accès

Une fois les services démarrés, le site est accessible via :
- **HTTPS** : `https://localhost:443` ou selon le domaine configuré

## 🔄 Health Checks

Chaque service dispose d'un health check :
- **MariaDB** : Vérifie la disponibilité du serveur MySQL
- **WordPress** : Vérifie la présence des fichiers WordPress
- Les dépendances entre services sont gérées automatiquement

## 📝 Notes

- Les conteneurs redémarrent automatiquement en cas d'erreur (`restart: unless-stopped`)
- Le réseau `inception` isole les services du réseau hôte
- Les volumes sont en bind mount pour faciliter l'accès aux données

## 🛠️ Développement

Pour modifier la configuration :
1. Éditer les fichiers dans `srcs/requirements/[service]/`
2. Reconstruire avec `make re` pour appliquer les changements

---

Projet réalisé dans le cadre du cursus 42
