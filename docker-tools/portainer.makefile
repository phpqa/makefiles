###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

PORTAINER_IMAGE?=cr.portainer.io/portainer/portainer-ce:latest
PORTAINER_ADMIN_PASSWORD?=superpassword
PORTAINER_NETWORK?=

###
## Docker Tools
###

# Start the Portainer container
portainer.start:%.start:
	@if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" "$(*)" 2> /dev/null)"; then \
		$(DOCKER) container run --rm --detach --name "$(*)" \
			--volume "portainer_data:/data" \
			--volume "$(DOCKER_SOCKET):/var/run/docker.sock:ro" \
			--publish "9000" \
			--label "traefik.enable=true" \
			$(if $(PORTAINER_NETWORK),--label "traefik.docker.network=$(PORTAINER_NETWORK)") \
			--label "traefik.http.routers.$(*).entrypoints=web" \
			--label "traefik.http.routers.$(*).rule=Host(\`$(*).localhost\`)" \
			--label "traefik.http.services.$(*).loadbalancer.server.port=9000" \
			$(if $(PORTAINER_NETWORK),--network "$(PORTAINER_NETWORK)") \
			"$(PORTAINER_IMAGE)" \
			--admin-password "$(subst $$,\$$,$(shell $(DOCKER) run --rm httpd:2.4-alpine sh -c "htpasswd -nbB admin '$(PORTAINER_ADMIN_PASSWORD)' | cut -d ':' -f 2"))" \
			--host "unix:///var/run/docker.sock"; \
	else \
		$(DOCKER) container inspect --format "{{ .ID }}" "$(*)"; \
	fi; \
	printf "http://$$($(DOCKER) container port portainer 9000)"
.PHONY: portainer.start

# Stop the Portainer container
portainer.stop:%.stop:
	-@$(DOCKER) stop portainer
.PHONY: portainer.stop

# Reset the Portainer volume (including password)
portainer.reset:%.reset:
	-@$(MAKE) portainer.stop
	-@$(DOCKER) volume rm portainer_data
	@$(MAKE) portainer.start
.PHONY: portainer.reset

#. Start the Portainer container (alias)
portainer: portainer.start
	@true
.PHONY: portainer
