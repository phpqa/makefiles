###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

JQ?=$(shell command -v jq || which jq 2>/dev/null)
ifeq ($(JQ),)
JQ?=$(DOCKER) run --rm --interactive stedolan/jq:latest
endif

CURL?=$(shell command -v curl || which curl 2>/dev/null)
ifeq ($(CURL),)
CURL?=$(DOCKER) run --rm --network host curlimages/curl:latest
endif

#. Docker variables for Portainer
PORTAINER_IMAGE?=cr.portainer.io/portainer/portainer-ce:latest
PORTAINER_SERVICE_NAME?=portainer
PORTAINER_DATA_VOLUME?=portainer_data

#. Extra variables for Portainer
PORTAINER_ADMIN_PASSWORD?=admin
PORTAINER_ADMIN_PASSWORD_LENGTH?=5
PORTAINER_LOGO_URL?=
PORTAINER_SESSION_TIMEOUT_IN_HOURS?=8640

#. Support for Traefik
PORTAINER_TRAEFIK_DOMAIN?=portainer.localhost
PORTAINER_TRAEFIK_NETWORK?=$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)

###
## Docker Tools
###

#. Pull the Portainer container
portainer.pull:%.pull:
	@$(DOCKER) image pull "$(PORTAINER_IMAGE)"
.PHONY: portainer.pull

#. Start the Portainer container
portainer.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(PORTAINER_SERVICE_NAME)" 2> /dev/null)"; then \
		$(DOCKER) container run --detach --name "$(PORTAINER_SERVICE_NAME)" \
			--volume "$(PORTAINER_DATA_VOLUME):/data" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--publish "9000" \
			--label "traefik.enable=true" \
			--label "traefik.docker.network=$(if $(PORTAINER_TRAEFIK_NETWORK),$(PORTAINER_TRAEFIK_NETWORK),traefik)" \
			--label "traefik.http.routers.$(PORTAINER_SERVICE_NAME).entrypoints=web" \
			--label "traefik.http.routers.$(PORTAINER_SERVICE_NAME).rule=Host(\`$(PORTAINER_TRAEFIK_DOMAIN)\`)" \
			--label "traefik.http.services.$(PORTAINER_SERVICE_NAME).loadbalancer.server.port=9000" \
			--network "$(if $(PORTAINER_TRAEFIK_NETWORK),$(PORTAINER_TRAEFIK_NETWORK),traefik)" \
			"$(PORTAINER_IMAGE)" \
			--bind ":9000" \
			--admin-password "$(subst $$,\$$,$(shell $(DOCKER) run --rm httpd:2.4-alpine sh -c "htpasswd -nbB admin '$(PORTAINER_ADMIN_PASSWORD)' | cut -d ':' -f 2"))" \
			--host "unix:///var/run/docker.sock" \
			>/dev/null; \
	else \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(PORTAINER_SERVICE_NAME)$$" 2>/dev/null)"; then \
			$(DOCKER) container start "$(PORTAINER_SERVICE_NAME)" >/dev/null; \
		fi; \
	fi
.PHONY: portainer.start

