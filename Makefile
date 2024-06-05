FORCE_RECREATE_FLAG := $(if $(ENABLE_FORCE_RECREATE),--force-recreate,)
REMOVE_ORPHANS_FLAG := $(if $(or $(services),$(DISABLE_REMOVE_ORPHANS)),,--remove-orphans)
REMOVE_ANSI_FLAG := $(if $(DISABLE_ANSI),--ansi never,)

DOCKER_COMPOSE_COMMAND=docker compose $(REMOVE_ANSI_FLAG) -p bhasai

setup-daemon:
	@./scripts/setup-daemon.sh
	
setup-webhook:
	@./scripts/webhook/setup-webhook.sh
	
reload-caddy:
	@echo "Reloading caddy"
	$(DOCKER_COMPOSE_COMMAND) exec -w /etc/caddy caddy caddy reload || true

deploy: $(if $(DISABLE_PULL),,pull build) reload-caddy
	$(DOCKER_COMPOSE_COMMAND)  up -d $(FORCE_RECREATE_FLAG) $(REMOVE_ORPHANS_FLAG) ${services}
	
restart:
	$(DOCKER_COMPOSE_COMMAND)  restart ${services}

stop:
	$(DOCKER_COMPOSE_COMMAND)  stop ${services}

down:
	$(DOCKER_COMPOSE_COMMAND)  down ${services}
	
pull:
	$(DOCKER_COMPOSE_COMMAND) pull ${services}

build:
	$(DOCKER_COMPOSE_COMMAND) build ${services} 

git-pull: 
	git pull

.PHONY: deploy restart stop down pull build reload-caddy git-pull