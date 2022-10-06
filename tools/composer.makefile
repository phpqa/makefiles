###
##. Dependencies
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(warning Please provide the variable COMPOSER_EXECUTABLE)
endif

###
##. Configuration
###

COMPOSER_CHECK_PLATFORM_REQS_FLAGS+=
COMPOSER_VALIDATE_FLAGS+=--no-check-publish --no-interaction

###
##. Composer
##. A Dependency Manager for PHP
##. @see https://getcomposer.org/
###

# Check the PHP and extensions versions
# @see https://getcomposer.org/doc/03-cli.md#check-platform-reqs
composer.check-platform-reqs: | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE)
endif
	@$(COMPOSER_EXECUTABLE) check-platform-reqs $(COMPOSER_CHECK_PLATFORM_REQS_FLAGS)
.PHONY: composer.check-platform-reqs
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=composer.check-platform-reqs

# Validate the Composer configuration
# @see https://getcomposer.org/doc/03-cli.md#validate
composer.validate: | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE)
endif
	@$(COMPOSER_EXECUTABLE) validate $(COMPOSER_VALIDATE_FLAGS)
.PHONY: composer.validate
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=composer.validate