#. Wait for the Portainer container to be running
portainer.ensure:%.ensure: | %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(PORTAINER_SERVICE_NAME)$$" 2>/dev/null)"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=created" --filter "status=running" --filter "name=^$(PORTAINER_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(PORTAINER_SERVICE_NAME)\" never started."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(PORTAINER_SERVICE_NAME)")" "$(PORTAINER_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
	@until test "$$($(CURL) --location --silent --fail --output /dev/null --write-out "%{http_code}" "http://$$($(DOCKER) container port "$(PORTAINER_SERVICE_NAME)" "9000" 2>/dev/null | grep "0.0.0.0")")" = "200"; do \
		if test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(PORTAINER_SERVICE_NAME)$$" 2>/dev/null)"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The container \"$(PORTAINER_SERVICE_NAME)\" stopped before being available."; \
			$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(PORTAINER_SERVICE_NAME)")" "$(PORTAINER_SERVICE_NAME)"; \
			exit 1; \
		fi; \
		sleep 1; \
	done
.PHONY: portainer.ensure

#. Setup the Portainer container
portainer.setup:%.setup: | %.ensure
	@AUTHORIZATION="$$( \
		$(CURL) --location --silent --show-error "http://$$($(DOCKER) container port "$(PORTAINER_SERVICE_NAME)" "9000" | grep "0.0.0.0")/api/auth" \
			-X POST \
			--data-raw '{"username":"admin","password":"$(PORTAINER_ADMIN_PASSWORD)"}' \
		| $(JQ) -r '.jwt' \
	)"; \
	$(if $(PORTAINER_LOGO_URL), \
		$(CURL) --location --silent --show-error "http://$$($(DOCKER) container port "$(PORTAINER_SERVICE_NAME)" "9000" | grep "0.0.0.0")/api/settings" \
			-X PUT -H "Authorization: Bearer $${AUTHORIZATION}" \
			--data-raw '{"LogoUrl":"$(PORTAINER_LOGO_URL)"}' > /dev/null; \
	) \
	$(if $(PORTAINER_ADMIN_PASSWORD_LENGTH), \
		$(CURL) --location --silent --show-error "http://$$($(DOCKER) container port "$(PORTAINER_SERVICE_NAME)" "9000" | grep "0.0.0.0")/api/settings" \
			-X PUT -H "Authorization: Bearer $${AUTHORIZATION}" \
			--data-raw '{"InternalAuthSettings":{"RequiredPasswordLength":$(PORTAINER_ADMIN_PASSWORD_LENGTH)}}' > /dev/null; \
	) \
	$(if $(PORTAINER_SESSION_TIMEOUT_IN_HOURS), \
		$(CURL) --location --silent --show-error "http://$$($(DOCKER) container port "$(PORTAINER_SERVICE_NAME)" "9000" | grep "0.0.0.0")/api/settings" \
			-X PUT -H "Authorization: Bearer $${AUTHORIZATION}" \
			--data-raw '{"UserSessionTimeout":"$(PORTAINER_SESSION_TIMEOUT_IN_HOURS)h"}' > /dev/null; \
	) \
	true
.PHONY: portainer.setup

#. List the url to the Portainer container
portainer.list:%.list: | %.ensure
	@printf "Open Portainer: %s or %s (admin/%s)\n" \
		"http://$(PORTAINER_TRAEFIK_DOMAIN)$(if $(filter-out 80,$(TRAEFIK_HTTP_PORT)),:$(TRAEFIK_HTTP_PORT))" \
		"http://$$($(DOCKER) container port "$(PORTAINER_SERVICE_NAME)" "9000" | grep "0.0.0.0")" "$(PORTAINER_ADMIN_PASSWORD)"
.PHONY: portainer.list

#. List the logs of the Portainer container
portainer.log:%.log:
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(PORTAINER_SERVICE_NAME)")" "$(PORTAINER_SERVICE_NAME)"
.PHONY: portainer.log

#. Stop the Portainer container
portainer.stop:%.stop:
	@$(DOCKER) container stop "$(PORTAINER_SERVICE_NAME)"
.PHONY: portainer.stop

#. Clear the Portainer container
portainer.clear:%.clear:
	@$(DOCKER) container kill "$(PORTAINER_SERVICE_NAME)" &>/dev/null || true
	@$(DOCKER) container rm --force --volumes "$(PORTAINER_SERVICE_NAME)" &>/dev/null || true
	@$(DOCKER) volume rm --force "$(PORTAINER_DATA_VOLUME)" &>/dev/null || true
.PHONY: portainer.clear

#. Reset the Portainer volume
portainer.reset:%.reset:
	-@$(MAKE) $(*).clear
	@$(MAKE) $(*)
.PHONY: portainer.reset

# Run Portainer in a container
# @see https://docs.portainer.io/
portainer:%: | %.start %.setup %.list
	@true
.PHONY: portainer
