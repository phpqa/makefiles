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

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

PORTAINER_IMAGE?=cr.portainer.io/portainer/portainer-ce:latest
PORTAINER_ADMIN_PASSWORD?=admin
PORTAINER_ADMIN_PASSWORD_LENGTH?=5

PORTAINER_LOGO_URL?=
PORTAINER_SESSION_TIMEOUT_IN_HOURS?=8640

PORTAINER_TRAEFIK_NETWORK?=

###
## Docker Tools
###

#. Pull the Portainer container
portainer.pull:%.pull:
	@$(DOCKER) image pull "$(PORTAINER_IMAGE)"
.PHONY: portainer.pull

#. Start the Portainer container
portainer.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(*)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --detach --name "$(*)" \
			--volume "portainer_data:/data" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--publish "9000" \
			$(if $(PORTAINER_TRAEFIK_NETWORK), \
				--label "traefik.enable=true" \
				--label "traefik.docker.network=$(PORTAINER_TRAEFIK_NETWORK)" \
				--label "traefik.http.routers.$(*).entrypoints=web" \
				--label "traefik.http.routers.$(*).rule=Host(\`$(*).localhost\`)" \
				--label "traefik.http.services.$(*).loadbalancer.server.port=9000" \
				--network "$(PORTAINER_TRAEFIK_NETWORK)" \
			) \
			"$(PORTAINER_IMAGE)" \
			--admin-password "$(subst $$,\$$,$(shell $(DOCKER) run --rm httpd:2.4-alpine sh -c "htpasswd -nbB admin '$(PORTAINER_ADMIN_PASSWORD)' | cut -d ':' -f 2"))" \
			--host "unix:///var/run/docker.sock"; \
	else \
		$(DOCKER) container inspect --format "{{ .ID }}" "$(*)"; \
	fi
.PHONY: portainer.start

#. Wait for the Portainer container to be running
portainer.ensure:%.ensure: | %.start
	@until test -n "$$($(DOCKER) container ls --quiet --filter "status=running" --filter "name=\b$(*)\b")"; do sleep 1; done
	@until test -n "$$(curl -sSL --fail "http://$$($(DOCKER) container port $(*) 9000)" 2>/dev/null)"; do sleep 1; done
.PHONY: portainer.ensure

#. Setup the Portainer container
portainer.setup:%.setup: | %.ensure
	@AUTHORIZATION="$$( \
		curl -sSL "http://$$($(DOCKER) container port portainer 9000)/api/auth" \
			-X POST \
			--data-raw '{"username":"admin","password":"$(PORTAINER_ADMIN_PASSWORD)"}' \
		| $(JQ) -r '.jwt' \
	)"; \
	$(if $(PORTAINER_LOGO_URL), \
		curl -sSL "http://$$($(DOCKER) container port portainer 9000)/api/settings" \
			-X PUT -H "Authorization: Bearer $${AUTHORIZATION}" \
			--data-raw '{"LogoUrl":"$(PORTAINER_LOGO_URL)"}' > /dev/null; \
	) \
	$(if $(PORTAINER_ADMIN_PASSWORD_LENGTH), \
		curl -sSL "http://$$($(DOCKER) container port portainer 9000)/api/settings" \
			-X PUT -H "Authorization: Bearer $${AUTHORIZATION}" \
			--data-raw '{"InternalAuthSettings":{"RequiredPasswordLength":$(PORTAINER_ADMIN_PASSWORD_LENGTH)}}' > /dev/null; \
	) \
	$(if $(PORTAINER_SESSION_TIMEOUT_IN_HOURS), \
		curl -sSL "http://$$($(DOCKER) container port portainer 9000)/api/settings" \
			-X PUT -H "Authorization: Bearer $${AUTHORIZATION}" \
			--data-raw '{"UserSessionTimeout":"$(PORTAINER_SESSION_TIMEOUT_IN_HOURS)h"}' > /dev/null; \
	) \
	true
.PHONY: portainer.setup

#. List the url to the Portainer container
portainer.list:%.list: | %.ensure
	@printf "Open Portainer (admin/$(PORTAINER_ADMIN_PASSWORD)): http://$$($(DOCKER) container port $(*) 9000)"
.PHONY: portainer.list

#. Stop the Portainer container
portainer.stop:%.stop:
	-@$(DOCKER) container stop
.PHONY: portainer.stop

#. Clear the Portainer container (including the volume)
portainer.clear:%.clear:
	-@$(DOCKER) container rm --force --volumes portainer
	-@$(DOCKER) volume rm --force portainer_data
.PHONY: portainer.clear

#. Reset the Portainer volume (including password)
portainer.reset:%.reset: | %.clear %.start
	@true
.PHONY: portainer.reset

# Run a Portainer container
portainer:%: | %.start %.setup %.list
	@true
.PHONY: portainer
