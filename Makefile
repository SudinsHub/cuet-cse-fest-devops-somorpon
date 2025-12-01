.PHONY: help dev-up dev-down prod-up prod-down ps logs shell clean

MODE ?= dev
COMPOSE_FILE_DEV = docker/compose.development.yaml
COMPOSE_FILE_PROD = docker/compose.production.yaml
DC_DEV = docker compose -f $(COMPOSE_FILE_DEV) --env-file .env
DC_PROD = docker compose -f $(COMPOSE_FILE_PROD) --env-file .env
SERVICE ?= backend

help:
	@echo "E-Commerce Backend - DevOps Commands"
	@echo ""
	@echo "Development:"
	@echo "  make dev-up      - Start development environment"
	@echo "  make dev-down    - Stop development environment"
	@echo "  make dev-logs    - View development logs"
	@echo ""
	@echo "Production:"
	@echo "  make prod-up     - Start production environment"
	@echo "  make prod-down   - Stop production environment"
	@echo "  make prod-logs   - View production logs"
	@echo ""
	@echo "Utils:"
	@echo "  make ps          - Show containers"
	@echo "  make logs SERVICE=name - View logs for service"
	@echo "  make shell SERVICE=name - Open shell in service"
	@echo "  make clean       - Stop and remove all containers"

dev-up:
	@echo "Starting development environment..."
	$(DC_DEV) up -d
	@$(DC_DEV) ps

dev-down:
	@echo "Stopping development environment..."
	$(DC_DEV) down

dev-logs:
	$(DC_DEV) logs -f

dev-shell:
	$(DC_DEV) exec $(SERVICE) sh

prod-up:
	@echo "Starting production environment..."
	$(DC_PROD) up -d
	@$(DC_PROD) ps

prod-down:
	@echo "Stopping production environment..."
	$(DC_PROD) down

prod-logs:
	$(DC_PROD) logs -f

prod-shell:
	$(DC_PROD) exec $(SERVICE) sh

ps:
	@$(DC_DEV) ps 2>/dev/null || $(DC_PROD) ps

logs:
	@$(DC_DEV) logs -f $(SERVICE) 2>/dev/null || $(DC_PROD) logs -f $(SERVICE)

shell:
	@$(DC_DEV) exec $(SERVICE) sh 2>/dev/null || $(DC_PROD) exec $(SERVICE) sh

clean:
	@echo "Cleaning up..."
	$(DC_DEV) down 2>/dev/null || true
	$(DC_PROD) down 2>/dev/null || true

health:
	@echo "Checking health..."
	@curl -s http://localhost:5921/health || echo "Gateway not responding"
	@curl -s http://localhost:5921/api/health || echo "Backend not responding"

.DEFAULT_GOAL := help
