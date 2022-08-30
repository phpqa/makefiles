###
##. Configuration
###

GIT_DETECTED?=$(shell command -v git || which git 2>/dev/null)
GIT_DEPENDENCY?=$(if $(GIT_DETECTED),git.assure-usable,git.not-found)
GIT?=git

GIT_SUBDIRECTORY?=.git

REPOSITORIES?=$(if $(wildcard $(GIT_SUBDIRECTORY)),self)
REPOSITORY_self?=$(if $(wildcard $(GIT_SUBDIRECTORY)),$(strip $(foreach variable,$(filter REPOSITORY_DIRECTORY_%,$(.VARIABLES)),$(if $(findstring $(shell pwd),$(realpath $($(variable)))),$(if $(findstring $(realpath $($(variable))),$(shell pwd)),$(patsubst REPOSITORY_DIRECTORY_%,%,$(variable)))))))
REPOSITORY_DIRECTORY_self?=$(if $(wildcard $(GIT_SUBDIRECTORY)),.)

###
##. Requirements
###

ifeq ($(GIT),)
$(error The variable GIT should never be empty.)
endif
ifeq ($(GIT_DEPENDENCY),)
$(error The variable GIT_DEPENDENCY should never be empty.)
endif

###
## Repositories
###

#. Assure that git is usable
git.assure-usable:
	@if test -z "$$($(GIT) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use GIT as "$(value GIT)".'; \
		exit 1; \
	fi
.PHONY: git.assure-usable

#. Exit if git is not found
git.not-found:
	@printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Please install git."
	@exit 1
.PHONY: git.not-found

# TODO make it optional to use stashes
# $(1) is repository
git-clone-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	if test ! -d "$(REPOSITORY_DIRECTORY_$(1))"; then \
		if test -z "$(REPOSITORY_URL_$(1))"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_URL_$(1)\"!"; \
			exit 1; \
		fi; \
		$(GIT) clone "$(REPOSITORY_URL_$(1))" "$(REPOSITORY_DIRECTORY_$(1))"; \
	fi
# $(1) is repository
git-pull-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	if test ! -d "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "%s\\n" "Could not find directory \"$(REPOSITORY_DIRECTORY_$(1))\"."; \
	else \
		cd "$(REPOSITORY_DIRECTORY_$(1))"; \
		if test -n "$(REPOSITORY_MAKEFILE_$(1))"; then \
			if test ! -f "$(REPOSITORY_MAKEFILE_$(1))"; then \
				printf "%s\\n" "Could not find file \"$(REPOSITORY_DIRECTORY_$(1))/$(REPOSITORY_MAKEFILE_$(1))\"."; \
			else \
				$(MAKE) -f "$(REPOSITORY_MAKEFILE_$(1))" repositories.pull-everything; \
			fi; \
		else \
			DEFAULT_BRANCH="$$($(GIT) remote show origin | sed -n '/HEAD branch/s/.*: //p')"; \
			if test -z "$${DEFAULT_BRANCH}" || test "$${DEFAULT_BRANCH}" = "(unknown)"; then \
				printf "%s\\n" "Could not determine branch for \"$$(pwd)\"!"; \
			else \
				printf "%s\\n" "Pulling \"$${DEFAULT_BRANCH}\" branch into \"$$(pwd)\"..."; \
				$(GIT) pull --rebase origin "$${DEFAULT_BRANCH}" || true; \
				if test -n "$(REPOSITORY_TAG_$(1))"; then \
					$(GIT) fetch --all --tags > /dev/null || true; \
					ACTUAL_REPOSITORY_TAG="$$($(GIT) tag --list --ignore-case --sort=-version:refname "$(REPOSITORY_TAG_$(1))" | head -n 1)"; \
					if test -z "$${ACTUAL_REPOSITORY_TAG}"; then \
						printf "%s\\n" "Could not find tag \"$(REPOSITORY_TAG_$(1))\" for \"$$(pwd)\"!"; \
					else \
						printf "%s\\n" "Checking \"$${ACTUAL_REPOSITORY_TAG}\" tag into \"$$(pwd)\"..."; \
						$(GIT) -c advice.detachedHead=false checkout "tags/$${ACTUAL_REPOSITORY_TAG}" || true; \
					fi; \
				fi; \
				echo " "; \
				sleep 1; \
			fi; \
		fi; \
	fi
