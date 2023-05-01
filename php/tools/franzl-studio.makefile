###
##. Dependencies
###

ifeq ($(PHP),)
$(warning Please provide the variable PHP)
endif
ifeq ($(COMPOSER_EXECUTABLE),)
$(warning Please provide the variable COMPOSER_EXECUTABLE)
endif
ifeq ($(GIT),)
$(warning Please provide the variable GIT)
endif
ifeq ($(JQ),)
$(warning Please provide the variable JQ)
endif

###
##. Configuration
###

#. Package variables
STUDIO_PACKAGE?=franzl/studio
ifeq ($(STUDIO_PACKAGE),)
$(error The variable STUDIO_PACKAGE should never be empty)
endif

STUDIO?=$(or $(PHP),php) vendor/bin/php-cs-fixer
ifeq ($(STUDIO),)
$(error The variable STUDIO should never be empty)
endif

ifeq ($(STUDIO),$(or $(PHP),php) vendor/bin/php-cs-fixer)
STUDIO_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/php-cs-fixer
else
STUDIO_DEPENDENCY?=$(wildcard $(STUDIO))
endif
ifeq ($(STUDIO_DEPENDENCY),)
$(error The variable STUDIO_DEPENDENCY should never be empty)
endif

#. Tool variables
STUDIO_JSON_FILE?=studio.json
STUDIO_PACKAGE_DIRECTORIES?=

ifeq ($(findstring COMPOSER,$(DOCKER_COMPOSE_RUN_ENVIRONMENT_VARIABLES)),)
DOCKER_COMPOSE_RUN_ENVIRONMENT_VARIABLES+=COMPOSER
endif
ifeq ($(findstring COMPOSER,$(DOCKER_COMPOSE_EXEC_ENVIRONMENT_VARIABLES)),)
DOCKER_COMPOSE_EXEC_ENVIRONMENT_VARIABLES+=COMPOSER
endif

###
##. Studio
##. A workbench for developing Composer packages
##. @see https://github.com/franzliedke/studio
###

ifneq ($(COMPOSER_EXECUTABLE),)
#. Install Studio
vendor/bin/studio: | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@))
endif
	@if test -f "$(STUDIO_JSON_FILE)"; then mv "$(STUDIO_JSON_FILE)" "$(STUDIO_JSON_FILE).disabled"; fi
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" vendor
	@if ! $(COMPOSER_EXECUTABLE) show $(STUDIO_PACKAGE) >/dev/null 2>&1; then \
		$(COMPOSER_EXECUTABLE) config --no-interaction --no-plugins --no-scripts allow-plugins.$(STUDIO_PACKAGE) true; \
		$(COMPOSER_EXECUTABLE) require --dev --no-interaction --no-plugins --no-scripts --no-progress $(STUDIO_PACKAGE); \
	fi
	@if test -f "$(STUDIO_JSON_FILE).disabled"; then mv "$(STUDIO_JSON_FILE).disabled" "$(STUDIO_JSON_FILE)"; fi
endif

# Load the packages
studio.load: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY) $(STUDIO_DEPENDENCY)
ifeq ($(PHP),)
	$(error Please provide the variable PHP)
endif
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@))
endif
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Please provide the variable STUDIO_PACKAGE_DIRECTORIES before running $(@))
endif
	@$(PHP) vendor/bin/studio load $(STUDIO_PACKAGE_DIRECTORIES)
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
studio.unload: | $(PHP_DEPENDENCY) $(COMPOSER_DEPENDENCY) $(GIT_DEPENDENCY) $(JQ_DEPENDENCY) $(STUDIO_DEPENDENCY)
ifeq ($(PHP),)
	$(error Please provide the variable PHP)
endif
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@))
endif
ifeq ($(GIT),)
	$(error Please provide the variable GIT)
endif
ifeq ($(JQ),)
	$(error Please provide the variable JQ)
endif
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Please provide the variable STUDIO_PACKAGE_DIRECTORIES before running $(@))
endif
	@if test -f "$(STUDIO_JSON_FILE)"; then $(PHP) vendor/bin/studio unload $(STUDIO_PACKAGE_DIRECTORIES); fi
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
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@))
endif
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Please provide the variable STUDIO_PACKAGE_DIRECTORIES before running $(@))
endif
	@$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES), \
	PACKAGE="$$($(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)"; \
	$(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path "$${PACKAGE}"; \
	)
.PHONY: studio.list
