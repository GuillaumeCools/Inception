#!/bin/bash

echo "🚀 Lancement de l'installation de WordPress..."

# Vérifier les variables .env
if [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Variables .env manquantes"
    exit 1
fi
echo "✅ Variables .env chargées"

# Charger les secrets
if [ -f /run/secrets/credentials ]; then
    source /run/secrets/credentials
    echo "✅ Secrets chargés"
else
    echo "❌ Fichier secrets non trouvé"
    exit 1
fi

# Vérifier les variables sensibles
if [ -z "$SQL_PASSWORD" ] || [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || \
   [ -z "$WP_ADMIN_EMAIL" ] || [ -z "$WP_USER" ] || [ -z "$WP_USER_EMAIL" ] || \
   [ -z "$WP_USER_PASSWORD" ]; then
    echo "❌ Variables sensibles manquantes"
    exit 1
fi

# Attente de MariaDB
echo "🔗 Connexion à la base de données..."
MAX_RETRIES=30
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    if mysqladmin ping -h"mariadb" -u"$SQL_USER" -p"$SQL_PASSWORD" --silent 2>/dev/null; then
        echo "✅ Connexion établie !"
        break
    fi
    echo "🔄 Tentative $((COUNT + 1))/$MAX_RETRIES"
    sleep 2
    COUNT=$((COUNT + 1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Échec de la connexion à MariaDB"
    exit 1
fi

cd /var/www/html

# Vérifier si WordPress est installé
if wp core is-installed --allow-root 2>/dev/null; then
    echo "✅ WordPress déjà installé"
else
    # Télécharger WordPress si pas déjà fait
    if [ ! -f "wp-settings.php" ]; then
        echo "📥 Téléchargement de WordPress..."
        wp core download --version=6.0 --locale=fr_FR --allow-root
    else
        echo "📦 Fichiers WordPress déjà présents"
    fi

    # Créer wp-config.php si n'existe pas
    if [ ! -f "wp-config.php" ]; then
        echo "⚙️ Création de wp-config.php..."
        wp config create --allow-root \
            --dbname="${SQL_DATABASE}" \
            --dbuser="${SQL_USER}" \
            --dbpass="${SQL_PASSWORD}" \
            --dbhost="mariadb:3306"
    fi

    # Installer WordPress
    echo "🛠️ Installation de WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception 42" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    # Créer le 2ème utilisateur
    echo "👤 Création de l'utilisateur ${WP_USER}..."
    if ! wp user get "${WP_USER}" --allow-root 2>/dev/null; then
        wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --role=author \
            --allow-root
    fi
    
    echo "✅ WordPress installé avec succès !"
fi

# Permissions
mkdir -p /run/php
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
rm -f /var/www/html/index.nginx-debian.html

# Lancement de PHP-FPM
echo "🔥 Démarrage de PHP-FPM..."
exec php-fpm7.4 -F
