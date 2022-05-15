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

#. Install PHPUnit
vendor/bin/phpunit: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev phpunit/phpunit; fi

#. Initialize PHPUnit
phpunit.xml.dist: | $(PHP_DEPENDENCY) vendor/bin/phpunit
	@true

# Run PHPUnit - Programmer-oriented Testing Framework for PHP
# @see https://phpunit.de/
phpunit: | $(PHP_DEPENDENCY) vendor/bin/phpunit phpunit.xml.dist
	@$(PHP) vendor/bin/phpunit
.PHONY: phpunit
