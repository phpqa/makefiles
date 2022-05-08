###
##. Configuration
###

GIT_EXECUTABLE?=$(shell command -v git || which git 2>/dev/null)
GIT_PULL_VERBOSE?=

REPOSITORIES?=$(if $(APPLICATIONS),$(APPLICATIONS))
REPOSITORY_DIRECTORY_self?=.

###
## Git
###

.PHONY: git clone pull

# TODO make it optional to use stashes

# $(1) is variable, $(2) is repository
git-find-variable-for-repository=\
	$(strip $(1))="$($(strip $(1))_$(strip $(2)))"; \
	if test -z "$${$(strip $(1))}"; then \
		$(strip $(1))="$$(printf "$($(strip $(1))_TEMPLATE)" "$(strip $(2))")"; \
	fi
# $(1) is variable, $(2) is repository
git-get-variable-for-repository=\
	$(call git-find-variable-for-repository,$(1),$(2)); \
	if test -z "$${$(strip $(1))}"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"$(strip $(1))_$(strip $(2))\", nor \"$(strip $(1))_TEMPLATE\"!"; \
		exit 1; \
	fi
# $(1) is repository
git-clone-repository=\
	$(call git-get-variable-for-repository,REPOSITORY_DIRECTORY,$(1)); \
	if test ! -d "$${REPOSITORY_DIRECTORY}"; then \
		$(call git-get-variable-for-repository,REPOSITORY_URL,$(1)); \
		printf "%s\\n" "Cloning into $${REPOSITORY_DIRECTORY}..."; \
		$(GIT_EXECUTABLE) clone $${REPOSITORY_URL} $${REPOSITORY_DIRECTORY}; \
	fi
# $(1) is repository
git-pull-repository=\
	$(call git-get-variable-for-repository,REPOSITORY_DIRECTORY,$(1)); \
	$(call git-find-variable-for-repository,REPOSITORY_MAKEFILE,$(1)); \
	$(call git-find-variable-for-repository,REPOSITORY_TAG,$(1)); \
	( \
		cd "$${REPOSITORY_DIRECTORY}"; \
		if test -n "$${REPOSITORY_MAKEFILE}"; then \
			if test ! -f "$${REPOSITORY_MAKEFILE}"; then \
				printf "%s\\n" "Could not find file \"$${REPOSITORY_DIRECTORY}/$${REPOSITORY_MAKEFILE}\"."; \
			else \
				$(MAKE) -f "$${REPOSITORY_MAKEFILE}" pull; \
			fi; \
		else \
			if test -n "$${REPOSITORY_TAG}"; then \
				ACTUAL_REPOSITORY_TAG="$$($(GIT_EXECUTABLE) fetch --all --tags > /dev/null && $(GIT_EXECUTABLE) tag --list --ignore-case --sort=-version:refname "$${REPOSITORY_TAG}" | head -n 1)"; \
				if test -z "$${ACTUAL_REPOSITORY_TAG}"; then \
					printf "%s\\n" "Could not find tag \"$${REPOSITORY_TAG}\" for \"$$(pwd)\"!"; \
				else \
					printf "%s\\n" "Checking \"$${ACTUAL_REPOSITORY_TAG}\" tag into \"$$(pwd)\"..."; \
					$(GIT_EXECUTABLE) checkout "tags/$${ACTUAL_REPOSITORY_TAG}" || true; \
					$(if $(GIT_PULL_VERBOSE),$(GIT_EXECUTABLE) log -1 || true;) \
					echo " "; \
					sleep 1; \
				fi; \
			else \
				DEFAULT_BRANCH="$$($(GIT_EXECUTABLE) remote show origin | sed -n '/HEAD branch/s/.*: //p')"; \
				if test -z "$${DEFAULT_BRANCH}" || test "$${DEFAULT_BRANCH}" = "(unknown)"; then \
					printf "%s\\n" "Could not determine branch for \"$$(pwd)\"!"; \
				else \
					printf "%s\\n" "Pulling \"$${DEFAULT_BRANCH}\" branch into \"$$(pwd)\"..."; \
					$(GIT_EXECUTABLE) pull origin "$${DEFAULT_BRANCH}" || true; \
					$(if $(GIT_PULL_VERBOSE),$(GIT_EXECUTABLE) log -1 || true;) \
					echo " "; \
					sleep 1; \
				fi; \
			fi; \
		fi \
	)

# Check if Git is available, exit if it is not
git:
	@if test -z "$(GIT_EXECUTABLE)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not run \"$(@)\". Make sure it is installed."; \
		exit 1; \
	fi

# Clone all repositories
clone: | git
	@$(foreach repository,$(REPOSITORIES),$(call git-clone-repository,$(repository)); )

# Pull all repositories
pull: | git
	@$(foreach repository,$(REPOSITORIES),$(call git-pull-repository,$(repository)); )
