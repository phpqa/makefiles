###
##. Configuration
###

JQ?=$(shell command -v jq || which jq 2>/dev/null)
ifeq ($(JQ),)
ifeq ($(DOCKER),)
$(error Please provide the variable JQ or the variable DOCKER before including this file.)
else
JQ?=$(DOCKER) run --rm --interactive stedolan/jq
endif
endif

ifeq ($(DOCKER_COMPOSE),)
$(error Please provide the variable DOCKER_COMPOSE before including this file.)
endif

# TODO Move to DOCKER_CONTAINER_NAME_FOR_KEYCLOAK - docker inspect $(docker-compose ps -q keycloak) --format="{{ .Name }}"
DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK?=
ifeq ($(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK),)
$(error Please provide the variable DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK before including this file.)
endif

###
##. Keycloak API
###

# No parameters
get-keycloak-token=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request POST \"http://localhost:\$${KC_HTTP_PORT}/realms/master/protocol/openid-connect/token\" \
			--header 'Content-Type: application/x-www-form-urlencoded' \
			--data-urlencode 'client_id=admin-cli' \
			--data-urlencode 'grant_type=password' \
			--data-urlencode \"username=\$${KEYCLOAK_ADMIN}\" \
			--data-urlencode \"password=\$${KEYCLOAK_ADMIN_PASSWORD}\" \
	" \
	| $(JQ) -r '.access_token' || true

# $1 is the realm
find-keycloak-realm-id=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request GET \"http://localhost:\$${KC_HTTP_PORT}/admin/realms/$(strip $(1))\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-keycloak-token))' \
	" \
	| $(JQ) -r '.id // empty' 2>/dev/null || true

# $1 is the realm
add-keycloak-realm=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request POST \"http://localhost:\$${KC_HTTP_PORT}/admin/realms\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-keycloak-token))' \
			--data-raw '{\"id\":\"$(strip $(1))\",\"realm\":\"$(strip $(1))\",\"displayName\":\"$(strip $(1))\",\"enabled\":\"true\"}' \
	"

# $1 is the realm, $2 is the username
find-keycloak-user-id=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request GET \"http://localhost:\$${KC_HTTP_PORT}/admin/realms/$(strip $(1))/users?username=$(strip $(2))\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-keycloak-token))' \
	" \
	| $(JQ) -r '.[].id // empty' 2>/dev/null || true

# $1 is the realm, $2 is the username
add-keycloak-user=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request POST \"http://localhost:\$${KC_HTTP_PORT}/admin/realms/$(strip $(1))/users\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-keycloak-token))' \
			--data-raw '{\"username\":\"$(strip $(2))\",\"enabled\":\"true\"}' \
	"

# $1 is the realm, $2 is the username, $3 is the password
update-keycloak-user-password=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request PUT \"http://localhost:\$${KC_HTTP_PORT}/admin/realms/$(strip $(1))/users/$$($(call find-keycloak-user-id,$(1),$(2)))/reset-password\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-keycloak-token))' \
			--data-raw '{\"type\":\"password\",\"temporary\":\"false\",\"value\":\"$(strip $(3))\"}' \
	"

# $1 is the realm, $2 is the username, $3 is the password
ensure-keycloak-realm-and-user=\
	REALM="$(if $(strip $(1)),$(strip $(1)),master)"; \
	USERNAME="$(if $(strip $(2)),$(strip $(2)),$(shell whoami))"; \
	PASSWORD="$(if $(strip $(3)),$(strip $(3)),$${USERNAME})"; \
	if test -z "$$($(call find-keycloak-realm-id,$${REALM}) || true)"; then \
		$(call add-keycloak-realm,$${REALM}); \
	fi; \
	if test -z "$$($(call find-keycloak-user-id,$${REALM},$${USERNAME}) || true)"; then \
		$(call add-keycloak-user,$${REALM},$${USERNAME}); \
	fi; \
	$(call update-keycloak-user-password,$${REALM},$${USERNAME},$${PASSWORD})
