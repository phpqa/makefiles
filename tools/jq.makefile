###
##. Configuration
###

JQ_DETECTED?=$(shell command -v jq || which jq 2>/dev/null)
JQ_DEPENDENCY?=$(if $(JQ_DETECTED),jq.assure-usable,$(if $(DOCKER_DETECTED),$(DOCKER_DEPENDENCY),jq.not-found))
JQ?=$(if $(JQ_DETECTED),jq,$(if $(DOCKER_DETECTED),$(DOCKER) run --rm --interactive stedolan/jq:latest))

###
##. Requirements
###

ifeq ($(JQ),)
$(error The variable JQ should never be empty.)
endif
ifeq ($(JQ_DEPENDENCY),)
$(error The variable JQ_DEPENDENCY should never be empty.)
endif

###
## Repositories
###

#. Exit if jq is not found
jq.not-found:
	@printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Please install jq."
	@exit 1
.PHONY: jq.not-found

#. Assure that jq is usable
jq.assure-usable:
	@if test -z "$$($(JQ) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use JQ as "$(value JQ)".'; \
		exit 1; \
	fi
.PHONY: jq.assure-usable
