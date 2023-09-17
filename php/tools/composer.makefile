###
##. Dependencies
###

ifeq ($(COMPOSER_EXECUTABLE),)
$(warning Please provide the variable COMPOSER_EXECUTABLE)
endif

###
##. Configuration
###

COMPOSER_CHECK_PLATFORM_REQS_FLAGS?=
COMPOSER_VALIDATE_FLAGS?=--no-check-publish --no-interaction
COMPOSER_OUTDATED_FLAGS?=--direct --locked --no-dev
COMPOSER_AUDIT_FLAGS?=

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

# Validate the composer.json file
# @see https://getcomposer.org/doc/03-cli.md#validate
composer.validate.strict: | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE)
endif
	@$(COMPOSER_EXECUTABLE) validate --strict $(COMPOSER_VALIDATE_FLAGS)
.PHONY: composer.validate-strict

# List available updates
# @see https://getcomposer.org/doc/03-cli.md#outdated
composer.outdated: | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE)
endif
	@$(COMPOSER_EXECUTABLE) outdated $(COMPOSER_OUTDATED_FLAGS)
.PHONY: composer.outdated

# List available minor version updates
# @see https://getcomposer.org/doc/03-cli.md#outdated
composer.outdated-minor: COMPOSER_OUTDATED_FLAGS+=--minor-only
composer.outdated-minor: composer.outdated; @true
.PHONY: composer.outdated-minor

# List available major version updates
# @see https://getcomposer.org/doc/03-cli.md#outdated
composer.outdated-major: COMPOSER_OUTDATED_FLAGS+=--major-only
composer.outdated-major: composer.outdated; @true
.PHONY: composer.outdated-major

# List available minor version updates
# @see https://getcomposer.org/doc/03-cli.md#outdated
composer.outdated-strict-minor: COMPOSER_OUTDATED_FLAGS+=--minor-only --strict
composer.outdated-strict-minor: composer.outdated; @true
.PHONY: composer.outdated-strict-minor

# List available major version updates
# @see https://getcomposer.org/doc/03-cli.md#outdated
composer.outdated-strict-major: COMPOSER_OUTDATED_FLAGS+=--major-only --strict
composer.outdated-strict-major: composer.outdated; @true
.PHONY: composer.outdated-strict-major

# Audit the installed packages for possible security issues
# @see https://getcomposer.org/doc/03-cli.md#audit
composer.audit: $(COMPOSER_LOCK) | $(COMPOSER_DEPENDENCY)
ifeq ($(COMPOSER_EXECUTABLE),)
	$(error Please provide the variable COMPOSER_EXECUTABLE)
endif
	@$(COMPOSER_EXECUTABLE) audit $(COMPOSER_AUDIT_FLAGS)
.PHONY: composer.audit
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=composer.audit
