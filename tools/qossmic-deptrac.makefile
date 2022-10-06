###
##. Configuration
###

#. Package variables
DEPTRAC_PACKAGE?=qossmic/deptrac-shim
ifeq ($(DEPTRAC_PACKAGE),)
$(error The variable DEPTRAC_PACKAGE should never be empty)
endif

DEPTRAC?=$(or $(PHP),php) vendor/bin/deptrac
ifeq ($(DEPTRAC),)
$(error The variable DEPTRAC should never be empty)
endif

ifeq ($(DEPTRAC),$(or $(PHP),php) vendor/bin/deptrac)
DEPTRAC_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/deptrac
else
DEPTRAC_DEPENDENCY?=$(wildcard $(DEPTRAC))
endif
ifeq ($(DEPTRAC_DEPENDENCY),)
$(error The variable DEPTRAC_DEPENDENCY should never be empty)
endif

#. Register as a tool
PHP_QUALITY_ASSURANCE_CHECK_TOOLS_DEPENDENCIES+=$(filter-out $(PHP_DEPENDENCY),$(DEPTRAC_DEPENDENCY))
HELP_TARGETS_TO_SKIP+=$(wildcard $(filter-out $(PHP_DEPENDENCY),$(DEPTRAC_DEPENDENCY)))

#. Tool variables
DEPTRAC_POSSIBLE_CONFIGS?=deptrac.yaml
DEPTRAC_CONFIG?=$(wildcard $(DEPTRAC_POSSIBLE_CONFIGS))

#. Building the flags
DEPTRAC_FLAGS?=

ifneq ($(wildcard $(DEPTRAC_CONFIG)),)
ifeq ($(findstring --config-file,$(DEPTRAC_FLAGS)),)
DEPTRAC_FLAGS+=--config-file="$(DEPTRAC_CONFIG)"
endif
endif

###
##. Deptrac
##. Communicate, visualize and enforce architectural decisions in your projects
##. @see https://qossmic.github.io/deptrac/
###

ifneq ($(COMPOSER_EXECUTABLE),)
# Install Deptrac as dev dependency in vendor
vendor/bin/deptrac: | $(COMPOSER_DEPENDENCY) vendor
	@if test ! -f "$(@)"; then $(COMPOSER_EXECUTABLE) require --dev "$(DEPTRAC_PACKAGE)"; fi
endif

#. Initialize Deptrac
$(if $(DEPTRAC_CONFIG),$(DEPTRAC_CONFIG),deptrac.yaml): | $(DEPTRAC_DEPENDENCY)
	@$(DEPTRAC) init --config-file="$(@)"

# Run Deptrac
# @see https://deptrac.org/
deptrac: $(wildcard $(DEPTRAC_CONFIG)) | $(DEPTRAC_DEPENDENCY)
	@$(DEPTRAC)$(if $(DEPTRAC_FLAGS), $(DEPTRAC_FLAGS)) analyse --report-uncovered
.PHONY: deptrac
PHP_QUALITY_ASSURANCE_CHECK_TOOLS+=deptrac
