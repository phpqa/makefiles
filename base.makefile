###
##. GNU Make
###

#. Check for GNU Make
ifneq ($(firstword $(shell $(MAKE) --version)),GNU)
$(error Please use GNU Make)
endif

###
##. Disable built-in rules
###

#. Remove all predefined rules
.SUFFIXES:

#. Remove the target if a recipe fails
.DELETE_ON_ERROR:

#. Default to the system shell
SHELL?=/bin/sh

#. Add extra flags to the make command
MAKEFLAGS+=--no-builtin-rules --environment-overrides

###
##. Current working directory
###

CWD=$(eval CWD:=$$(abspath $$(dir $$(firstword $(MAKEFILE_LIST)))))$(CWD)
CWD_PREFIX=$(if $(CWD),$(CWD)/)

###
##. Verbosity
###

VERBOSE?=0
NO_PRINTING_LEVELS?=0
NO_SHELL_PRINTING_LEVELS?=0 1
NO_SHELL_TIMING_LEVELS?=0 1 2

ifneq ($(filter $(VERBOSE),$(NO_PRINTING_LEVELS)),)
Q:=@
MAKEFLAGS+=--no-print-directory
else
Q:=
endif
ifeq ($(filter $(VERBOSE),$(NO_SHELL_PRINTING_LEVELS)),)
SHELL+=-x
endif
ifeq ($(filter $(VERBOSE),$(NO_SHELL_TIMING_LEVELS)),)
SHELL:=time $(SHELL)
endif

#. Run the command without printing "is up to date" messages
silent-% %.silent:%; @true

###
##. Parallelism
###

MAKE_PARALLELISM_OPTIONS=$(eval MAKE_PARALLELISM_OPTIONS:=$$(if $$(shell $$(MAKE) -v | grep "3\|4"), -j $$$$(nproc 2>/dev/null || sysctl -n hw.physicalcpu 2>/dev/null || echo "1"))$$(if $$(shell $$(MAKE) -v | grep "4"), --output-sync=recurse))$(MAKE_PARALLELISM_OPTIONS)

###
##. Default variables
###

TARGET?=
CI?=

###
##. POSIX dependencies - @see https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html
###

define check-base-dependency
ifeq ($$(shell command -v $(1) || which $(1) 2>/dev/null),)
$$(error Please provide the command "$(1)")
endif
endef
$(foreach command,if test printf exit,$(eval $(call check-base-dependency,$(command))))

###
##. Characters
###

empty:=
space:=$(empty) $(empty)
comma:=,
define newline

$(empty)
endef

###
##. Stylesheets
###

STYLE_RESET?=\033[0m

STYLE_TITLE?=\033[1;36m
STYLE_SUCCESS?=\033[32m
STYLE_WARNING?=\033[33m
STYLE_ERROR?=\033[31m
STYLE_DIM?=\033[2m
STYLE_BOLD?=\033[1m
STYLE_UNDERLINE?=\033[4m

ICON_SUCCESS?=\342\234\224 # \u2713
ICON_WARNING?=\342\232\240 # \u26A0
ICON_ERROR?=\342\234\225 # \u2715

###
##. Link
###

#. $(1) is the url, $(2) is the (optional) description
print_link?=printf "\033]8;;%s\033\\\\%s\033]8;;\033\\\\" "$(1)" "$(if $(2),$(2),$(1))"
println_link?=printf "\033]8;;%s\033\\\\%s\033]8;;\033\\\\\n" "$(1)" "$(if $(2),$(2),$(1))"

###
##. Force
###

#. Force the command to run
force: ; @true
.PHONY: force
