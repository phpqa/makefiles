###
##. Configuration
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
## Quality Assurance Tools
###

# Validate Composer - Dependency Manager for PHP
# @see https://getcomposer.org/
composer.validate: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) validate --strict --no-check-publish --no-interaction
