###
##. Configuration
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
## Quality Assurance Tools
###

#. Install PHPStan
vendor/bin/phpstan: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev phpstan/phpstan; fi

# Run PHPStan - Static Analysis Tool
# @see https://github.com/phpstan/phpstan
phpstan: | $(PHP_DEPENDENCY) vendor/bin/phpstan
	@$(PHP) vendor/bin/phpstan --no-interaction analyse .
.PHONY: phpstan

# Generate a baseline for PHPStan
phpstan-baseline.neon: | $(PHP_DEPENDENCY) vendor/bin/phpstan
	@$(PHP) vendor/bin/phpstan --generate-baseline
