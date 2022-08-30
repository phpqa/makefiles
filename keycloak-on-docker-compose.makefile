###
##. Configuration
###

# TODO Move to DOCKER_CONTAINER_NAME_FOR_KEYCLOAK - docker inspect $(docker-compose ps -q keycloak) --format="{{ .Name }}"
DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK?=

###
##. Requirements
###

ifeq ($(DOCKER_COMPOSE),)
$(error The variable DOCKER_COMPOSE should never be empty.)
endif
ifeq ($(DOCKER_COMPOSE_DEPENDENCY),)
$(error The variable DOCKER_COMPOSE_DEPENDENCY should never be empty.)
endif
ifeq ($(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK),)
$(error Please provide the variable DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK before including this file.)
endif

###
## Keycloak
###

# Ensure that Keycloak is ready
keycloak.ensure-ready: $(DOCKER_COMPOSE_DEPENDENCY) compose.service.$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK).ensure-running
	@$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		while test \"\$$(curl --silent --output /dev/null --write-out '%{http_code}' http://\$${KC_HTTP_HOST:-localhost}:\$${KC_HTTP_PORT:-8080}/realms/master)\" != \"200\"; do \
			sleep 1; \
		done \
	"
.PHONY: keycloak.ensure-ready

# Export the data from Keycloak to /opt/keycloak/data/export
keycloak.export: | $(DOCKER_COMPOSE_DEPENDENCY) keycloak.ensure-ready
	@$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) \
		/opt/keycloak/bin/kc.sh export --users realm_file --dir /opt/keycloak/data/export
.PHONY: keycloak.export

# Import the data from /opt/keycloak/data/import into Keycloak
keycloak.import: | $(DOCKER_COMPOSE_DEPENDENCY)
	@$(DOCKER_COMPOSE) rm --stop --force -v $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)
	@$(DOCKER_COMPOSE) up -d $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)
.PHONY: keycloak.import
