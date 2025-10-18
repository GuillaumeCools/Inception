#!/bin/bash

echo "🚀 Démarrage de l'initialisation de MariaDB..."

# Charger les secrets
if [ -f /run/secrets/credentials ]; then
    source /run/secrets/credentials
else
    echo "❌ Fichier secrets non trouvé"
    exit 1
fi

# S'assure que les variables requises ne soient pas vides
if [ -z "$SQL_ROOT_PASSWORD" ] || [ -z "$SQL_DATABASE" ] || [ -z "$SQL_USER" ] || [ -z "$SQL_PASSWORD" ]; then
    echo "❌ Variables d'environnement requises manquantes."
    exit 1
fi

# Lancer le service MariaDB
service mariadb start

echo "🔗 Connexion à la base de données..."
# Attendre que MariaDB soit prêt à accepter des connexions
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

echo "✅ MariaDB est prêt. Création de la base de données et des utilisateurs..."

# Définir le mot de passe root
mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Utiliser le mot de passe root pour la configuration suivante
mysql -u root -p"${SQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "🎉 Configuration de la base de données terminée avec succès !"

# Arrêt de MariaDB pour un redémarrage en mode production
echo "🔥 Démarrage de MariaDB en avant-plan..."
mysqladmin -u root -p"${SQL_ROOT_PASSWORD}" shutdown

sleep 2

# Démarrer MariaDB en avant-plan
exec mysqld_safe
