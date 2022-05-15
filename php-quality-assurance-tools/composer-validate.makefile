###
##. Configuration
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
## Quality Assurance Tools
## Composer - A Dependency Manager for PHP
## @see https://getcomposer.org/
###

# Validate Composer
composer.validate: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) validate --no-check-publish
