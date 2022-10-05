###
##. Configuration
###

#. Package variables
STUDIO_PACKAGE?=franzl/studio
STUDIO_JSON_FILE?=studio.json
STUDIO_PACKAGE_DIRECTORIES?=

ifeq ($(findstring COMPOSER,$(DOCKER_COMPOSE_RUN_ENVIRONMENT_VARIABLES)),)
DOCKER_COMPOSE_RUN_ENVIRONMENT_VARIABLES+=COMPOSER
endif
ifeq ($(findstring COMPOSER,$(DOCKER_COMPOSE_EXEC_ENVIRONMENT_VARIABLES)),)
DOCKER_COMPOSE_EXEC_ENVIRONMENT_VARIABLES+=COMPOSER
endif

###
##. Requirements
###

ifeq ($(PHP),)
$(error The variable PHP should never be empty.)
endif
ifeq ($(COMPOSER_EXECUTABLE),)
$(error The variable COMPOSER_EXECUTABLE should never be empty.)
endif
ifeq ($(GIT),)
$(error The variable GIT should never be empty.)
endif
ifeq ($(JQ),)
$(error The variable JQ should never be empty.)
endif

###
## Studio
###

#. Install Studio
vendor/bin/studio: | $(COMPOSER_DEPENDENCY)
	@if test -f "$(STUDIO_JSON_FILE)"; then mv "$(STUDIO_JSON_FILE)" "$(STUDIO_JSON_FILE).disabled"; fi
	@$(MAKE) vendor
	@if ! $(COMPOSER_EXECUTABLE) show $(STUDIO_PACKAGE) >/dev/null 2>&1; then \
		$(COMPOSER_EXECUTABLE) config --no-interaction --no-plugins --no-scripts allow-plugins.$(STUDIO_PACKAGE) true; \
		$(COMPOSER_EXECUTABLE) require --dev --no-interaction --no-plugins --no-scripts --no-progress $(STUDIO_PACKAGE); \
	fi
	@if test -f "$(STUDIO_JSON_FILE).disabled"; then mv "$(STUDIO_JSON_FILE).disabled" "$(STUDIO_JSON_FILE)"; fi

# Load the packages
studio.load: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY) vendor/bin/studio
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Please provide the variable STUDIO_PACKAGE_DIRECTORIES before running $(@).)
endif
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	$(PHP) vendor/bin/studio load "$(directory)"; \
	)
	@$(COMPOSER_EXECUTABLE) require --no-interaction --no-scripts --no-progress --optimize-autoloader \
		$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES),"$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self):@dev")
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	PACKAGE_PATH="$$($(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}")"; \
	if printf "$${PACKAGE_PATH}" | grep -q -F "$(directory)"; then \
		printf "$(STYLE_SUCCESS)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is being loaded from $(directory)."; \
	else \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is still being loaded from the vendor directory."; \
	fi; \
	)
.PHONY: studio.load

# Unload the packages
studio.unload: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY) $(GIT_DEPENDENCY) $(JQ_DEPENDENCY) vendor/bin/studio
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Could not find any local package directories to load.)
endif
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	if test -f "$(STUDIO_JSON_FILE)" && grep --quiet "$(directory)" "$(STUDIO_JSON_FILE)"; then \
		$(PHP) vendor/bin/studio unload "$(directory)"; \
	fi; \
	)
	@JQ_REQUIRE_FILTER="$$($(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES),PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; printf "%s" "\"$${PACKAGE}:\" + .require.\"$${PACKAGE}\" + \" \" + ";)) \"\""; \
		REQUIRE_CONSTRAINTS="$$($(GIT) cat-file -p $$($(GIT) rev-parse HEAD):$(or $(COMPOSER),composer.json) | $(JQ) -r "$${JQ_REQUIRE_FILTER}")"; \
		JQ_UPDATE_NAME_FILTER="$$($(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES),PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; printf "%s" ".name==\"$${PACKAGE}\",";) printf "%s" "false")"; \
		JQ_UPDATE_FILTER="(.packages|map(select($${JQ_UPDATE_NAME_FILTER})|.name + \" --with \" + .name + \":\" + .version)|join(\" \"))"; \
		UPDATE_CONSTRAINTS="$$($(GIT) cat-file -p $$($(GIT) rev-parse HEAD):$(patsubst %.json,%.lock,$(or $(COMPOSER),composer.json)) | $(JQ) -r "$${JQ_UPDATE_FILTER}")"; \
		$(COMPOSER_EXECUTABLE) require --no-interaction --no-scripts --no-progress --no-install --no-update $${REQUIRE_CONSTRAINTS}; \
		$(COMPOSER_EXECUTABLE) update --no-interaction --no-scripts --no-progress --optimize-autoloader $${UPDATE_CONSTRAINTS}
	@if test -f "$(STUDIO_JSON_FILE)" && grep -q -F '"paths": []' "$(STUDIO_JSON_FILE)"; then \
		rm -f "$(STUDIO_JSON_FILE)"; \
	fi
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	PACKAGE_PATH="$$($(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}")"; \
	if printf "$${PACKAGE_PATH}" | grep -q -F "/vendor/"; then \
		printf "$(STYLE_SUCCESS)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is being loaded from the vendor directory."; \
	else \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is still being loaded from the directory $(directory)."; \
	fi; \
	)
.PHONY: studio.unload

# List the packages
studio.list: | $(COMPOSER_DEPENDENCY)
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Could not find any package directories to load.)
endif
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	$(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}"; \
	)
.PHONY: studio.list
