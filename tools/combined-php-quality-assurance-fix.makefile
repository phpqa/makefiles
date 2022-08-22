###
## Quality Assurance
## ! If you include this file, always include it AFTER the makefiles of the tools
###

PHP_QUALITY_ASSURANCE_FIX_TOOLS?=
PHP_QUALITY_ASSURANCE_FIX_TOOLS_TO_SKIP?=

ifneq ($(PHP_QUALITY_ASSURANCE_FIX_TOOLS),)
# Fix all files #!
php.fix: $(filter-out $(PHP_QUALITY_ASSURANCE_FIX_TOOLS_TO_SKIP),$(PHP_QUALITY_ASSURANCE_FIX_TOOLS))
	@true
.PHONY: php.fix
endif
