#!/bin/bash

echo "🚀 Démarrage de l'initialisation de MariaDB..."

# Charger les secrets
if [ -f /run/secrets/credentials ]; then
    source /run/secrets/credentials
else
    echo "❌ Fichier secrets non trouvé"
    exit 1
fi

# Vérification des variables
if [ -z "$SQL_ROOT_PASSWORD" ] || [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ] || [ -z "$SQL_PASSWORD" ]; then
    echo "❌ Variables d'environnement requises manquantes."
    exit 1
fi

# Vérifier si MariaDB a déjà été initialisé
if [ -d "/var/lib/mysql/${SQL_DATABASE}" ]; then
    echo "✅ Base de données déjà initialisée, démarrage direct..."
    exec mysqld_safe
fi

# Démarrer MariaDB temporairement
service mariadb start

echo "🔗 Connexion à la base de données..."
# Attendre que MariaDB soit prêt
MAX_RETRIES=30
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    if mysqladmin ping -h"localhost" --silent; then
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

echo "✅ MariaDB est prêt. Configuration initiale..."

# Configuration sécurisée (sans mot de passe car première connexion)
mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Création de la base et de l'utilisateur (AVEC mot de passe root maintenant)
mysql -u root -p"${SQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "🎉 Configuration de la base de données terminée avec succès !"

# Arrêt propre
mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown
sleep 2

# Démarrage en avant-plan
echo "🔥 Démarrage de MariaDB en mode production..."
exec mysqld_safe
