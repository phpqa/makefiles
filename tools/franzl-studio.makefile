###
##. Configuration
###

#. Package variables
STUDIO_PACKAGE?=franzl/studio
STUDIO_CACHE_DIRECTORY?=.cache/studio
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
ifeq ($(STUDIO_CACHE_DIRECTORY),)
$(error The variable STUDIO_CACHE_DIRECTORY should never be empty.)
endif

###
## Studio
###

#.! Note: this package is not being installed in the main composer.json file on purpose.

#. Create Studio cache directory
$(STUDIO_CACHE_DIRECTORY):
	@mkdir -p "$(STUDIO_CACHE_DIRECTORY)"

#. Install Studio
vendor/bin/studio:
	@if test -f "$(STUDIO_JSON_FILE)"; then mv "$(STUDIO_JSON_FILE)" "$(STUDIO_JSON_FILE).disabled"; fi
	@$(MAKE) vendor
	@if ! $(COMPOSER_EXECUTABLE) show $(STUDIO_PACKAGE) >/dev/null 2>&1; then \
		$(COMPOSER_EXECUTABLE) config --no-interaction --no-plugins --no-scripts allow-plugins.$(STUDIO_PACKAGE) true; \
		$(COMPOSER_EXECUTABLE) require --dev --no-interaction --no-plugins --no-scripts --no-progress $(STUDIO_PACKAGE); \
	fi
	@if test -f "$(STUDIO_JSON_FILE).disabled"; then mv "$(STUDIO_JSON_FILE).disabled" "$(STUDIO_JSON_FILE)"; fi

# Load the packages
studio.load: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY) vendor/bin/studio $(STUDIO_CACHE_DIRECTORY)
ifeq ($(STUDIO_CACHE_DIRECTORY),)
	$(error Please provide the variable STUDIO_CACHE_DIRECTORY before running $(@).)
endif
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Please provide the variable STUDIO_PACKAGE_DIRECTORIES before running $(@).)
endif
	@cp "$(COMPOSER)" "$(STUDIO_CACHE_DIRECTORY)/"
	@cp "$(patsubst %.json,%.lock,$(COMPOSER))" "$(STUDIO_CACHE_DIRECTORY)/"
	@if test -f "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))"; then \
		cp "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))" "$(STUDIO_CACHE_DIRECTORY)/"; \
	fi
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	COMPOSER="$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER)" $(PHP) vendor/bin/studio load "$(directory)"; \
	)
	@COMPOSER="$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) require --no-interaction --no-scripts --no-progress --optimize-autoloader \
		$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES),"$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self):@dev")
	@if test "$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER)" -ot "$(COMPOSER)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Composer is not updating the correct file. Is the COMPOSER environment variable passed to the PHP container?"; \
		exit 1; \
	fi
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	PACKAGE_PATH="$$(COMPOSER="$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER)" $(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}")"; \
	if printf "$${PACKAGE_PATH}" | grep -q -F "$(directory)"; then \
		printf "$(STYLE_SUCCESS)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is being loaded from $(directory)."; \
	else \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "Package $${PACKAGE} is still being loaded from the vendor directory."; \
	fi; \
	)
.PHONY: studio.load

# Unload the packages
studio.unload: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY) vendor/bin/studio $(STUDIO_CACHE_DIRECTORY)
ifeq ($(STUDIO_CACHE_DIRECTORY),)
	$(error Please provide the variable STUDIO_CACHE_DIRECTORY before running $(@).)
endif
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Could not find any local package directories to load.)
endif
	@if test ! -f "$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER)"; then \
		cp "$(COMPOSER)" "$(STUDIO_CACHE_DIRECTORY)/"; \
	fi
	@if test ! -f "$(patsubst %.json,%.lock,$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER))"; then \
		cp "$(patsubst %.json,%.lock,$(COMPOSER))" "$(STUDIO_CACHE_DIRECTORY)/"; \
	fi
	@if test ! -f "$(subst composer,symfony,$(patsubst %.json,%.lock,$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER)))"; then \
		if test -f "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))"; then \
			cp "$(subst composer,symfony,$(patsubst %.json,%.lock,$(COMPOSER)))" "$(STUDIO_CACHE_DIRECTORY)/"; \
		fi; \
	fi
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	if test -f "$(STUDIO_JSON_FILE)" && grep --quiet "$(directory)" "$(STUDIO_JSON_FILE)"; then \
		COMPOSER="$(STUDIO_CACHE_DIRECTORY)/$(COMPOSER)" $(PHP) vendor/bin/studio unload "$(directory)"; \
	fi; \
	)
	@$(COMPOSER_EXECUTABLE) install --no-interaction --no-scripts --no-progress --optimize-autoloader
	@if test -d "$(STUDIO_CACHE_DIRECTORY)/"; then \
		rm -rf "$(STUDIO_CACHE_DIRECTORY)/"; \
	fi
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
