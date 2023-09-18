###
##. Report tools
##. ! If you include this file, always include it AFTER the makefiles of the tools
###

PHP_QUALITY_ASSURANCE_REPORT_TOOLS?=
PHP_QUALITY_ASSURANCE_REPORT_TOOLS_DEPENDENCIES?=
PHP_QUALITY_ASSURANCE_REPORT_TOOLS_TO_SKIP?=

ifneq ($(PHP_QUALITY_ASSURANCE_REPORT_TOOLS),)
#. Install all report tools
php.report.install: | $(PHP_QUALITY_ASSURANCE_REPORT_TOOLS_DEPENDENCIES)
.PHONY: php.report.install

# Generate all reports
php.report: $(filter-out $(PHP_QUALITY_ASSURANCE_REPORT_TOOLS_TO_SKIP),$(PHP_QUALITY_ASSURANCE_REPORT_TOOLS)); @true
.PHONY: php.report

# List all reports
php.report.list: $(addsuffix .report.list,$(filter-out $(PHP_QUALITY_ASSURANCE_REPORT_TOOLS_TO_SKIP),$(PHP_QUALITY_ASSURANCE_REPORT_TOOLS))); @true
.PHONY: php.report.list

# Remove all reports #!
php.report.remove: $(addsuffix .report.remove,$(filter-out $(PHP_QUALITY_ASSURANCE_REPORT_TOOLS_TO_SKIP),$(PHP_QUALITY_ASSURANCE_REPORT_TOOLS))); @true
.PHONY: php.report.remove
endif
