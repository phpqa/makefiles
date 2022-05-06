###
##. Configuration
###

GIT_EXECUTABLE?=$(shell command -v git || which git 2>/dev/null)
GIT_DEPENDENCY?=$(if $(GIT_EXECUTABLE),$(if $(wildcard $(GIT_EXECUTABLE)),$(GIT_EXECUTABLE)),git)

GIT_PULL_VERBOSE?=

REPOSITORIES?=$(if $(APPLICATIONS),$(APPLICATIONS))

DIRECTORY_FOR_REPOSITORY_self?=.

###
## Git
###

# TODO make it optional to use stashes

# $(1) is variable, $(2) is repository
git-find-variable-for-repository=\
	$(strip $(1))="$($(strip $(1))_$(strip $(2)))"; \
	if test -z "$${$(strip $(1))}"; then \
		$(strip $(1))="$$(printf "$($(strip $(1))_TEMPLATE)" "$(strip $(2))")"; \
	fi;
# $(1) is variable, $(2) is repository
git-get-variable-for-repository=\
	$(call git-find-variable-for-repository,$(1),$(2)) \
	if test -z "$${$(strip $(1))}"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"$(strip $(1))_$(strip $(2))\", nor \"$(strip $(1))_TEMPLATE\"!"; \
		exit 1; \
	fi;
# $(1) is repository
git-clone-repository=\
	$(call git-get-variable-for-repository,DIRECTORY_FOR_REPOSITORY,$(1)) \
	if test ! -d "$${DIRECTORY_FOR_REPOSITORY}"; then \
		$(call git-get-variable-for-repository,REPOSITORY_URL_FOR_REPOSITORY,$(1)) \
		printf "%s\\n" "Cloning into $${DIRECTORY_FOR_REPOSITORY}..."; \
		$(GIT_EXECUTABLE) clone $${REPOSITORY_URL_FOR_REPOSITORY} $${DIRECTORY_FOR_REPOSITORY}; \
	fi;
# $(1) is repository
git-pull-repository=\
	$(call git-get-variable-for-repository,DIRECTORY_FOR_REPOSITORY,$(1)) \
	$(call git-find-variable-for-repository,MAKEFILE_FOR_REPOSITORY,$(1)) \
	if test -n "$${MAKEFILE_FOR_REPOSITORY}" && test -f "$${DIRECTORY_FOR_REPOSITORY}/$${MAKEFILE_FOR_REPOSITORY}"; then \
		( cd "$${DIRECTORY_FOR_REPOSITORY}" && $(MAKE) -f "$${MAKEFILE_FOR_REPOSITORY}" pull ); \
	else \
		DEFAULT_BRANCH="$$(cd "$${DIRECTORY_FOR_REPOSITORY}" && $(GIT_EXECUTABLE) remote show origin | sed -n '/HEAD branch/s/.*: //p')"; \
		if test -z "$${DEFAULT_BRANCH}" || test "$${DEFAULT_BRANCH}" = "(unknown)"; then \
			printf "%s\\n" "Could not determine branch for $$(cd "$${DIRECTORY_FOR_REPOSITORY}"; pwd)!"; \
		else \
			printf "%s\\n" "Pulling \"$${DEFAULT_BRANCH}\" branch into \"$$(cd "$${DIRECTORY_FOR_REPOSITORY}"; pwd)\"..." \
			&& ( \
				cd "$${DIRECTORY_FOR_REPOSITORY}"; \
				( $(GIT_EXECUTABLE) pull origin "$${DEFAULT_BRANCH}" || true ) \
				$(if $(GIT_PULL_VERBOSE), && ( $(GIT_EXECUTABLE) log -1 || true )) \
			) \
			&& echo \
			&& sleep 1; \
		fi; \
	fi;

# Check if Git is available, exit if it is not
$(if $(GIT_DEPENDENCY),$(GIT_DEPENDENCY),git):
	@if ! test -x "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not run \"$(@)\". Make sure it is installed."; \
		exit 1; \
	fi

# Clone all repositories
clone: | $(GIT_DEPENDENCY)
	@$(foreach repository,$(REPOSITORIES),$(call git-clone-repository,$(repository)))

# Pull all repositories
pull: | $(GIT_DEPENDENCY)
	@$(foreach repository,$(REPOSITORIES),$(call git-pull-repository,$(repository)))
