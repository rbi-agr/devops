FORCE_RECREATE_FLAG := $(if $(filter 1,$(ENABLE_FORCE_RECREATE)),--force-recreate,)
REMOVE_ORPHANS_FLAG := $(if $(or $(services),$(filter 1, $(DISABLE_REMOVE_ORPHANS))),,--remove-orphans)
REMOVE_ANSI_FLAG := $(if $(filter 1,$(DISABLE_ANSI)),,--ansi never)

DOCKER_COMPOSE_COMMAND=docker compose $(REMOVE_ANSI_FLAG) -p esm

install-docker:
	@./scripts/install-docker.sh

install-gpu-drivers:
	@./scripts/install-gpu-drivers.sh

setup-daemon:
	@./scripts/setup-daemon.sh

migrate-volume:
	@./scripts/migrate-volume.sh
	
setup-webhook:
	@./scripts/webhook/setup-webhook.sh
	
reload-caddy:
	@echo "Reloading caddy"
	$(DOCKER_COMPOSE_COMMAND) exec -w /etc/caddy caddy caddy reload || true

deploy: $(if $(filter 1,$(ENABLE_GIT_PULL)),git-pull,) $(if $(filter 1,$(DISABLE_PULL)),,pull build) reload-caddy
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
