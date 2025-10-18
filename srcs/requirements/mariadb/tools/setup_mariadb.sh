cat > ~/inception/srcs/requirements/mariadb/tools/setup_mariadb.sh << 'EOF'
#!/bin/bash

echo "🚀 Démarrage de l'initialisation de MariaDB..."

# Les variables du .env sont automatiquement injectées par Docker
if [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ]; then
    echo "❌ Variables .env manquantes"
    echo "SQL_DATABASE=${SQL_DATABASE:-MANQUANT}"
    echo "SQL_USER=${SQL_USER:-MANQUANT}"
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
if [ -z "$SQL_ROOT_PASSWORD" ] || [ -z "$SQL_PASSWORD" ]; then
    echo "❌ Variables sensibles manquantes"
    echo "SQL_ROOT_PASSWORD=${SQL_ROOT_PASSWORD:-MANQUANT}"
    echo "SQL_PASSWORD=${SQL_PASSWORD:-MANQUANT}"
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

# Configuration sécurisée (première connexion sans mot de passe)
mysql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Création de la base et de l'utilisateur (avec mot de passe root)
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
EOF

chmod +x ~/inception/srcs/requirements/mariadb/tools/setup_mariadb.sh
