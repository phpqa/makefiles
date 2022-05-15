###
##. Disable built-in rules
###

.SUFFIXES:
.DELETE_ON_ERROR:
SHELL?=/bin/sh
MAKEFLAGS+=--no-print-directory --no-builtin-rules --environment-overrides
