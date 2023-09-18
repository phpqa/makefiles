###
##. Configuration
###

LC_ALL?=C
GIT_SSH_COMMAND?=ssh -o ControlPath=$(if $(PARALLEL),no,~/.ssh/make_%r@%h_%p) -o ControlPersist=10s

GIT_COMMAND?=git
ifeq ($(GIT_COMMAND),)
$(error The variable GIT_COMMAND should never be empty)
endif

GIT_DETECTED?=$(eval GIT_DETECTED:=$$(shell command -v $(GIT_COMMAND) || which $(GIT_COMMAND) 2>/dev/null))$(GIT_DETECTED)
GIT_DEPENDENCY?=$(if $(GIT_DETECTED),git.assure-usable,git.not-found)
ifeq ($(GIT_DEPENDENCY),)
$(error The variable GIT_DEPENDENCY should never be empty)
endif

GIT?=$(if $(GIT_COMMAND),LC_ALL=$(LC_ALL) $(if $(GIT_SSH_COMMAND),GIT_SSH_COMMAND="$(GIT_SSH_COMMAND)" )$(GIT_COMMAND))
ifeq ($(GIT),)
$(error The variable GIT should never be empty)
endif

GIT_DIRECTORY?=.git
ifeq ($(GIT_DIRECTORY),)
$(error The variable GIT_DIRECTORY should never be empty)
endif

###
##. Git
##. Free and open source distributed version control system
##. @see https://git-scm.com/
###

#. Exit if GIT_COMMAND is not found
git.not-found:
	@printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Please install git."
	@exit 1
.PHONY: git.not-found

#. Assure that GIT is usable
git.assure-usable:
	@if test -z "$$($(GIT) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use git as "$(value GIT)".'; \
		$(GIT) --version; \
		exit 1; \
	fi
.PHONY: git.assure-usable
