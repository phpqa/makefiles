###
##. Disable built-in rules
###

#. Disable documentation
.SUFFIXES:

#. Disable documentation
.DELETE_ON_ERROR:

SHELL?=/bin/sh
MAKEFLAGS+=--no-print-directory --no-builtin-rules --warn-undefined-variables --environment-overrides
