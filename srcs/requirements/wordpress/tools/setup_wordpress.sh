#!/bin/bash

echo "🚀 Lancement de l'installation de WordPress..."

# Les variables du .env sont automatiquement injectées par Docker
# On vérifie qu'elles sont bien présentes
if [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Variables .env manquantes"
    echo "SQL_DATABASE=${SQL_DATABASE:-MANQUANT}"
    echo "SQL_USER=${SQL_USER:-MANQUANT}"
    echo "DOMAIN_NAME=${DOMAIN_NAME:-MANQUANT}"
    exit 1
fi

echo "✅ Variables .env chargées"

# Charger les secrets (variables sensibles)
if [ -f /run/secrets/credentials ]; then
    source /run/secrets/credentials
    echo "✅ Secrets chargés"
else
    echo "❌ Fichier secrets non trouvé"
    exit 1
fi

# Vérifier que TOUTES les variables sensibles sont présentes
if [ -z "$SQL_PASSWORD" ] || \
   [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || \
   [ -z "$WP_ADMIN_EMAIL" ] || [ -z "$WP_USER" ] || \
   [ -z "$WP_USER_EMAIL" ] || [ -z "$WP_USER_PASSWORD" ]; then
    echo "❌ Variables sensibles manquantes dans secrets"
    echo "SQL_PASSWORD=${SQL_PASSWORD:-MANQUANT}"
    echo "WP_ADMIN_USER=${WP_ADMIN_USER:-MANQUANT}"
    echo "WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD:-MANQUANT}"
    echo "WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL:-MANQUANT}"
    echo "WP_USER=${WP_USER:-MANQUANT}"
    echo "WP_USER_EMAIL=${WP_USER_EMAIL:-MANQUANT}"
    echo "WP_USER_PASSWORD=${WP_USER_PASSWORD:-MANQUANT}"
    exit 1
fi

# Attente de MariaDB
echo "🔗 Connexion à la base de données..."
MAX_RETRIES=30
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    if mysqladmin ping -h"mariadb" -u"$SQL_USER" -p"$SQL_PASSWORD" --silent; then
        echo "✅ Connexion à la base de données établie !"
        break
    fi
    echo "🔄 En attente que MariaDB soit prêt... Tentative $((COUNT + 1))/$MAX_RETRIES"
    sleep 2
    COUNT=$((COUNT + 1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Échec de la connexion à la base de données après $MAX_RETRIES tentatives."
    exit 1
fi

# Vérifier si WordPress est déjà installé
if ! wp core is-installed --allow-root --path="/var/www/html/" 2>/dev/null; then
    echo "📥 Téléchargement de WordPress..."
    wp core download --version=6.0 --locale=fr_FR --allow-root --path="/var/www/html/"

    echo "⚙️ Création du fichier wp-config.php..."
    wp config create --allow-root \
        --dbname="${SQL_DATABASE}" \
        --dbuser="${SQL_USER}" \
        --dbpass="${SQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --path="/var/www/html/"

    echo "🛠️ Installation de WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception 42" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --path="/var/www/html/"

    echo "👤 Création de l'utilisateur ${WP_USER}..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root \
        --path="/var/www/html/"
    
    echo "✅ WordPress installé avec succès !"
else
    echo "✅ WordPress est déjà installé."
fi

# Création du dossier PHP-FPM
mkdir -p /run/php

# Permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Nettoyage
rm -f /var/www/html/index.nginx-debian.html

# Lancement de PHP-FPM
echo "🔥 Démarrage de PHP-FPM..."
exec php-fpm7.4 -F
EOF

chmod +x ~/inception/srcs/requirements/wordpress/tools/setup_wordpress.sh
