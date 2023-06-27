###
##. Dependencies
###

ifeq ($(GIT),)
$(error Please provide the variable GIT)
endif
ifeq ($(GIT_DIRECTORY),)
$(error Please provide the variable GIT_DIRECTORY)
endif

###
##. Configuration
###

REPOSITORIES?=$(if $(wildcard $(GIT_DIRECTORY)),self)
REPOSITORY_self?=$(if $(wildcard $(GIT_DIRECTORY)),$(strip $(foreach variable,$(filter REPOSITORY_DIRECTORY_%,$(.VARIABLES)),$(if $(findstring $(shell pwd),$(realpath $($(variable)))),$(if $(findstring $(realpath $($(variable))),$(shell pwd)),$(patsubst REPOSITORY_DIRECTORY_%,%,$(variable)))))))
REPOSITORY_DIRECTORY_self?=$(if $(wildcard $(GIT_DIRECTORY)),.)

###
##. Repositories
###

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
	else \
		if test ! -d "$(REPOSITORY_DIRECTORY_$(1))/$(GIT_DIRECTORY)"; then \
			DEFAULT_BRANCH="$$($(GIT) ls-remote --symref "$(REPOSITORY_URL_$(1))" HEAD | awk -F'[/\t]' 'NR == 1 {print $$3}')"; \
			( \
				cd $(REPOSITORY_DIRECTORY_$(1)) \
				&& $(GIT) init --initial-branch="$${DEFAULT_BRANCH}" \
				&& $(GIT) remote add origin "$(REPOSITORY_URL_$(1))" \
				&& $(call git-pull-repository,$(1)) \
			); \
		fi; \
	fi
# $(1) is repository
git-pull-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	if test ! -d "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find directory \"$(REPOSITORY_DIRECTORY_$(1))\"."; \
	else \
		cd "$(REPOSITORY_DIRECTORY_$(1))"; \
		if test -n "$(REPOSITORY_MAKEFILE_$(1))"; then \
			if test ! -f "$(REPOSITORY_MAKEFILE_$(1))"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find file \"$(REPOSITORY_DIRECTORY_$(1))/$(REPOSITORY_MAKEFILE_$(1))\"."; \
			else \
				$(MAKE) -f "$(REPOSITORY_MAKEFILE_$(1))" repositories.pull-everything; \
			fi; \
		else \
			REPOSITORY_URL="$(REPOSITORY_URL_$(1))"; \
			if test -z "$${REPOSITORY_URL}"; then \
				REPOSITORY_URL="$$($(GIT) config --get remote.origin.url)"; \
			fi; \
			if test -z "$${REPOSITORY_URL}"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not determine the url for \"$$(pwd)\"!"; \
			else \
				DEFAULT_BRANCH="$$($(GIT) ls-remote --symref "$${REPOSITORY_URL}" HEAD | awk -F'[/\t]' 'NR == 1 {print $$3}')"; \
				if test -z "$${DEFAULT_BRANCH}" || test "$${DEFAULT_BRANCH}" = "(unknown)"; then \
					printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not determine branch for \"$$(pwd)\"!"; \
				else \
					printf "%s\\n" "Pulling \"$${DEFAULT_BRANCH}\" branch into \"$$(pwd)\"..."; \
					$(GIT) pull --rebase origin "$${DEFAULT_BRANCH}" || true; \
					if test -n "$(REPOSITORY_TAG_$(1))"; then \
						$(GIT) fetch --all --tags > /dev/null || true; \
						ACTUAL_REPOSITORY_TAG="$$($(GIT) tag --list --ignore-case --sort=-version:refname "$(REPOSITORY_TAG_$(1))" | head -n 1)"; \
						if test -z "$${ACTUAL_REPOSITORY_TAG}"; then \
							printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find tag \"$(REPOSITORY_TAG_$(1))\" for \"$$(pwd)\"!"; \
						else \
							printf "%s\\n" "Checking \"$${ACTUAL_REPOSITORY_TAG}\" tag into \"$$(pwd)\"..."; \
							$(GIT) -c advice.detachedHead=false checkout "tags/$${ACTUAL_REPOSITORY_TAG}" || true; \
						fi; \
					fi; \
					echo " "; \
					sleep 1; \
				fi; \
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
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find directory \"$(REPOSITORY_DIRECTORY_$(1))\"."; \
	else \
		cd "$(REPOSITORY_DIRECTORY_$(1))"; \
		if test -n "$(REPOSITORY_MAKEFILE_$(1))"; then \
			if test ! -f "$(REPOSITORY_MAKEFILE_$(1))"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find file \"$(REPOSITORY_DIRECTORY_$(1))/$(REPOSITORY_MAKEFILE_$(1))\"."; \
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
# $(1) is repository
git-remove-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	if test -d "$(REPOSITORY_DIRECTORY_$(1))"; then \
		cd "$(REPOSITORY_DIRECTORY_$(1))"; \
		if test -d "$(REPOSITORY_DIRECTORY_$(1))/$(GIT_DIRECTORY)"; then \
			$(GIT) read-tree -u --reset "$$($(GIT) hash-object -t tree /dev/null)" && rm -rf $(GIT_DIRECTORY); \
		fi; \
		rmdir "$(REPOSITORY_DIRECTORY_$(1))" 2>/dev/null || true; \
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

