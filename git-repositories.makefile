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

GIT_SSH_COMMAND?=
REPOSITORY_CLONE_IN_PARALLEL?=
REPOSITORY_FETCH_IN_PARALLEL?=
REPOSITORY_PULL_IN_PARALLEL?=

REPOSITORY_PROJECT_ROOT_DIRECTORY?=
REPOSITORY_DIRECTORY_self?=$(eval REPOSITORY_DIRECTORY_self:=$$(if $$(wildcard $(GIT_DIRECTORY)),.))$(REPOSITORY_DIRECTORY_self)

REPOSITORY_NAMES?=$(eval REPOSITORY_NAMES:=$$(if $$(wildcard $$(GIT_DIRECTORY)),self))$(REPOSITORY_NAMES)
REPOSITORY_self?=$(eval REPOSITORY_self:=$$(firstword $$(strip $$(foreach variable,$$(filter REPOSITORY_DIRECTORY_%,$$(.VARIABLES)),$$(if $$(filter $$(shell pwd),$$($$(variable))),$$(patsubst REPOSITORY_DIRECTORY_%,%,$$(variable)))))))$(REPOSITORY_self)

###
##. Repositories
###

# $(1) is repository
git-clone-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	$(if $(REPOSITORY_CLONE_IN_PARALLEL),export GIT_SSH_COMMAND="$(or $(GIT_SSH_COMMAND),ssh -o ControlPath=no)";) \
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
git-list-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	if test ! -d "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find directory \"$(REPOSITORY_DIRECTORY_$(1))\"."; \
	else \
		cd "$(REPOSITORY_DIRECTORY_$(1))"; \
		PWD_TO_PRINT="$(subst $(patsubst %/,%,$(REPOSITORY_PROJECT_ROOT_DIRECTORY))/,,$(realpath $(REPOSITORY_DIRECTORY_$(1))))"; \
		if test -n "$(REPOSITORY_MAKEFILE_$(1))"; then \
			if test ! -f "$(REPOSITORY_MAKEFILE_$(1))"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not find file \"$(REPOSITORY_DIRECTORY_$(1))/$(REPOSITORY_MAKEFILE_$(1))\"."; \
			else \
				$(MAKE) --file "$(REPOSITORY_MAKEFILE_$(1))" repositories.list-everything; \
			fi; \
		else \
			REPOSITORY_URL="$(REPOSITORY_URL_$(1))"; \
			if test -z "$${REPOSITORY_URL}"; then \
				REPOSITORY_URL="$$($(GIT) config --get remote.origin.url)"; \
			fi; \
			CURRENT_BRANCH="$$($(GIT) rev-parse --abbrev-ref HEAD)"; \
			printf "%s\\n" "$(1): directory $${PWD_TO_PRINT}, branch \"$${CURRENT_BRANCH}\", remote url \"$${REPOSITORY_URL}\""; \
		fi; \
	fi
# $(1) is repository
git-fetch-repository=\
	if test -z "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find variable \"REPOSITORY_DIRECTORY_$(1)\"!"; \
		exit 1; \
	fi; \
	if test ! -d "$(REPOSITORY_DIRECTORY_$(1))"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Could not find directory \"$(REPOSITORY_DIRECTORY_$(1))\"."; \
	else \
		cd "$(REPOSITORY_DIRECTORY_$(1))"; \
		PWD_TO_PRINT="$(subst $(patsubst %/,%,$(REPOSITORY_PROJECT_ROOT_DIRECTORY))/,,$(realpath $(REPOSITORY_DIRECTORY_$(1))))"; \
		if test -n "$(REPOSITORY_MAKEFILE_$(1))"; then \
			if test ! -f "$(REPOSITORY_MAKEFILE_$(1))"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not find file \"$(REPOSITORY_DIRECTORY_$(1))/$(REPOSITORY_MAKEFILE_$(1))\"."; \
			else \
				$(MAKE) --file "$(REPOSITORY_MAKEFILE_$(1))" repositories.fetch-everything; \
			fi; \
		else \
			$(if $(REPOSITORY_FETCH_IN_PARALLEL),export GIT_SSH_COMMAND="$(or $(GIT_SSH_COMMAND),ssh -o ControlPath=no)";) \
			REPOSITORY_URL="$(REPOSITORY_URL_$(1))"; \
			if test -z "$${REPOSITORY_URL}"; then \
				REPOSITORY_URL="$$($(GIT) config --get remote.origin.url)"; \
			fi; \
			if test -z "$${REPOSITORY_URL}"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not determine the remote url!"; \
			else \
				DEFAULT_BRANCH="$$($(GIT) ls-remote --symref "$${REPOSITORY_URL}" HEAD | awk -F'[/\t]' 'NR == 1 {print $$3}')"; \
				CURRENT_BRANCH="$$($(GIT) rev-parse --abbrev-ref HEAD)"; \
				if test -z "$${CURRENT_BRANCH}" || test "$${CURRENT_BRANCH}" = "(unknown)" || test "$${CURRENT_BRANCH}" = "HEAD"; then \
					printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not determine the current branch!"; \
				else \
					if test "$${DEFAULT_BRANCH}" = "$${CURRENT_BRANCH}"; then \
						printf "%s\\n" "[$${PWD_TO_PRINT}] Fetching the \"$${CURRENT_BRANCH}\" branch..."; \
						$(GIT) fetch --quiet "origin" "$${CURRENT_BRANCH}"; \
					else \
						printf "%s\\n" "[$${PWD_TO_PRINT}] Fetching the \"$${DEFAULT_BRANCH}\" and \"$${CURRENT_BRANCH}\" branches..."; \
						$(GIT) fetch --quiet "origin" "$${DEFAULT_BRANCH}"; \
						$(GIT) fetch --quiet "origin" "$${CURRENT_BRANCH}"; \
					fi; \
				fi; \
			fi; \
		fi; \
	fi
