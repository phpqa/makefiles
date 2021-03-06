###
##. Configuration
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
## PHP Quality Assurance Tools
###

# Validate Composer configuration
# @see https://getcomposer.org/
composer.validate: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) validate --strict --no-check-publish --no-interaction

# Check PHP and extensions versions
# @see https://getcomposer.org/
composer.check-platform-reqs: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) check-platform-reqs
