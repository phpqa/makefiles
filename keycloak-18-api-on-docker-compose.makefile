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

# $1 is server, $2 is realm, $3 is username, $4 is password
# typical oneliner: $(call start-keycloak-session,http://\$${KC_HTTP_HOST:-localhost}:\$${KC_HTTP_PORT:-8080},master,\$${KEYCLOAK_ADMIN:-admin},\$${KEYCLOAK_ADMIN_PASSWORD:-admin})
start-keycloak-session=\
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh config credentials \
			--server \"$(strip $(1))\" \
			--realm \"$(strip $(2))\" \
			--user \"$(strip $(3))\" \
			--password \"$(strip $(4))\" \
	"

# $1 is the realm
find-keycloak-realm-id=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh get realms/$${REALM} \
			--fields id \
			2>/dev/null \
	" \
	| $(JQ) -r ".id // empty"

# $1 is the realm
add-keycloak-realm=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh create realms \
			--set realm=$${REALM} \
			--set enabled=true \
	"

# $1 is the realm
ensure-keycloak-realm=\
	if test -z "$$($(call find-keycloak-realm-id,$(1)) || true)"; then \
		$(call add-keycloak-realm,$(1)); \
	fi

# $1 is the realm, $2 is the client name
find-keycloak-realm-client-id=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	CLIENT_NAME="$(if $(2),$(strip $(2)),admin-cli)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh get clients \
			--target-realm $${REALM} \
			--fields id,clientId \
			2>/dev/null \
	" \
	| $(JQ) -r ".[] | select(.clientId==\"$${CLIENT_NAME}\") | .id // empty"

# $1 is the realm, $2 is the client name
add-keycloak-realm-client=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	CLIENT_NAME="$(if $(2),$(strip $(2)),admin-cli)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh create clients \
			--target-realm $${REALM} \
			--set clientId=$${CLIENT_NAME} \
			--set enabled=true \
			--set publicClient=false \
			--set directAccessGrantsEnabled=true \
	"

# $1 is the realm, $2 is the client name
ensure-keycloak-realm-client=\
	if test -z "$$($(call find-keycloak-realm-client-id,$(1),$(2)))"; then \
		$(call add-keycloak-realm-client,$(1),$(2)); \
	fi

# $1 is the realm, $2 is the client name, $3 are the redirect uris (as a space separated list)
update-keycloak-realm-client-redirectUris=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	CLIENT_NAME="$(if $(2),$(strip $(2)),admin-cli)"; \
	REDIRECT_URI="$(3)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh update clients/$$($(call find-keycloak-realm-client-id,$${REALM},$${CLIENT_NAME})) \
			--target-realm $${REALM} \
			--set 'redirectUris=[$(subst $(space),$(comma),$(foreach uri,$(3),\"$(uri)\"))]' \
			--merge \
	"

# $1 is the realm, $2 is the client name, $3 is the role
find-keycloak-realm-client-role=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	CLIENT_NAME="$(if $(2),$(strip $(2)),admin-cli)"; \
	ROLE="$(3)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh get-roles \
			--target-realm=$${REALM} \
			--cclientid=$${CLIENT_NAME} \
			--rolename=$${ROLE} \
			2>/dev/null \
	" \
	| $(JQ) -r ".name // empty"

# $1 is the realm, $2 is the client name, $3 is the role
add-keycloak-realm-client-role=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	CLIENT_NAME="$(if $(2),$(strip $(2)),admin-cli)"; \
	ROLE="$(3)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh create clients/$$($(call find-keycloak-realm-client-id,$${REALM},$${CLIENT_NAME}))/roles \
			--target-realm $${REALM} \
			--set name=$${ROLE} \
	"

# $1 is the realm, $2 is the client name, $3 is the role
ensure-keycloak-realm-client-role=\
	if test -z "$$($(call find-keycloak-realm-client-role,$(1),$(2),$(3)) || true)"; then \
		$(call add-keycloak-realm-client-role,$(1),$(2),$(3)); \
	fi

