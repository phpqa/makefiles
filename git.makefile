###
##. Configuration
###

GIT_EXECUTABLE?=$(shell command -v git || which git 2>/dev/null || printf "%s" "git")

DIRECTORIES?=

###
## Git
###

# TODO make it optional to use stashes

# Pull the repository
$(foreach dir,$(DIRECTORIES),$(dir)/.git):%/.git: | $(GIT_EXECUTABLE)
	@printf "%s\\n" "Cloning into $(*)..."
	@if test -z "$(REPOSITORY_URL_FOR_DIRECTORY_$(*))"; then \
		printf "%s\\n" "Could not find variable REPOSITORY_URL_FOR_DIRECTORY_$(*)!"; \
		exit 1; \
	else \
		$(GIT_EXECUTABLE) clone $(REPOSITORY_URL_FOR_DIRECTORY_$(*)) $(*); \
	fi

# Clone all repositories
clone: $(foreach dir,$(DIRECTORIES),$(dir)/.git)
	@true

# Pull the repository
$(foreach dir,$(DIRECTORIES),pull-$(dir)):pull-%: | %/.git $(GIT_EXECUTABLE)
	$(eval $(@)_DEFAULT_BRANCH:=$(shell cd "$(*)" && $(GIT_EXECUTABLE) remote show origin | sed -n '/HEAD branch/s/.*: //p'))
	@if test -n '$($(@)_DEFAULT_BRANCH)'; then \
		printf "%s\\n" "Pulling '$($(@)_DEFAULT_BRANCH)' branch into $(*)..." \
		&& cd "$(*)" \
		&& ( $(GIT_EXECUTABLE) pull origin $($(@)_DEFAULT_BRANCH) || true ) \
		$(if $(LOG),&& $(GIT_EXECUTABLE) log -1) \
		&& echo \
		&& sleep 1; \
	else \
		printf "%s\\n" "Could not determine branch for $(*)!"; \
	fi

# Pull all repositories
pull: $(foreach dir,$(DIRECTORIES),pull-$(dir))
	@true
