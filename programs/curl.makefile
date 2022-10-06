###
##. Configuration
###

CURL_COMMAND?=curl
ifeq ($(CURL_COMMAND),)
$(error The variable CURL_COMMAND should never be empty)
endif

CURL_DETECTED?=$(shell command -v $(CURL_COMMAND) || which $(CURL_COMMAND) 2>/dev/null)
CURL_DEPENDENCY?=$(if $(CURL_DETECTED),curl.assure-usable,curl.not-found)
ifeq ($(CURL_DEPENDENCY),)
$(error The variable CURL_DEPENDENCY should never be empty)
endif

CURL?=$(CURL_COMMAND)
ifeq ($(CURL),)
$(error The variable CURL should never be empty)
endif

###
##. curl
##. Command line tool and library for transferring data with URLs
##. @see https://curl.se/
##. @see https://hub.docker.com/r/curlimages/curl
###

#. Exit if CURL_COMMAND is not found
curl.not-found:
	@printf "$(STYLE_ERROR)%s$(STYLE_RESET)\\n" "Please install curl."
	@exit 1
.PHONY: curl.not-found

#. Assure that CURL is usable
curl.assure-usable:
	@if test -z "$$($(CURL) --version 2>/dev/null || true)"; then \
		printf "$(STYLE_ERROR)%s$(STYLE_RESET)\n" 'Could not use curl as "$(value CURL)".'; \
		exit 1; \
	fi
.PHONY: curl.assure-usable