# $1 is the realm, $2 is the username
find-keycloak-realm-user-id=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	USERNAME="$(if $(2),$(strip $(2)),$(shell whoami))"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh get users \
			--target-realm $${REALM} \
			--fields id,username \
			2>/dev/null \
	" \
	| $(JQ) -r ".[] | select(.username==\"$${USERNAME}\") | .id // empty"

# $1 is the realm, $2 is the username
add-keycloak-realm-user=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	USERNAME="$(if $(2),$(strip $(2)),$(shell whoami))"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh create users \
			--target-realm $${REALM} \
			--set username=$${USERNAME} \
			--set enabled=true \
	"

# $1 is the realm, $2 is the username
ensure-keycloak-realm-user=\
	if test -z "$$($(call find-keycloak-realm-user-id,$(1),$(2)) || true)"; then \
		$(call add-keycloak-realm-user,$(1),$(2)); \
	fi

# $1 is the realm, $2 is the username, $3 is the password
reset-keycloak-realm-user-password=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	USERNAME="$(if $(2),$(strip $(2)),$(shell whoami))"; \
	PASSWORD="$(if $(3),$(strip $(3)),$(shell whoami))"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh update users/$$($(call find-keycloak-realm-user-id,$${REALM},$${USERNAME}))/reset-password \
			--target-realm $${REALM} \
			--set type=password \
			--set value=$${PASSWORD} \
			--set temporary=false \
			--no-merge \
	"

# $1 is the realm, $2 is the username, $3 is the field, $4 is the value
update-keycloak-realm-user-field=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	USERNAME="$(if $(2),$(strip $(2)),$(shell whoami))"; \
	FIELD="$(3)"; \
	VALUE="$(4)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh update users/$$($(call find-keycloak-realm-user-id,$${REALM},$${USERNAME})) \
			--target-realm $${REALM} \
			--set $${FIELD}=$${VALUE} \
	"

# $1 is the realm, $2 is the username, $3 is the client name, $4 is the role
find-keycloak-realm-user-client-role=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	USERNAME="$(if $(2),$(strip $(2)),$(shell whoami))"; \
	CLIENT_NAME="$(if $(3),$(strip $(3)),admin-cli)"; \
	ROLE="$(4)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh get-roles \
			--target-realm=$${REALM} \
			--uusername=$${USERNAME} \
			--cclientid=$${CLIENT_NAME} \
			--rolename=$${ROLE} \
			2>/dev/null \
	" \
	| $(JQ) -r ".[] | select(.name==\"$${ROLE}\") | .name // empty"

# $1 is the realm, $2 is the username, $3 is the client name, $4 is the role
add-keycloak-realm-user-client-role=\
	REALM="$(if $(1),$(strip $(1)),master)"; \
	USERNAME="$(if $(2),$(strip $(2)),$(shell whoami))"; \
	CLIENT_NAME="$(if $(3),$(strip $(3)),admin-cli)"; \
	ROLE="$(4)"; \
	$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		/opt/keycloak/bin/kcadm.sh add-roles \
			--target-realm $${REALM} \
			--uusername $${USERNAME} \
			--cclientid $${CLIENT_NAME} \
			--rolename $${ROLE} \
	"

# $1 is the realm, $2 is the username, $3 is the client name, $4 is the role
ensure-keycloak-realm-user-client-role=\
	if test -z "$$($(call find-keycloak-realm-user-client-role,$(1),$(2),$(3),$(4)) || true)"; then \
		$(call add-keycloak-realm-user-client-role,$(1),$(2),$(3),$(4)); \
	fi

keycloak.ensure-ready: compose.service.$(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK).ensure-running
	@$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_SERVICE_NAME_FOR_KEYCLOAK) sh -c " \
		while test \"\$$(curl --silent --output /dev/null --write-out '%{http_code}' http://\$${KC_HTTP_HOST:-localhost}:\$${KC_HTTP_PORT:-8080}/realms/master)\" != \"200\"; do \
			sleep 1; \
		done \
	"
.PHONY: keycloak.ensure-ready