#. DEFAULT_BRANCH="$$($(GIT) ls-remote --symref "$${REPOSITORY_URL}" HEAD | awk -F'[/\t]' 'NR == 1 {print $$3}')"
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
		PWD_TO_PRINT="$(subst $(patsubst %/,%,$(REPOSITORY_PROJECT_ROOT_DIRECTORY))/,,$(realpath $(REPOSITORY_DIRECTORY_$(1))))"; \
		if test -n "$(REPOSITORY_MAKEFILE_$(1))"; then \
			if test ! -f "$(REPOSITORY_MAKEFILE_$(1))"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not find file \"$(REPOSITORY_DIRECTORY_$(1))/$(REPOSITORY_MAKEFILE_$(1))\"."; \
			else \
				$(MAKE) --file "$(REPOSITORY_MAKEFILE_$(1))" repositories.pull-everything; \
			fi; \
		else \
			$(if $(REPOSITORY_PULL_IN_PARALLEL),export GIT_SSH_COMMAND="$(or $(GIT_SSH_COMMAND),ssh -o ControlPath=no)";) \
			REPOSITORY_URL="$(REPOSITORY_URL_$(1))"; \
			if test -z "$${REPOSITORY_URL}"; then \
				REPOSITORY_URL="$$($(GIT) config --get remote.origin.url)"; \
			fi; \
			if test -z "$${REPOSITORY_URL}"; then \
				printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not determine the remote url!"; \
			else \
				CURRENT_BRANCH="$$($(GIT) rev-parse --abbrev-ref HEAD)"; \
				if test -z "$${CURRENT_BRANCH}" || test "$${CURRENT_BRANCH}" = "(unknown)" || test "$${CURRENT_BRANCH}" = "HEAD"; then \
					printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not determine the current branch!"; \
				else \
					printf "%s\\n" "[$${PWD_TO_PRINT}] Fetching all remote branches..."; \
					$(GIT) fetch --all --quiet; \
					if test -z "$$($(GIT) log --oneline HEAD..origin/$${CURRENT_BRANCH} 2>&1)"; then \
						printf "$(STYLE_WARNING)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Nothing to pull for the \"$${CURRENT_BRANCH}\" branch."; \
					else \
						COMMIT_HASH_BEFORE="$$($(GIT) rev-parse --verify HEAD)"; \
						printf "%s\\n" "[$${PWD_TO_PRINT}] Pulling the \"$${CURRENT_BRANCH}\" branch..."; \
						OUTPUT="$$($(GIT) pull --rebase origin "$${CURRENT_BRANCH}" 2>&1)"; \
						RESULT="$$?"; \
						if test "$${RESULT}" -eq "0"; then \
							COMMIT_HASH_AFTER="$$($(GIT) rev-parse --verify HEAD)"; \
							LOGS="$$($(GIT) --no-pager log --oneline --reverse --pretty=format:"%C(yellow)%h%Creset %ci %Cgreen(%cr)%Creset %s %C(bold blue)<%an>%Creset" $${COMMIT_HASH_BEFORE}..$${COMMIT_HASH_AFTER})"; \
							if test -n "$${LOGS}"; then printf "%s\\n" "$${LOGS}"; fi; \
							printf "$(STYLE_SUCCESS)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Pulled the \"$${CURRENT_BRANCH}\" branch."; \
						else \
							printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "$${OUTPUT}"; \
							exit $${RESULT}; \
						fi; \
					fi; \
					if test -n "$(REPOSITORY_TAG_$(1))"; then \
						$(GIT) fetch --all --tags > /dev/null || true; \
						ACTUAL_REPOSITORY_TAG="$$($(GIT) tag --list --ignore-case --sort=-version:refname "$(REPOSITORY_TAG_$(1))" | head -n 1)"; \
						if test -z "$${ACTUAL_REPOSITORY_TAG}"; then \
							printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Could not find the tag \"$(REPOSITORY_TAG_$(1))\"!"; \
						else \
							printf "%s\\n" "[$${PWD_TO_PRINT}] Doing a checkout of the \"$${ACTUAL_REPOSITORY_TAG}\" tag..."; \
							$(GIT) -c advice.detachedHead=false checkout "tags/$${ACTUAL_REPOSITORY_TAG}" || true; \
							printf "$(STYLE_SUCCESS)%s$(STYLE_RESET)\\n" "[$${PWD_TO_PRINT}] Checked out the \"$${ACTUAL_REPOSITORY_TAG}\" tag."; \
						fi; \
					fi; \
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
				$(MAKE) --file "$(REPOSITORY_MAKEFILE_$(1))" repositories.stash-everything; \
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
$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).clone):repository.%.clone: | $(GIT_DEPENDENCY)
	@$(call git-clone-repository,$(*))

