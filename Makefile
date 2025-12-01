.PHONY: help up down build logs restart shell ps status health \
        dev-up dev-down dev-build dev-logs dev-restart dev-shell dev-ps \
        prod-up prod-down prod-build prod-logs prod-restart \
        backend-shell gateway-shell mongo-shell backend-build backend-install \
        backend-type-check backend-dev db-reset db-backup \
        clean clean-all clean-volumes

# Variables
MODE ?= dev
ARGS ?=
SERVICE ?= backend
COMPOSE_FILE_DEV = docker/compose.development.yaml
COMPOSE_FILE_PROD = docker/compose.production.yaml
DC_DEV = docker compose -f $(COMPOSE_FILE_DEV) --env-file .env
DC_PROD = docker compose -f $(COMPOSE_FILE_PROD) --env-file .env

# Select compose command based on MODE
ifeq ($(MODE),prod)
	DC = $(DC_PROD)
else
	DC = $(DC_DEV)
endif

.DEFAULT_GOAL := help

help:
	@echo "E-Commerce Backend - DevOps Commands"
	@echo ""
	@echo "Docker Services:"
	@echo "  make up [service...]           - Start services (use MODE=prod for production)"
	@echo "  make down [service...]         - Stop services (use MODE=prod, ARGS='--volumes' for options)"
	@echo "  make build [service...]        - Build containers (use MODE=prod for production)"
	@echo "  make logs [service]            - View logs (use SERVICE=backend MODE=prod for production)"
	@echo "  make restart [service...]      - Restart services (use MODE=prod for production)"
	@echo "  make shell [service]           - Open shell (use SERVICE=gateway MODE=prod, default: backend)"
	@echo "  make ps                        - Show running containers (use MODE=prod for production)"
	@echo ""
	@echo "Convenience Aliases (Development):"
	@echo "  make dev-up                    - Start development environment"
	@echo "  make dev-down                  - Stop development environment"
	@echo "  make dev-build                 - Build development containers"
	@echo "  make dev-logs                  - View development logs"
	@echo "  make dev-restart               - Restart development services"
	@echo "  make dev-shell                 - Open shell in backend container"
	@echo "  make dev-ps                    - Show running development containers"
	@echo "  make backend-shell             - Open shell in backend container"
	@echo "  make gateway-shell             - Open shell in gateway container"
	@echo "  make mongo-shell               - Open MongoDB shell"
	@echo ""
	@echo "Convenience Aliases (Production):"
	@echo "  make prod-up                   - Start production environment"
	@echo "  make prod-down                 - Stop production environment"
	@echo "  make prod-build                - Build production containers"
	@echo "  make prod-logs                 - View production logs"
	@echo "  make prod-restart              - Restart production services"
	@echo ""
	@echo "Backend:"
	@echo "  make backend-build             - Build backend TypeScript"
	@echo "  make backend-install           - Install backend dependencies"
	@echo "  make backend-type-check        - Type check backend code"
	@echo "  make backend-dev               - Run backend in development mode (local, not Docker)"
	@echo ""
	@echo "Database:"
	@echo "  make db-reset                  - Reset MongoDB database (WARNING: deletes all data)"
	@echo "  make db-backup                 - Backup MongoDB database"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                     - Remove containers and networks (both dev and prod)"
	@echo "  make clean-all                 - Remove containers, networks, volumes, and images"
	@echo "  make clean-volumes             - Remove all volumes"
	@echo ""
	@echo "Utilities:"
	@echo "  make status                    - Alias for ps"
	@echo "  make health                    - Check service health"

# ==========================================
# Docker Services (Generic)
# ==========================================
up:
	@echo "Starting $(MODE) environment..."
	$(DC) up -d $(ARGS) $(filter-out $@,$(MAKECMDGOALS))
	@$(DC) ps

down:
	@echo "Stopping $(MODE) environment..."
	$(DC) down $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

build:
	@echo "Building $(MODE) images..."
	$(DC) build $(ARGS) $(filter-out $@,$(MAKECMDGOALS))

logs:
	@echo "Showing logs for $(MODE) environment..."
	$(DC) logs -f $(SERVICE) $(filter-out $@,$(MAKECMDGOALS))

restart:
	@echo "Restarting $(MODE) services..."
	$(DC) restart $(filter-out $@,$(MAKECMDGOALS))

shell:
	@echo "Opening shell in $(SERVICE) ($(MODE))..."
	$(DC) exec $(SERVICE) sh

