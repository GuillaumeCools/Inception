# Variables
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /Users/guillaumecools/data

# Couleurs pour les messages
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Règle par défaut
all: setup up

# Créer les dossiers de données nécessaires
setup:
	@echo "$(YELLOW)📁 Création des dossiers de données...$(NC)"
	@mkdir -p $(DATA_PATH)/mysql
	@mkdir -p $(DATA_PATH)/wordpress
	@echo "$(GREEN)✅ Dossiers créés avec succès$(NC)"

# Lancer les conteneurs
up:
	@echo "$(YELLOW)🚀 Démarrage des conteneurs...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d --build
	@echo "$(GREEN)✅ Conteneurs démarrés$(NC)"

# Arrêter les conteneurs
down:
	@echo "$(YELLOW)🛑 Arrêt des conteneurs...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✅ Conteneurs arrêtés$(NC)"

# Arrêter et supprimer les conteneurs, réseaux, volumes
clean: down
	@echo "$(YELLOW)🧹 Nettoyage des conteneurs, réseaux et volumes...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down -v
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

# Nettoyage complet (conteneurs + images + données)
fclean: clean
	@echo "$(RED)🔥 Suppression complète (images + données)...$(NC)"
	@docker system prune -af
	@sudo rm -rf $(DATA_PATH)/mysql/*
	@sudo rm -rf $(DATA_PATH)/wordpress/*
	@echo "$(GREEN)✅ Suppression complète terminée$(NC)"

# Reconstruire tout depuis zéro
re: fclean all

# Afficher les logs
logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

# Afficher le statut des conteneurs
status:
	@docker-compose -f $(COMPOSE_FILE) ps

# Redémarrer les conteneurs
restart: down up

# Empêche Make de confondre les règles avec des fichiers
.PHONY: all setup up down clean fclean re logs status restart
