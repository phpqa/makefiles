###
##. Configuration
###

ifeq ($(DOCKER_SOCKET),)
$(error Please provide the variable DOCKER_SOCKET before including this file.)
endif

ifeq ($(DOCKER),)
$(error Please provide the variable DOCKER before including this file.)
endif

PORTAINER_ADMIN_PASSWORD?=superpassword

###
## Docker Tools
###

# Start the Portainer container
start-portainer:start-%:
	@ID=""; \
	if test -z "$$($(DOCKER) container inspect --format "{{ .ID }}" portainer 2> /dev/null)"; then \
		$(DOCKER) container run --rm --detach --name portainer \
			--volume "portainer_data:/data" \
			--volume "$(DOCKER_SOCKET):$(DOCKER_SOCKET):ro" \
			--publish "9000" \
			cr.portainer.io/portainer/portainer-ce \
			--admin-password "$(subst $$,\$$,$(shell $(DOCKER) run --rm httpd:2.4-alpine sh -c "htpasswd -nbB admin '$(PORTAINER_ADMIN_PASSWORD)' | cut -d ':' -f 2"))" \
			--host=unix://$(DOCKER_SOCKET); \
	else \
		$(DOCKER) container inspect --format "{{ .ID }}" portainer; \
	fi
	@printf "http://$$($(DOCKER) container port portainer 9000)"

# Stop the Portainer container
stop-portainer:stop-%:
	-@$(DOCKER) stop portainer

# Reset the Portainer volume (including password)
reset-portainer:reset-%:
	-@$(MAKE) stop-portainer
	-@$(DOCKER) volume rm portainer_data
	@$(MAKE) start-portainer
