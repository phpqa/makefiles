###
##. Dependencies
###

ifeq ($(DOCKER),)
$(warning Please provide the variable DOCKER)
endif
ifeq ($(DOCKER_SOCKET),)
$(warning Please provide the variable DOCKER_SOCKET)
endif
ifeq ($(CURL),)
$(warning Please provide the variable CURL)
endif
ifeq ($(JQ),)
$(warning Please provide the variable JQ)
endif

###
##. Configuration
###

#. Docker variables
PORTAINER_IMAGE?=cr.portainer.io/portainer/portainer-ce:alpine
PORTAINER_SERVICE_NAME?=portainer
PORTAINER_DATA_VOLUME?=portainer_data

#. Adding our own variables
PORTAINER_ADMIN_PASSWORD?=admin
PORTAINER_ADMIN_PASSWORD_LENGTH?=5
PORTAINER_LOGO_URL?=
PORTAINER_SESSION_TIMEOUT_IN_HOURS?=8640

#. Support for Traefik
PORTAINER_TRAEFIK_DOMAIN?=$(PORTAINER_SERVICE_NAME).localhost
PORTAINER_TRAEFIK_NETWORK?=$(TRAEFIK_PROVIDERS_DOCKER_NETWORK)

###
##. Portainer
##. A powerful, open source toolset that allows you to easily build and manage containers
##. @see https://docs.portainer.io/
###

#. Pull the Portainer container
portainer.pull:%.pull: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
	@$(DOCKER) image pull "$(PORTAINER_IMAGE)"
.PHONY: portainer.pull

#. Start the Portainer container
portainer.start:%.start: | $(DOCKER_DEPENDENCY) $(DOCKER_SOCKET)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(DOCKER_SOCKET),)
	$(error Please provide the variable DOCKER_SOCKET before running $(@))
endif
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(PORTAINER_SERVICE_NAME)" 2> /dev/null)"; then \
		if test -z "$$($(DOCKER) network ls --quiet --filter "name=^$(PORTAINER_TRAEFIK_NETWORK)$$")"; then \
			$(DOCKER) network create "$(PORTAINER_TRAEFIK_NETWORK)" > /dev/null 2>&1; \
		fi; \
		$(DOCKER) container run --detach --name "$(PORTAINER_SERVICE_NAME)" \
			--volume "$(PORTAINER_DATA_VOLUME):/data" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--publish "9000" \
			--health-cmd='wget --no-verbose --tries=1 --spider http://localhost:9000 || exit 1' \
			--health-interval=60s \
			--health-retries=3 \
			--health-timeout=5s \
			--health-start-period=20s \
			--label "traefik.enable=true" \
			$(if $(PORTAINER_TRAEFIK_NETWORK),--label "traefik.docker.network=$(PORTAINER_TRAEFIK_NETWORK)") \
			--label "traefik.http.routers.$(PORTAINER_SERVICE_NAME).entrypoints=web" \
			--label "traefik.http.routers.$(PORTAINER_SERVICE_NAME).rule=Host(\`$(PORTAINER_TRAEFIK_DOMAIN)\`)" \
			--label "traefik.http.services.$(PORTAINER_SERVICE_NAME).loadbalancer.server.port=9000" \
			$(if $(PORTAINER_TRAEFIK_NETWORK),--network "$(PORTAINER_TRAEFIK_NETWORK)") \
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
portainer.ensure-running:%.ensure-running: | $(DOCKER_DEPENDENCY) %.start
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(CURL),)
	$(error Please provide the variable CURL before running $(@))
endif
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
.PHONY: portainer.ensure-running

#. Setup the Portainer container
portainer.setup:%.setup: | %.ensure-running
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
ifeq ($(CURL),)
	$(error Please provide the variable CURL before running $(@))
endif
ifeq ($(JQ),)
	$(error Please provide the variable JQ before running $(@))
endif
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
portainer.list:%.list: | $(DOCKER_DEPENDENCY) %.ensure-running
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
	@printf "Open Portainer: %s or %s (admin/%s)\n" \
		"http://$(PORTAINER_TRAEFIK_DOMAIN)$(if $(filter-out 80,$(TRAEFIK_HTTP_PORT)),:$(TRAEFIK_HTTP_PORT))" \
		"http://$$($(DOCKER) container port "$(PORTAINER_SERVICE_NAME)" "9000" | grep "0.0.0.0")" "$(PORTAINER_ADMIN_PASSWORD)"
.PHONY: portainer.list

#. List the logs of the Portainer container
portainer.log:%.log: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
	@$(DOCKER) container logs --since "$$($(DOCKER) container inspect --format "{{ .State.StartedAt }}" "$(PORTAINER_SERVICE_NAME)")" "$(PORTAINER_SERVICE_NAME)"
.PHONY: portainer.log

#. Stop the Portainer container
portainer.stop:%.stop: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
	@$(DOCKER) container stop "$(PORTAINER_SERVICE_NAME)"
.PHONY: portainer.stop

#. Clear the Portainer container
portainer.clear:%.clear: | $(DOCKER_DEPENDENCY)
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
	@$(DOCKER) container kill "$(PORTAINER_SERVICE_NAME)" > /dev/null 2>&1 || true
	@$(DOCKER) container rm --force --volumes "$(PORTAINER_SERVICE_NAME)" > /dev/null 2>&1 || true
	@$(DOCKER) volume rm --force "$(PORTAINER_DATA_VOLUME)" > /dev/null 2>&1 || true
.PHONY: portainer.clear

#. Wait for the Portainer container to be cleared
portainer.ensure-cleared:%.ensure-cleared: | $(DOCKER_DEPENDENCY) %.clear
ifeq ($(DOCKER),)
	$(error Please provide the variable DOCKER before running $(@))
endif
	@until test -z "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=^$(PORTAINER_SERVICE_NAME)$$")"; do \
		sleep 1; \
	done
.PHONY: portainer.ensure-cleared

#. Reset the Portainer volume
portainer.reset:%.reset: | %.ensure-cleared %.ensure-running; @true
.PHONY: portainer.reset

# Run Portainer in a container
# @see https://docs.portainer.io/
portainer:%: | %.start %.setup %.list; @true
.PHONY: portainer