ps:
	@echo "Running containers ($(MODE)):"
	@$(DC) ps

status: ps

# ==========================================
# Development Aliases
# ==========================================
dev-up:
	@$(MAKE) up MODE=dev

dev-down:
	@$(MAKE) down MODE=dev

dev-build:
	@$(MAKE) build MODE=dev

dev-logs:
	@$(MAKE) logs MODE=dev

dev-restart:
	@$(MAKE) restart MODE=dev

dev-shell:
	@$(MAKE) shell MODE=dev SERVICE=backend

dev-ps:
	@$(MAKE) ps MODE=dev

# ==========================================
# Production Aliases
# ==========================================
prod-up:
	@$(MAKE) up MODE=prod ARGS="--build"

prod-down:
	@$(MAKE) down MODE=prod

prod-build:
	@$(MAKE) build MODE=prod

prod-logs:
	@$(MAKE) logs MODE=prod

prod-restart:
	@$(MAKE) restart MODE=prod

# ==========================================
# Service-Specific Shells
# ==========================================
backend-shell:
	@$(MAKE) shell SERVICE=backend

gateway-shell:
	@$(MAKE) shell SERVICE=gateway

mongo-shell:
	@echo "Opening MongoDB shell..."
	@$(DC) exec mongo mongosh -u $(shell grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2)

# ==========================================
# Backend Commands
# ==========================================
backend-build:
	@echo "Building backend TypeScript..."
	cd backend && npm run build

backend-install:
	@echo "Installing backend dependencies..."
	cd backend && npm install

backend-type-check:
	@echo "Type checking backend..."
	cd backend && npm run type-check 2>/dev/null || npx tsc --noEmit

backend-dev:
	@echo "Running backend in development mode (local)..."
	cd backend && npm run dev

# ==========================================
# Database Commands
# ==========================================
db-reset:
	@echo "⚠️  WARNING: This will delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Resetting database..."; \
		$(DC) exec mongo mongosh -u $(shell grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) -p $(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --eval "db.getSiblingDB('$(shell grep MONGO_DATABASE .env | cut -d '=' -f2)').dropDatabase()"; \
		echo "Database reset complete."; \
	else \
		echo "Database reset cancelled."; \
	fi

db-backup:
	@echo "Backing up MongoDB database..."
	@mkdir -p backups
	@$(DC) exec -T mongo mongodump --username=$(shell grep MONGO_INITDB_ROOT_USERNAME .env | cut -d '=' -f2) --password=$(shell grep MONGO_INITDB_ROOT_PASSWORD .env | cut -d '=' -f2) --db=$(shell grep MONGO_DATABASE .env | cut -d '=' -f2) --archive > backups/db-backup-$(shell date +%Y%m%d-%H%M%S).archive
	@echo "Backup complete: backups/db-backup-$(shell date +%Y%m%d-%H%M%S).archive"

# ==========================================
# Cleanup Commands
# ==========================================
clean:
	@echo "Removing containers and networks..."
	@$(DC_DEV) down 2>/dev/null || true
	@$(DC_PROD) down 2>/dev/null || true
	@echo "Cleanup complete."

clean-all:
	@echo "⚠️  WARNING: This will remove all containers, networks, volumes, and images!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Removing everything..."; \
		$(DC_DEV) down --volumes --rmi all 2>/dev/null || true; \
		$(DC_PROD) down --volumes --rmi all 2>/dev/null || true; \
		echo "All cleanup complete."; \
	else \
		echo "Cleanup cancelled."; \
	fi

clean-volumes:
	@echo "⚠️  WARNING: This will remove all volumes and delete all data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Removing volumes..."; \
		$(DC_DEV) down --volumes 2>/dev/null || true; \
		$(DC_PROD) down --volumes 2>/dev/null || true; \
		echo "Volumes removed."; \
	else \
		echo "Volume cleanup cancelled."; \
	fi

# ==========================================
# Utilities
# ==========================================
health:
	@echo "Checking service health..."
	@echo -n "Gateway: "
	@curl -s http://localhost:5921/health > /dev/null && echo "✓ Healthy" || echo "✗ Unhealthy"
	@echo -n "Backend: "
	@curl -s http://localhost:5921/api/health > /dev/null && echo "✓ Healthy" || echo "✗ Unhealthy"

# Catch-all target to handle arguments
%:
	@:
