###
##. Configuration
###

PHP?=$(if $(wildcard bin/php),bin/php,$(shell command -v php || which php 2>/dev/null))
ifeq ($(PHP),)
$(error Please install php.)
endif

# ! Note: the environment variable COMPOSER is used by Composer to locate the composer.json file
COMPOSER_EXECUTABLE?=$(if $(wildcard bin/composer),bin/composer,$(shell command -v composer || which composer 2>/dev/null))
ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install composer.)
endif

###
## Quality Assurance Tools
###

.PHONY: phpstan rector phpunit

#. Install PHPStan
vendor/bin/phpstan: | vendor
	@if test ! -f "$(@)"; then $(PHP) $(COMPOSER_EXECUTABLE) require --dev phpstan/phpstan; fi

# Run PHPStan - Static Analysis Tool         https://github.com/phpstan/phpstan
phpstan: | vendor/bin/phpstan
	@$(PHP) vendor/bin/phpstan --no-interaction analyse .

# Generate a baseline for PHPStan
phpstan-baseline.neon: | vendor/bin/phpstan
	@$(PHP) vendor/bin/phpstan --generate-baseline

#. Install Rector
vendor/bin/rector: | vendor
	@if test ! -f "$(@)"; then $(PHP) $(COMPOSER_EXECUTABLE) require --dev rector/rector; fi

#. Initialize Rector
rector.php: | vendor/bin/rector
	@$(PHP) vendor/bin/rector init

# Run Rector - Upgrades and Refactoring     https://github.com/rectorphp/rector
rector: | vendor/bin/rector rector.php
	@$(PHP) vendor/bin/rector process tests

#. Install PHPUnit
vendor/bin/phpunit: | vendor
	@if test ! -f "$(@)"; then $(PHP) $(COMPOSER_EXECUTABLE) require --dev phpunit/phpunit; fi

#. Initialize PHPUnit
phpunit.xml.dist: | vendor/bin/phpunit
	@true

# Run PHPUnit - Testing Framework for PHP                   https://phpunit.de/
phpunit: | vendor/bin/phpunit phpunit.xml.dist
	@$(PHP) vendor/bin/phpunit