#. List a repository
$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).list):repository.%.list: | $(GIT_DEPENDENCY)
	@$(call git-list-repository,$(*))

#. Fetch a repository
$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).fetch):repository.%.fetch: | $(GIT_DEPENDENCY)
	@$(call git-fetch-repository,$(*))

#. Pull a repository
$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).pull):repository.%.pull: | $(GIT_DEPENDENCY)
	@$(call git-pull-repository,$(*))

#. Stash a repository
$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).stash):repository.%.stash: | $(GIT_DEPENDENCY)
	@$(call git-stash-repository,$(*))

#. Remove a repository
$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).remove):repository.%.remove: | $(GIT_DEPENDENCY)
	@$(call git-remove-repository,$(*))

#. Case 1: No repositories
ifeq ($(REPOSITORY_NAMES),)
#. Do nothing
repositories.list-everything: ; @true
.PHONY: repositories.list-everything

#. Do nothing
repositories.fetch-everything: ; @true
.PHONY: repositories.fetch-everything

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
#. Case 2: Only this repository
ifeq ($(REPOSITORY_NAMES),$(REPOSITORY_self))
#. List this repository
repositories.list-everything: | repository.list; @true
.PHONY: repositories.list-everything

#. Fetch this repository
repositories.fetch-everything: | repository.fetch; @true
.PHONY: repositories.fetch-everything

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
repositories.clone:
	@$(if $(REPOSITORY_CLONE_IN_PARALLEL),REPOSITORY_CLONE_IN_PARALLEL=$(REPOSITORY_CLONE_IN_PARALLEL)) \
		$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" $(if $(REPOSITORY_CLONE_IN_PARALLEL),$(MAKE_PARALLELISM_OPTIONS)) \
		$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).clone)
.PHONY: repositories.clone

#. Clone all repositories
repositories.clone-everything: repositories.clone; @true
.PHONY: repositories.clone-everything

# List all repositories
repositories.list: | $(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).list); @true
.PHONY: repositories.list

#. List all repositories
repositories.list-everything: repositories.list; @true
.PHONY: repositories.list-everything

# Fetch all repositories
repositories.fetch:
	@$(if $(REPOSITORY_FETCH_IN_PARALLEL),REPOSITORY_FETCH_IN_PARALLEL=$(REPOSITORY_FETCH_IN_PARALLEL)) \
		$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" $(if $(REPOSITORY_FETCH_IN_PARALLEL),$(MAKE_PARALLELISM_OPTIONS)) \
		$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).fetch)
.PHONY: repositories.fetch

#. Fetch all repositories
repositories.fetch-everything: repositories.fetch; @true
.PHONY: repositories.fetch-everything

# Pull all repositories
repositories.pull:
	@$(if $(REPOSITORY_PULL_IN_PARALLEL),REPOSITORY_PULL_IN_PARALLEL=$(REPOSITORY_PULL_IN_PARALLEL)) \
		$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" $(if $(REPOSITORY_PULL_IN_PARALLEL),$(MAKE_PARALLELISM_OPTIONS)) \
		$(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).pull)
.PHONY: repositories.pull

#. Pull all repositories
repositories.pull-everything: repositories.pull; @true
.PHONY: repositories.pull-everything

# Stash files in all repositories
repositories.stash:
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" $(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).stash)
.PHONY: repositories.stash

#. Stash files in all repositories
repositories.stash-everything: repositories.stash; @true
.PHONY: repositories.stash-everything

# Remove files in all repositories
repositories.remove: | $(foreach repository,$(REPOSITORY_NAMES),repository.$(repository).remove); @true
.PHONY: repositories.remove

#. Remove files in all repositories
repositories.remove-everything: repositories.remove; @true
.PHONY: repositories.remove-everything
endif
endif

ifneq ($(REPOSITORY_self),)
# List this repository
repository.list: | repository.$(REPOSITORY_self).list; @true
.PHONY: repository.list

# Fetch this repository
repository.fetch: | repository.$(REPOSITORY_self).fetch; @true
.PHONY: repository.fetch

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
