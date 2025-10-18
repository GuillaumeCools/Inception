FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y wget \
		php7.4-fpm php7.4-mysql \
    mariadb-client && \
    rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

# Crée le dossier racine pour WordPress
RUN mkdir -p /var/www/html

# Copie le script d’installation de WordPress
COPY tools/setup_wordpress.sh /setup.sh

# Rend le script exécutable
RUN chmod +x /setup.sh

# Déclare le port 9000 utilisé par PHP-FPM
EXPOSE 9000

# Définit le répertoire de travail par défaut.
# Important pour que notre script install wordpress au bon endroit
WORKDIR /var/www/html

# Lance l’installation automatique à l’exécution du container
ENTRYPOINT ["bash", "/setup.sh"]