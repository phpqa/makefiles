###
##. Dependencies
###

ifeq ($(PHP),)
$(error Please install PHP.)
endif

ifeq ($(COMPOSER_EXECUTABLE),)
$(error Please install Composer.)
endif

###
##. Configuration
###

#. Package variables
DEPTRAC_PACKAGE?=qossmic/deptrac-shim
DEPTRAC?=$(PHP) vendor/bin/deptrac
ifeq ($(DEPTRAC),$(PHP) vendor/bin/deptrac)
DEPTRAC_DEPENDENCY?=$(PHP_DEPENDENCY) vendor/bin/deptrac
else
DEPTRAC_DEPENDENCY?=$(wildcard $(DEPTRAC))
endif

#. Configuration variables
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
## PHP Quality Assurance Tools
###

ifeq ($(wildcard $(filter-out $(PHP_DEPENDENCY),$(DEPTRAC_DEPENDENCY))),)

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
