#!/bin/bash

echo "🚀 Démarrage de l'initialisation de MariaDB..."

if [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ]; then
    echo "❌ Variables .env manquantes"
    exit 1
fi

echo "✅ Variables .env chargées"

if [ -f /run/secrets/credentials ]; then
    source /run/secrets/credentials
    echo "✅ Secrets chargés"
else
    echo "❌ Fichier secrets non trouvé"
    exit 1
fi

if [ -z "$SQL_ROOT_PASSWORD" ] || [ -z "$SQL_PASSWORD" ]; then
    echo "❌ Variables sensibles manquantes"
    exit 1
fi

# Vérifier si déjà initialisé
if [ -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    echo "✅ Base de données déjà initialisée"
    exec mysqld_safe
fi

service mariadb start

echo "🔗 Attente de MariaDB..."
MAX_RETRIES=30
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    if mysqladmin ping -h"localhost" --silent 2>/dev/null; then
        echo "✅ MariaDB prêt !"
        break
    fi
    sleep 2
    COUNT=$((COUNT + 1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Échec de la connexion"
    exit 1
fi

echo "⚙️ Configuration de MariaDB..."

# Configuration root
mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Création base et utilisateur
mysql -u root -p"${SQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "✅ Configuration terminée !"

mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
sleep 2

echo "🔥 Démarrage de MariaDB..."
exec mysqld_safe
