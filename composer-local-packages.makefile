###
##. Configuration
###

COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY?=.cache/studio

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
ifeq ($(PHP_DEPENDENCY),)
$(error The variable PHP_DEPENDENCY should never be empty.)
endif
ifeq ($(COMPOSER_EXECUTABLE),)
$(error The variable COMPOSER_EXECUTABLE should never be empty.)
endif
ifeq ($(COMPOSER_DEPENDENCY),)
$(error The variable COMPOSER_DEPENDENCY should never be empty.)
endif
ifeq ($(COMPOSER),)
$(error The variable COMPOSER should never be empty.)
endif

###
## Composer
###

# Load local packages
composer.load-local-packages: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY) vendor
ifeq ($(COMPOSER_LOCAL_PACKAGE_DIRECTORIES),)
	$(error Please provide the variable COMPOSER_LOCAL_PACKAGE_DIRECTORIES before running $(@).)
endif
ifeq ($(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY),)
	$(error Please provide the variable COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY before running $(@).)
endif
	@$(if $(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY),mkdir -p "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)")
	@cp "$(COMPOSER)" "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"
	@cp "$(patsubst %.json,%.lock,$(COMPOSER))" "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"
	@if test -f "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))"; then \
		cp "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))" "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"; \
	fi
	@COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) config --no-interaction --no-plugins --no-scripts allow-plugins.franzl/studio true
	@if test "$(patsubst %.json,%.lock,$(COMPOSER))" -ot "$(COMPOSER)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Composer is not using the correct file to load Studio. Is the COMPOSER environment variable passed to the PHP container?"; \
		COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) config --unset --no-interaction --no-plugins --no-scripts allow-plugins.franzl/studio; \
		exit 1; \
	fi
	@if test ! -f "vendor/bin/studio"; then \
		COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) require --dev --no-interaction --no-plugins --no-scripts --no-progress franzl/studio; \
	fi
	@$(foreach directory,$(COMPOSER_LOCAL_PACKAGE_DIRECTORIES), \
	COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(PHP) vendor/bin/studio load "$(directory)"; \
	)
	@COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) require --no-interaction --no-scripts --no-progress --optimize-autoloader \
		$(foreach directory,$(COMPOSER_LOCAL_PACKAGE_DIRECTORIES),"$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self):@dev")
	@$(foreach directory,$(COMPOSER_LOCAL_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	PACKAGE_PATH="$$(COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}")"; \
	if printf "$${PACKAGE_PATH}" | grep -q -F "$(directory)"; then \
		printf "$(STYLE_SUCCESS)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is being loaded from $(directory)."; \
	else \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is still being loaded from the vendor directory."; \
	fi; \
	)
.PHONY: composer.load-local-packages

# Unload local packages
composer.unload-local-packages: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_LOCAL_PACKAGE_DIRECTORIES),)
	$(error Could not find any local package directories to load.)
endif
ifeq ($(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY),)
	$(error Please provide the variable COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY before running $(@).)
endif
	@$(if $(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY),mkdir -p "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)")
	@if test ! -f "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)"; then \
		cp "$(COMPOSER)" "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"; \
	fi
	@if test ! -f "$(patsubst %.json,%.lock,$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER))"; then \
		cp "$(patsubst %.json,%.lock,$(COMPOSER))" "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"; \
	fi
	@if test ! -f "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)))"; then \
		if test -f "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))"; then \
			cp "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))" "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"; \
		fi; \
	fi
	@if test -f "vendor/bin/studio"; then \
		$(foreach directory,$(COMPOSER_LOCAL_PACKAGE_DIRECTORIES), \
		COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(PHP) vendor/bin/studio unload "$(directory)"; \
		) \
		COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) remove --dev --no-interaction --no-plugins --no-scripts --no-progress franzl/studio; \
	fi
	@COMPOSER="$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) config --unset --no-interaction --no-plugins --no-scripts allow-plugins.franzl/studio
	@$(COMPOSER_EXECUTABLE) install --no-interaction --no-scripts --no-progress --optimize-autoloader
	@if test -d "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"; then \
		rm -rf "$(COMPOSER_LOCAL_PACKAGES_CACHE_DIRECTORY)/"; \
	fi
	@if test -f "studio.json" && grep -q -F '"paths": []' "studio.json"; then \
		rm -f "studio.json"; \
	fi
	@$(foreach directory,$(COMPOSER_LOCAL_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	PACKAGE_PATH="$$($(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}")"; \
	if printf "$${PACKAGE_PATH}" | grep -q -F "/vendor/"; then \
		printf "$(STYLE_SUCCESS)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is being loaded from the vendor directory."; \
	else \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is still being loaded from the directory $(directory)."; \
	fi; \
	)
.PHONY: composer.unload-local-packages

# List local packages
composer.list-local-packages: | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_LOCAL_PACKAGE_DIRECTORIES),)
	$(error Could not find any local package directories to load.)
endif
	@$(foreach directory,$(COMPOSER_LOCAL_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	$(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}"; \
	)
.PHONY: composer.list-local-packages
