COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR= $(HOME)/data
all: up

build:
	$(COMPOSE) build

up:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down -v --rmi all

re: fclean all

.PHONY: all build up down start stop restart logs ps clean fclean re
