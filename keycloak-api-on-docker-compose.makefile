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
$(error Please install docker-compose.)
endif

DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK?=
ifeq ($(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK),)
$(error Please provide the variable DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK before including this file.)
endif

###
##. Keycloak API
###

# TODO add api call to add a realm to keycloak

# No parameters
get-token-for-keycloak-service=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request POST \"http://\$${HOSTNAME}:\$${KEYCLOAK_HTTP_PORT}/auth/realms/master/protocol/openid-connect/token\" \
			--header 'Content-Type: application/x-www-form-urlencoded' \
			--data-urlencode \"username=\$${KEYCLOAK_USER}\" \
			--data-urlencode \"password=\$${KEYCLOAK_PASSWORD}\" \
			--data-urlencode 'grant_type=password' \
			--data-urlencode 'client_id=admin-cli' \
	" \
	| $(JQ) -r '.access_token' || true
# $1 is realm, $2 is username
find-user-id-on-keycloak-service=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request GET \"http://\$${HOSTNAME}:\$${KEYCLOAK_HTTP_PORT}/auth/admin/realms/$(strip $(1))/users?username=$(strip $(2))\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-token-for-keycloak-service))' \
	" \
	| $(JQ) -r '.[].id' 2>/dev/null || true
# $1 is realm, $2 is username
add-user-to-keycloak-service=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request POST \"http://\$${HOSTNAME}:\$${KEYCLOAK_HTTP_PORT}/auth/admin/realms/$(strip $(1))/users\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-token-for-keycloak-service))' \
			--data-raw '{\"username\":\"$(strip $(2))\",\"enabled\":\"true\"}' \
	"
# $1 is realm, $2 is username, $3 is password
update-user-password-on-keycloak-service=\
	$(DOCKER_COMPOSE) exec -T "$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK)" sh -c "\
		curl --silent --show-error \
			--location --request PUT \"http://\$${HOSTNAME}:\$${KEYCLOAK_HTTP_PORT}/auth/admin/realms/$(strip $(1))/users/$$($(call find-user-id-on-keycloak-service,$(1),$(2)))/reset-password\" \
			--header 'Content-Type: application/json' \
			--header 'Authorization: Bearer $$($(call get-token-for-keycloak-service))' \
			--data-raw '{\"type\":\"password\",\"temporary\":\"false\",\"value\":\"$(strip $(3))\"}' \
	"
# $1 is realm, $2 is username, $3 is password
ensure-user-on-keycloak-service=\
	REALM="$(if $(strip $(1)),$(strip $(1)),master)"; \
	USERNAME="$(if $(strip $(2)),$(strip $(2)),$(shell whoami))"; \
	PASSWORD="$(if $(strip $(3)),$(strip $(3)),$${USERNAME})"; \
	USER_ID="$$($(call find-user-id-on-keycloak-service,$${REALM},$${USERNAME}) || true)"; \
	if test -z "$${USER_ID}"; then $(call add-user-to-keycloak-service,$${REALM},$${USERNAME}); fi; \
	if test -n "$${USER_ID}"; then $(call update-user-password-on-keycloak-service,$${REALM},$${USERNAME},$${PASSWORD}); fi
