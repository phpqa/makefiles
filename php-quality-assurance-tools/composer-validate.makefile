###
##. Configuration
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
## PHP Quality Assurance Tools
###

# Validate Composer
# @see https://getcomposer.org/
composer.validate: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) validate --strict --no-check-publish --no-interaction
