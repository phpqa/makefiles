###
##. Configuration
###

GIT_EXECUTABLE?=$(shell command -v git || which git 2>/dev/null)
GIT_DEPENDENCY?=$(if $(GIT_EXECUTABLE),$(if $(wildcard $(GIT_EXECUTABLE)),$(GIT_EXECUTABLE)),git)

GIT_PULL_VERBOSE?=

APPLICATIONS?=

###
## Git
###

# TODO make it optional to use stashes

# $(1) is variable, $(2) is application
git-get-variable-for-application=\
	$(strip $(1))="$($(strip $(1))_$(strip $(2)))"; \
	if test -z "$${$(strip $(1))}"; then \
		$(strip $(1))="$$(printf "$($(strip $(1))_TEMPLATE)" "$(strip $(2))")"; \
		if test -z "$${$(strip $(1))}"; then \
			printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"$(strip $(1))_$(strip $(2))\", nor \"$(strip $(1))_TEMPLATE\"!"; \
			exit 1; \
		fi; \
	fi;
# $(1) is application
git-clone-application=\
	$(call git-get-variable-for-application,DIRECTORY_FOR_REPOSITORY,$(1)) \
	$(call git-get-variable-for-application,REPOSITORY_URL_FOR_REPOSITORY,$(1)) \
	if test ! -d "$${DIRECTORY_FOR_REPOSITORY}"; then \
		printf "%s\\n" "Cloning into $${DIRECTORY_FOR_REPOSITORY}..."; \
		$(GIT_EXECUTABLE) clone $${REPOSITORY_URL_FOR_REPOSITORY} $${DIRECTORY_FOR_REPOSITORY}; \
	fi;
# $(1) is application
git-pull-application=\
	$(call git-get-variable-for-application,DIRECTORY_FOR_REPOSITORY,$(1)) \
	DEFAULT_BRANCH="$$(cd "$${DIRECTORY_FOR_REPOSITORY}" && $(GIT_EXECUTABLE) remote show origin | sed -n '/HEAD branch/s/.*: //p')"; \
	if test -n "$${DEFAULT_BRANCH}" && test "$${DEFAULT_BRANCH}" != "(unknown)"; then \
		printf "%s\\n" "Pulling \"$${DEFAULT_BRANCH}\" branch into \"$${DIRECTORY_FOR_REPOSITORY}\"..." \
		&& cd "$${DIRECTORY_FOR_REPOSITORY}" \
		&& ( $(GIT_EXECUTABLE) pull origin "$${DEFAULT_BRANCH}" || true ) \
		$(if $(GIT_PULL_VERBOSE),&& $(GIT_EXECUTABLE) log -1) \
		&& echo \
		&& sleep 1; \
	else \
		printf "%s\\n" "Could not determine branch for $${DIRECTORY_FOR_REPOSITORY}!"; \
	fi;

# Check if Git is available, exit if it is not
$(if $(GIT_DEPENDENCY),$(GIT_DEPENDENCY),git):
	@if ! test -x "$(@)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not run \"$(@)\". Make sure it is installed."; \
		exit 1; \
	fi

# Clone all repositories
clone: | $(GIT_DEPENDENCY)
	@$(foreach application,$(APPLICATIONS),$(call git-clone-application,$(application)))

# Pull all repositories
pull: | $(GIT_DEPENDENCY)
	@$(foreach application,$(APPLICATIONS),$(call git-pull-application,$(application)))
