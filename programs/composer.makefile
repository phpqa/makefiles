###
##. Dependencies
###

#. POSIX dependencies - @see https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html
define check-composer-dependency
ifeq ($$(shell command -v $(1) || which $(1) 2>/dev/null),)
$$(error Please provide the command "$(1)")
endif
endef
$(foreach command,touch ln chmod rm,$(eval $(call check-composer-dependency,$(command))))

ifeq ($(PHP),)
$(warning Please provide the variable PHP)
endif

###
##. Configuration
###

#.! Note: the environment variable COMPOSER is already used by Composer to locate the composer.json file
COMPOSER_DIRECTORY?=.

COMPOSER_DEPENDENCY?=$(strip $(if $(findstring bin/composer,$(COMPOSER_EXECUTABLE)),$(PHP_DEPENDENCY) bin/composer) composer.assure-usable)
ifeq ($(COMPOSER_DEPENDENCY),)
$(error The variable COMPOSER_DEPENDENCY should never be empty)
endif

COMPOSER_EXECUTABLE?=$(if $(findstring $(COMPOSER),composer.json),,COMPOSER="$(COMPOSER)" )$(PHP) $(if $(wildcard $(filter-out .,$(COMPOSER_DIRECTORY))),$(COMPOSER_DIRECTORY)/)bin/composer
ifeq ($(COMPOSER_EXECUTABLE),)
$(error The variable COMPOSER_EXECUTABLE should never be empty)
endif

COMPOSER?=composer.json
ifeq ($(COMPOSER),)
$(error The variable COMPOSER should never be empty)
endif
COMPOSER_LOCK?=$(patsubst %.json,%.lock,$(COMPOSER))

COMPOSER_DOCKER_IMAGE?=composer
COMPOSER_VERSION?=
COMPOSER_VENDOR_DIRECTORY?=vendor

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
COMPOSER_BUMP_FLAGS+=

###
##. Composer
##. A Dependency Manager for PHP
##. @see https://getcomposer.org/
###

#. Assure that COMPOSER_EXECUTABLE is usable
composer.assure-usable:
	@if test -z "$$($(COMPOSER_EXECUTABLE) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use COMPOSER_EXECUTABLE as "$(value COMPOSER_EXECUTABLE)".'; \
		$(COMPOSER_EXECUTABLE) --version; \
		exit 1; \
	fi
.PHONY: composer.assure-usable

ifneq ($(DOCKER_DETECTED),)
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | $(DOCKER_DEPENDENCY)
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@$(if $(COMPOSER_VERSION),if test -L "bin/composer" || test -f "bin/composer"; then rm -f "bin/composer"; fi)
	@$(DOCKER) image pull $(COMPOSER_DOCKER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@$(DOCKER) run --rm --init --pull=missing --volume "$(shell pwd)":"/app" --workdir "/app" $(COMPOSER_DOCKER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION)) cat /usr/bin/composer > "$(@)"
	@$(DOCKER) image rm $(COMPOSER_DOCKER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@if test ! -f "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The \"$(@)\" file is not present. Something went wrong."; \
	else \
		chmod +x "$(@)"; \
	fi
else
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | $(PHP_DEPENDENCY)
ifeq ($(PHP),)
	$(error Please provide the variable PHP before running $(@))
endif
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@$(if $(COMPOSER_VERSION),if test -L "bin/composer" || test -f "bin/composer"; then rm -f "bin/composer"; fi)
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
	@if test ! -f "$(@)"; then \
		$(COMPOSER_EXECUTABLE) init $(COMPOSER_INIT_FLAGS); \
	fi

#. Build the composer.lock file
$(COMPOSER_LOCK): $(COMPOSER) | $(COMPOSER_DEPENDENCY)
	@if test ! -f "$(@)"; then \
		$(COMPOSER_EXECUTABLE) install $(COMPOSER_INSTALL_FLAGS); \
	else \
		if test "$(@)" -ot "$(<)"; then \
			$(COMPOSER_EXECUTABLE) update $(COMPOSER_UPDATE_FLAGS) --lock; \
		fi; \
	fi
	@if test ! -f "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The \"$(@)\" file is not present. Something went wrong."; \
	else \
		touch "$(@)"; \
	fi

#. Build the dependencies directory
$(COMPOSER_VENDOR_DIRECTORY): $(COMPOSER_LOCK) | $(COMPOSER_DEPENDENCY)
	@if test ! -d "$(@)"; then \
		$(COMPOSER_EXECUTABLE) install $(COMPOSER_INSTALL_FLAGS); \
	else \
		if test ! -d "$(@)" || test "$(@)" -ot "$(<)"; then \
			$(COMPOSER_EXECUTABLE) install $(COMPOSER_INSTALL_FLAGS); \
		fi; \
	fi
	@if test ! -d "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" "The \"$(@)\" directory is not present. Something went wrong."; \
	else \
		touch "$(@)"; \
	fi

#. (internal) Untouch the Composer related files - set last modified date back to latest git commit
composer.untouch: | $(GIT_DEPENDENCY)
ifeq ($(GIT),)
	$(error Please provide the variable GIT before running $(@))
endif
	@$(foreach file,$(COMPOSER) $(COMPOSER_LOCK), \
	touch -d "$$($(GIT) log --pretty=format:%ci -1 "HEAD" -- "$(file)")" "$(file)"; \
	printf "%s: %s\n" "$(file)" "$$(date -r "$(file)" +"%Y-%m-%d %H:%M:%S")"; \
	)

# Configure Composer with some more strict flags
# @see https://getcomposer.org/doc/06-config.md
composer.configure-strict: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) config optimize-autoloader true
	@$(COMPOSER_EXECUTABLE) config sort-packages true
	@$(COMPOSER_EXECUTABLE) config platform-check true
.PHONY: composer.configure-strict

###
##. Composer commands
###

# Initialize the project dependencies
# @see https://getcomposer.org/doc/03-cli.md#init
composer.init: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) init $(COMPOSER_INIT_FLAGS)
.PHONY: composer.init

# Install the project dependencies
# @see https://getcomposer.org/doc/03-cli.md#install-i
composer.install: $(COMPOSER_LOCK) | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) install $(COMPOSER_INSTALL_FLAGS)
.PHONY: composer.install

# Update the project dependencies
# @see https://getcomposer.org/doc/03-cli.md#update-u
composer.update: $(COMPOSER_LOCK) | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) update $(COMPOSER_UPDATE_FLAGS)
.PHONY: composer.update

# Update only the lock file
# @see https://getcomposer.org/doc/03-cli.md#update-u
composer.update-lock: $(COMPOSER_LOCK) | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) update --lock $(COMPOSER_UPDATE_FLAGS)
.PHONY: composer.update-lock

# Bump the lower limit of the composer.json requirements to the currently installed versions
# @see https://getcomposer.org/doc/03-cli.md#bump
composer.bump: $(COMPOSER_LOCK) | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) bump $(COMPOSER_BUMP_FLAGS)
.PHONY: composer.bump

# Bump the lower limit of the composer.json requirements to the currently installed versions
# @see https://getcomposer.org/doc/03-cli.md#bump
composer.bump.dryrun: $(COMPOSER_LOCK) | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) bump --dry-run $(COMPOSER_BUMP_FLAGS)
.PHONY: composer.bump.dryrun
