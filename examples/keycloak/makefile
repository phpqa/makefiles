###
##. Configuration
###

include ../../builtins.makefile
include ../../base.makefile
include ../../docker.makefile

DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK=keycloak

include ../../keycloak-18-api-on-docker-compose.makefile

# Run everything
all: keycloak.ensure
.PHONY: all

# Ensure Keycloak has been set up
keycloak.ensure: keycloak.ensure-ready
	@$(call start-keycloak-session,http://\$${KC_HTTP_HOST:-localhost}:\$${KC_HTTP_PORT:-8080},master,\$${KEYCLOAK_ADMIN:-admin},\$${KEYCLOAK_ADMIN_PASSWORD:-admin})
	@$(call ensure-keycloak-realm,my-realm)
	@$(call ensure-keycloak-realm-client,my-realm,my-client)
	@$(call update-keycloak-realm-client-redirectUris,my-realm,my-client,http://localhost:8080/*)
	@$(call ensure-keycloak-realm-client-role,my-realm,my-client,my-role)
	@$(call ensure-keycloak-realm-user,my-realm,$(shell whoami))
	@$(call reset-keycloak-realm-user-password,my-realm,$(shell whoami),$(shell whoami))
	@$(call update-keycloak-realm-user-field,my-realm,$(shell whoami),email,test@example.com)
	@$(call ensure-keycloak-realm-user-client-role,my-realm,$(shell whoami),my-client,my-role)
	@printf "%s" "Click to open keycloak: " && $(call println_link,http://$$($(DOCKER_COMPOSE) port $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) $(call get_env_variable,.env,PROJECT_PORT)))
.PHONY: keycloak.ensure
