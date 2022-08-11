###
##. Dependencies
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
## PHP Quality Assurance Tools
###

# Configure Composer with some more strict flags
# @see https://getcomposer.org/doc/06-config.md
composer.configure-strict: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) config optimize-autoloader true
	@$(COMPOSER_EXECUTABLE) config sort-packages true
	@$(COMPOSER_EXECUTABLE) config platform-check true

# Check PHP and extensions versions
# @see https://getcomposer.org/
composer.check-platform-reqs: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) check-platform-reqs

# Validate Composer configuration
# @see https://getcomposer.org/
composer.validate: | $(COMPOSER_DEPENDENCY)
	@$(COMPOSER_EXECUTABLE) validate --strict --no-check-publish --no-interaction