# $(1) is repository
git-stash-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	if test ! -d "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "%s\\n" "Could not find directory \"$(REPOSITORY_DIRECTORY_$(1))\"."; \
	else \
		cd "$(REPOSITORY_DIRECTORY_$(1))"; \
		if test -n "$(REPOSITORY_MAKEFILE_$(1))"; then \
			if test ! -f "$(REPOSITORY_MAKEFILE_$(1))"; then \
				printf "%s\\n" "Could not find file \"$(REPOSITORY_DIRECTORY_$(1))/$(REPOSITORY_MAKEFILE_$(1))\"."; \
			else \
				$(MAKE) -f "$(REPOSITORY_MAKEFILE_$(1))" repositories.stash-everything; \
			fi; \
		else \
			if test -z "$$($(GIT) status -s)"; then \
				printf "%s\\n" "Nothing to stash in \"$$(pwd)\"."; \
			else \
				printf "%s\\n" "Stash pending changes in \"$$(pwd)\"..."; \
				$(GIT) stash push --message "Stashed $$(date +'%Y-%m-%d %H:%M:%S') by makefile script" || true; \
			fi; \
		fi; \
	fi

#. Clone a repository
$(foreach repository,$(REPOSITORIES),repository.$(repository).clone):repository.%.clone: | $(GIT_DEPENDENCY)
	@$(call git-clone-repository,$(*))

#. Pull a repository
$(foreach repository,$(REPOSITORIES),repository.$(repository).pull):repository.%.pull: | $(GIT_DEPENDENCY)
	@$(call git-pull-repository,$(*))

#. Stash a repository
$(foreach repository,$(REPOSITORIES),repository.$(repository).stash):repository.%.stash: | $(GIT_DEPENDENCY)
	@$(call git-stash-repository,$(*))

#. Case 1: No repositories to pull
ifeq ($(REPOSITORIES),)
#. Do nothing
repositories.pull-everything: ; @true
.PHONY: repositories.pull-everything

#. Do nothing
repositories.stash-everything: ; @true
.PHONY: repositories.stash-everything
else
#. Case 2: Only this repository to pull
ifeq ($(REPOSITORIES),$(REPOSITORY_self))
#. Pull this repository
repositories.pull-everything: | repository.pull; @true
.PHONY: repositories.pull-everything

#. Stash files in this repository
repositories.stash-everything: | repository.stash; @true
.PHONY: repositories.stash-everything
#. Case 3: Multiple repositories to pull
else
# Clone all repositories
repositories.clone: | $(foreach repository,$(REPOSITORIES),repository.$(repository).clone); @true
.PHONY: repositories.clone

# Pull all repositories
repositories.pull: | $(foreach repository,$(REPOSITORIES),repository.$(repository).pull); @true
.PHONY: repositories.pull

#. Pull all repositories
repositories.pull-everything: repositories.pull; @true
.PHONY: repositories.pull-everything

# Stash files in all repositories
repositories.stash: | $(foreach repository,$(REPOSITORIES),repository.$(repository).stash); @true
.PHONY: repositories.stash

#. Stash files in all repositories
repositories.stash-everything: repositories.stash; @true
.PHONY: repositories.stash-everything
endif
endif

ifneq ($(REPOSITORY_self),)
# Pull this repository
repository.pull: | repository.$(REPOSITORY_self).pull
	@true
.PHONY: repository.pull

# Stash files in this repository
repository.stash: | repository.$(REPOSITORY_self).stash
	@true
.PHONY: repository.stash
endif

ifneq ($(REPOSITORIES),)
#. Hand-off to the REPOSITORY_MAKEFILE of the repository
$(foreach repository,$(filter-out self,$(REPOSITORIES)),$(if $(REPOSITORY_MAKEFILE_$(repository)),%-$(repository))):
	@if test -z "$(REPOSITORY_DIRECTORY_$(patsubst $(*)-%,%,$(@)))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(patsubst $(*)-%,%,$(@))\"!"; \
		exit 1; \
	fi
	@cd "$(REPOSITORY_DIRECTORY_$(patsubst $(*)-%,%,$(@)))" && $(MAKE) -f "$(REPOSITORY_MAKEFILE_$(patsubst $(*)-%,%,$(@)))" $(*)
endif
