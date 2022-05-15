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
MAKEFLAGS+=--no-print-directory --no-builtin-rules --environment-overrides