#. Remove a repository
$(foreach repository,$(REPOSITORIES),repository.$(repository).remove):repository.%.remove: | $(GIT_DEPENDENCY)
	@$(call git-remove-repository,$(*))

#. Case 1: No repositories to pull
ifeq ($(REPOSITORIES),)
#. Do nothing
repositories.pull-everything: ; @true
.PHONY: repositories.pull-everything

#. Do nothing
repositories.stash-everything: ; @true
.PHONY: repositories.stash-everything

#. Do nothing
repositories.remove-everything: ; @true
.PHONY: repositories.remove-everything
else
#. Case 2: Only this repository to pull
ifeq ($(REPOSITORIES),$(REPOSITORY_self))
#. Pull this repository
repositories.pull-everything: | repository.pull; @true
.PHONY: repositories.pull-everything

#. Stash files in this repository
repositories.stash-everything: | repository.stash; @true
.PHONY: repositories.stash-everything

#. Remove files in this repository
repositories.remove-everything: | repository.remove; @true
.PHONY: repositories.remove-everything
#. Case 3: Multiple repositories to pull
else
# Clone all repositories
repositories.clone: | $(foreach repository,$(REPOSITORIES),repository.$(repository).clone); @true
.PHONY: repositories.clone

# Pull all repositories
repositories.pull: | repositories.clone $(foreach repository,$(REPOSITORIES),repository.$(repository).pull); @true
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

# Remove files in all repositories
repositories.remove: | $(foreach repository,$(REPOSITORIES),repository.$(repository).remove); @true
.PHONY: repositories.remove

#. Remove files in all repositories
repositories.remove-everything: repositories.remove; @true
.PHONY: repositories.remove-everything
endif
endif

ifneq ($(REPOSITORY_self),)
# Pull this repository
repository.pull: | repository.$(REPOSITORY_self).pull; @true
.PHONY: repository.pull

# Stash files in this repository
repository.stash: | repository.$(REPOSITORY_self).stash; @true
.PHONY: repository.stash

# Remove files in this repository
repository.remove: | repository.$(REPOSITORY_self).remove; @true
.PHONY: repository.remove
endif

ifneq ($(REPOSITORIES),)
#. Hand-off to the REPOSITORY_MAKEFILE of the repository
$(foreach repository,$(filter-out self,$(REPOSITORIES)),$(if $(REPOSITORY_MAKEFILE_$(repository)),%-$(repository))):
	@if test -z "$(REPOSITORY_DIRECTORY_$(patsubst $(*)-%,%,$(@)))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(patsubst $(*)-%,%,$(@))\"!"; \
		exit 1; \
	fi
	@cd "$(REPOSITORY_DIRECTORY_$(patsubst $(*)-%,%,$(@)))" && $(MAKE) -f "$(REPOSITORY_MAKEFILE_$(patsubst $(*)-%,%,$(@)))" $(*)

define make-repository-alias
  $(1): | $(1)-$(2)
  .PHONY: $(1)
endef
#. Hand-off to the REPOSITORY_MAKEFILE of the repository, but without the suffix for the repository
$(foreach repository,$(filter-out self,$(REPOSITORIES)),$(if $(REPOSITORY_MAKEFILE_ALIASES_$(repository)), \
$(foreach alias,$(REPOSITORY_MAKEFILE_ALIASES_$(repository)),$(eval $(call make-repository-alias,$(alias),$(repository))))))
endif
