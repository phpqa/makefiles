###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install php.)
endif

COMPOSER_IMAGE?=composer
COMPOSER_VERSION?=

#. Provide the COMPOSER_EXECUTABLE variable as installed by this file
#.! Note: the environment variable COMPOSER is already used by Composer to locate the composer.json file
COMPOSER_EXECUTABLE?=$(PHP) bin/composer
ifeq ($(COMPOSER_EXECUTABLE),$(PHP) bin/composer)
COMPOSER_DEPENDENCY?=$(PHP_DEPENDENCY) bin/composer
else
COMPOSER_DEPENDENCY?=$(wildcard $(COMPOSER_EXECUTABLE))
endif

###
## Composer
###

ifneq ($(DOCKER),)
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | $(wildcard $(DOCKER))
	@if test ! -d "$(dir $(@))"; then mkdir -p "$(dir $(@))"; fi
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@$(if $(COMPOSER_VERSION),if test -L "bin/composer" || -f "bin/composer"; then rm -f "bin/composer"; fi)
	@$(DOCKER) image pull $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@$(DOCKER) run --rm --init --pull=missing --volume "$(CWD)":"/app" --workdir "/app" $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION)) cat /usr/bin/composer > "$(@)"
	@$(DOCKER) image rm $(COMPOSER_IMAGE)$(if $(COMPOSER_VERSION),:$(COMPOSER_VERSION))
	@chmod +x "$(@)"
else
#. Download Composer to bin/composer or bin/composer-COMPOSER_VERSION
bin/composer$(if $(COMPOSER_VERSION),-$(COMPOSER_VERSION)): | $(PHP_DEPENDENCY)
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
	@chmod +x "$(@)"
endif

ifneq ($(COMPOSER_VERSION),)
# Download Composer to bin/composer
bin/composer: bin/composer-$(COMPOSER_VERSION)
	@if test -f "$(@)"; then rm -f "$(@)"; fi
	@if test -L "$(@)"; then rm -f "$(@)"; fi
	@ln -s "$(notdir $(<))" "$(@)"
endif

# Create a composer.json file
composer.json: | $(COMPOSER_DEPENDENCY)
	@if test ! -f "$(@)"; then \
		$(COMPOSER_EXECUTABLE) init --no-interaction --name vendor/project; \
	fi

# Build the composer.lock file
composer.lock: composer.json | $(COMPOSER_DEPENDENCY)
	@if test ! -f "$(@)"; then \
		$(COMPOSER_EXECUTABLE) install --no-progress; \
	else \
		$(COMPOSER_EXECUTABLE) update --lock; \
		touch "$(@)"; \
	fi

# Build the vendor directory
vendor: composer.lock | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) install --no-progress --no-suggest
	@touch "$(@)"
