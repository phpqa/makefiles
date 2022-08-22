###
## Quality Assurance
## ! If you include this file, always include it AFTER the makefiles of the tools
###

PHP_QUALITY_ASSURANCE_CHECK_TOOLS?=
PHP_QUALITY_ASSURANCE_CHECK_TOOLS_TO_SKIP?=

ifneq ($(PHP_QUALITY_ASSURANCE_CHECK_TOOLS),)
# Run a complete analysis
php.check: $(filter-out $(PHP_QUALITY_ASSURANCE_CHECK_TOOLS_TO_SKIP),$(PHP_QUALITY_ASSURANCE_CHECK_TOOLS))
	@true
.PHONY: php.check
endif
