###
##. POSIX dependencies - @see https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html
###

define check-franzl-studio-dependency
ifeq ($$(shell command -v $(1) || which $(1) 2>/dev/null),)
$$(error Please provide the command "$(1)")
endif
endef
$(foreach command,awk,$(eval $(call check-franzl-studio-dependency,$(command))))

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

ifeq ($(filter COMPOSER,$(DOCKER_COMPOSE_RUN_ENVIRONMENT_VARIABLES)),)
DOCKER_COMPOSE_RUN_ENVIRONMENT_VARIABLES+=COMPOSER
endif
ifeq ($(filter COMPOSER,$(DOCKER_COMPOSE_EXEC_ENVIRONMENT_VARIABLES)),)
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

STUDIO_VENDOR_COLOR=
STUDIO_EXTERNAL_COLOR=
# List all packages known by Studio, and where they are being loaded from
studio.list: | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@))
endif
ifeq ($(STUDIO_PACKAGE_DIRECTORIES),)
	$(error Please provide the variable STUDIO_PACKAGE_DIRECTORIES before running $(@))
endif
	@PACKAGES_FILTER="$(subst $(space),\|,$(foreach directory,$(STUDIO_PACKAGE_DIRECTORIES),$(shell $(COMPOSER_EXECUTABLE) --working-dir="$(directory)" show --name-only --self)))"; \
		$(COMPOSER_EXECUTABLE) --no-interaction --no-scripts show --path | grep "$${PACKAGES_FILTER}" | \
		awk ' \
			{ \
				if (index($$2,"vendor")) { printf "$(STUDIO_VENDOR_COLOR)%s$(STYLE_RESET)\n", "Package " $$1 " is being loaded from the vendor directory." } \
				else { printf "$(STUDIO_EXTERNAL_COLOR)%s$(STYLE_RESET)\n", "Package " $$1 " is being loaded from the directory " $$2 "." } \
			} \
		'
.PHONY: studio.list

# Load all packages, to use the code from their local directories
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
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" studio.list STUDIO_VENDOR_COLOR="$(STYLE_ERROR)" STUDIO_EXTERNAL_COLOR="$(STYLE_SUCCESS)"
.PHONY: studio.load

# Unload all packages, to use the code from their vendor dependency
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
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" studio.list STUDIO_VENDOR_COLOR="$(STYLE_SUCCESS)" STUDIO_EXTERNAL_COLOR="$(STYLE_ERROR)"
.PHONY: studio.unload

# List the packages known by Studio, filtered on %, and where they are being loaded from
studio.list-%:
	@STUDIO_PACKAGE_DIRECTORIES="$(strip $(foreach v,$(STUDIO_PACKAGE_DIRECTORIES),$(if $(findstring $(*),$(v)),$(v))))" \
		$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" studio.list

# Load the packages, filtered on %, to use the code from their local directories
studio.load-%:
	@STUDIO_PACKAGE_DIRECTORIES="$(strip $(foreach v,$(STUDIO_PACKAGE_DIRECTORIES),$(if $(findstring $(*),$(v)),$(v))))" \
		$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" studio.load

# Unload the packages, filtered on %, to use the code from their vendor dependency
studio.unload-%:
	@STUDIO_PACKAGE_DIRECTORIES="$(strip $(foreach v,$(STUDIO_PACKAGE_DIRECTORIES),$(if $(findstring $(*),$(v)),$(v))))" \
		$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" studio.unload
