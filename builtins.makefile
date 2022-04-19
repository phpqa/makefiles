###
##. Disable built-in rules
###

.SUFFIXES:
SHELL?=/bin/sh
MAKEFLAGS+=--no-print-directory --no-builtin-rules --environment-overrides
