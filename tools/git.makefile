###
##. Configuration
###

GIT_DETECTED?=$(shell command -v git || which git 2>/dev/null)
GIT_DEPENDENCY?=$(if $(GIT_DETECTED),git.assure-usable,git.not-found)
GIT?=git

GIT_DIRECTORY?=.git

###
##. Requirements
###

ifeq ($(GIT),)
$(error The variable GIT should never be empty.)
endif
ifeq ($(GIT_DEPENDENCY),)
$(error The variable GIT_DEPENDENCY should never be empty.)
endif
ifeq ($(GIT_DIRECTORY),)
$(error The variable GIT_DIRECTORY should never be empty.)
endif

###
## Repositories
###

#. Exit if git is not found
git.not-found:
	@printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Please install git."
	@exit 1
.PHONY: git.not-found

#. Assure that git is usable
git.assure-usable:
	@if test -z "$$($(GIT) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use GIT as "$(value GIT)".'; \
		exit 1; \
	fi
.PHONY: git.assure-usable
