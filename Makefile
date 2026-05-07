DC=docker compose

up:
	$(DC) up -d --build

down:
	$(DC) down

restart:
	$(DC) down
	$(DC) up -d --build

ps:
	$(DC) ps

logs:
	$(DC) logs -f

# =========================
# Serviços separados
# =========================

up-nginx:
	$(DC) up -d --build nginx

up-laravel:
	$(DC) up -d --build laravel mysql-laravel redis

up-users:
	$(DC) up -d --build users_service

up-orders:
	$(DC) up -d --build orders_service

up-db:
	$(DC) up -d mysql-laravel

up-redis:
	$(DC) up -d redis

restart-nginx:
	$(DC) restart nginx

restart-laravel:
	$(DC) restart laravel

restart-users:
	$(DC) restart users_service

restart-orders:
	$(DC) restart orders_service

logs-nginx:
	$(DC) logs -f nginx

logs-laravel:
	$(DC) logs -f laravel

logs-users:
	$(DC) logs -f users_service

logs-orders:
	$(DC) logs -f orders_service

# =========================
# Setup
# =========================

setup: up composer-install laravel-env laravel-key npm-install-users npm-install-orders migrate

composer-install:
	$(DC) exec laravel composer install

laravel-env:
	$(DC) exec laravel cp .env.example .env || true

laravel-key:
	$(DC) exec laravel php artisan key:generate

migrate:
	$(DC) exec laravel php artisan migrate

npm-install-users:
	$(DC) exec users_service npm install

npm-install-orders:
	$(DC) exec orders_service npm install

# =========================
# Bash / shell
# =========================

bash-laravel:
	$(DC) exec laravel bash

bash-users:
	$(DC) exec users_service sh

bash-orders:
	$(DC) exec orders_service sh

bash-nginx:
	$(DC) exec nginx sh

# =========================
# Laravel
# =========================

artisan:
	$(DC) exec laravel php artisan $(cmd)

clear-laravel:
	$(DC) exec laravel php artisan optimize:clear

# =========================
# Node
# =========================

start-users:
	$(DC) exec users_service npm run start:dev

start-orders:
	$(DC) exec orders_service npm run start:dev

# =========================
# Limpeza
# =========================

down-volumes:
	$(DC) down -v

rebuild:
	$(DC) build --no-cache

fresh:
	$(DC) down -v
	$(DC) up -d --build