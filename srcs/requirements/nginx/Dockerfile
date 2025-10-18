FROM debian:bullseye

RUN apt-get update && apt-get install nginx -y

RUN apt-get install openssl -y
RUN rm -rf /var/lib/apt/lists/*

# Supprime les fichiers par défaut de NGINX
RUN rm -f /etc/nginx/sites-enabled/default
RUN rm -f /etc/nginx/sites-available/default
RUN rm -f /usr/share/nginx/html/index.html
RUN rm -f /usr/share/nginx/html/index.nginx-debian.html

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/setup_ssl.sh /setup.sh
RUN chmod +x /setup.sh

# Déclare le port 443 comme exposé (HTTPS)
EXPOSE 443

# Utilise le script bash comme point d'entrée
ENTRYPOINT ["bash", "/setup.sh"]
