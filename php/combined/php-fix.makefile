###
##. Fix tools
##. ! If you include this file, always include it AFTER the makefiles of the tools
###

PHP_QUALITY_ASSURANCE_FIX_TOOLS?=
PHP_QUALITY_ASSURANCE_FIX_TOOLS_DEPENDENCIES?=
PHP_QUALITY_ASSURANCE_FIX_TOOLS_TO_SKIP?=

ifneq ($(PHP_QUALITY_ASSURANCE_FIX_TOOLS),)
#. Install all fix tools
php.fix.install: | $(PHP_QUALITY_ASSURANCE_FIX_TOOLS_DEPENDENCIES)
.PHONY: php.fix.install

# Fix all files #!
php.fix: $(filter-out $(PHP_QUALITY_ASSURANCE_FIX_TOOLS_TO_SKIP),$(PHP_QUALITY_ASSURANCE_FIX_TOOLS)); @true
.PHONY: php.fix
endif
