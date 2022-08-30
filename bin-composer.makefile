###
##. Dependencies
###

#. POSIX dependencies - @see https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html
define check-bin-composer-command
ifeq ($$(shell command -v $(1) || which $(1) 2>/dev/null),)
$$(error Please provide the command "$(1)" before including the "managed-files.makefile" file)
endif
endef
$(foreach command,touch ln chmod rm,$(eval $(call check-bin-composer-command,$(command))))

###
##. Configuration
###

#.! Note: the environment variable COMPOSER is already used by Composer to locate the composer.json file
COMPOSER_DIRECTORY?=.
COMPOSER_DEPENDENCY?=$(PHP_DEPENDENCY) bin/composer composer.assure-usable
COMPOSER_EXECUTABLE?=$(if $(findstring $(COMPOSER),composer.json),,COMPOSER="$(COMPOSER)" )$(PHP) $(if $(wildcard $(filter-out .,$(COMPOSER_DIRECTORY))),$(COMPOSER_DIRECTORY)/)bin/composer
COMPOSER_VENDOR_DIRECTORY?=vendor

COMPOSER?=composer.json

COMPOSER_IMAGE?=composer
COMPOSER_VERSION?=

#. Building the flags
ifeq ($(findstring --name,$(COMPOSER_INIT_FLAGS)),)
COMPOSER_INIT_FLAGS+=--name "$(shell whoami)/$(notdir $(shell pwd))"
endif
ifeq ($(findstring --description,$(COMPOSER_INIT_FLAGS)),)
COMPOSER_INIT_FLAGS+=--description "new project"
endif
ifeq ($(findstring --license,$(COMPOSER_INIT_FLAGS)),)
COMPOSER_INIT_FLAGS+=--license "proprietary"
endif
COMPOSER_INIT_FLAGS+=--no-interaction
COMPOSER_INSTALL_FLAGS+=
COMPOSER_UPDATE_FLAGS+=

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

#. Assure that Composer is usable
composer.assure-usable:
	@if test -z "$$($(COMPOSER_EXECUTABLE) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use COMPOSER_EXECUTABLE as "$(value COMPOSER_EXECUTABLE)".'; \
		exit 1; \
	fi
.PHONY: composer.assure-usable

ifneq ($(DOCKER),)
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | $(DOCKER_DEPENDENCY)
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@$(if $(COMPOSER_VERSION),if test -L "bin/composer" || test -f "bin/composer"; then rm -f "bin/composer"; fi)
	@$(DOCKER) image pull $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@$(DOCKER) run --rm --init --pull=missing --volume "$(shell pwd)":"/app" --workdir "/app" $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION)) cat /usr/bin/composer > "$(@)"
	@$(DOCKER) image rm $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@if test ! -f "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The \"$(@)\" file is not present. Something went wrong."; \
	else \
		chmod +x "$(@)"; \
	fi
else
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | $(PHP_DEPENDENCY)
ifeq ($(PHP),)
	$(error Please provide the variable PHP before running $(@).)
endif
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@$(if $(COMPOSER_VERSION),if test -L "bin/composer" || -f "bin/composer"; then rm -f "bin/composer"; fi)
	@$(PHP) -r "file_put_contents('setup.php', fopen('https://getcomposer.org/installer', 'r'), LOCK_EX);"
	@$(PHP) -r "file_put_contents('setup.sig', fopen('https://composer.github.io/installer.sig', 'r'), LOCK_EX);"
	@$(PHP) -r " \
		if (hash_file('SHA384', 'setup.php') !== trim(file_get_contents('setup.sig'))) { \
			echo 'Installer corrupt'; \
			unlink('setup.php'); \
			unlink('setup.sig'); \
			echo PHP_EOL; \
		} \
	"
	@if test ! -d "$(dir $(@))"; then $(PHP) -r "mkdir('$(dir $(@))', 0777, true);"; fi
	@$(PHP) setup.php --no-ansi --install-dir=$(dir $(@)) --filename=$(notdir $(@))$(if $(COMPOSER_VERSION), --version=$(COMPOSER_VERSION))
	@$(PHP) -r "unlink('setup.php');"
	@$(PHP) -r "unlink('setup.sig');"
	@if test ! -f "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The \"$(@)\" file is not present. Something went wrong."; \
	else \
		chmod +x "$(@)"; \
	fi
endif

ifneq ($(COMPOSER_VERSION),)
# Download Composer to bin/composer
bin/composer: bin/composer-$(COMPOSER_VERSION)
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@if test -L "$(@)"; then rm -f "$(@)"; fi
	@ln -s "$(notdir $(<))" "$(@)"
endif

#. Create a composer.json file
$(COMPOSER): | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@).)
endif
	@if test ! -f "$(@)"; then \
		$(COMPOSER_EXECUTABLE) init $(or $(COMPOSER_INIT_FLAGS)); \
	fi

#. Build the composer.lock file
$(patsubst %.json,%.lock,$(COMPOSER)): $(COMPOSER) | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@).)
endif
	@if test ! -f "$(@)"; then \
		$(COMPOSER_EXECUTABLE) install $(or $(COMPOSER_INSTALL_FLAGS)); \
	else \
		if test "$(@)" -ot "$(<)"; then \
			$(COMPOSER_EXECUTABLE) update $(or $(COMPOSER_UPDATE_FLAGS)) --lock; \
		fi; \
	fi
	@if test ! -f "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The \"$(@)\" file is not present. Something went wrong."; \
	else \
		touch "$(@)"; \
	fi

#. Build the dependencies directory
$(COMPOSER_VENDOR_DIRECTORY): $(patsubst %.json,%.lock,$(COMPOSER)) | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@).)
endif
	@if test ! -d "$(@)"; then \
		$(COMPOSER_EXECUTABLE) install $(or $(COMPOSER_INSTALL_FLAGS)); \
	else \
		if test ! -d "$(@)" || test "$(@)" -ot "$(<)"; then \
			$(COMPOSER_EXECUTABLE) install $(or $(COMPOSER_INSTALL_FLAGS)); \
		fi; \
	fi
	@if test ! -d "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The \"$(@)\" directory is not present. Something went wrong."; \
	else \
		touch "$(@)"; \
	fi

# Install the project dependencies
composer.install: $(patsubst %.json,%.lock,$(COMPOSER)) | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@).)
endif
	@$(COMPOSER_EXECUTABLE) install $(or $(COMPOSER_INSTALL_FLAGS))
.PHONY: composer.install

# Update the project dependencies
composer.update: $(patsubst %.json,%.lock,$(COMPOSER)) | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@).)
endif
	@$(COMPOSER_EXECUTABLE) update $(or $(COMPOSER_UPDATE_FLAGS))
.PHONY: composer.update

# Update only the lock file
composer.update-lock: $(patsubst %.json,%.lock,$(COMPOSER)) | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE before running $(@).)
endif
	@$(COMPOSER_EXECUTABLE) update $(or $(COMPOSER_UPDATE_FLAGS)) --lock
.PHONY: composer.update-lock

#. (internal) Untouch the Composer related files - set last modified date back to latest git commit
composer.untouch:
	@$(foreach file,$(COMPOSER) $(patsubst %.json,%.lock,$(COMPOSER)), \
	touch -d "$$(git log --pretty=format:%ci -1 "HEAD" -- "$(file)")" "$(file)"; \
	printf "%s: %s\n" "$(file)" "$$(date -r "$(file)" +"%Y-%m-%d %H:%M:%S")"; \
	)
