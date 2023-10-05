###
##. curl
##. Command line tool and library for transferring data with URLs
##. @see https://curl.se/
##. @see https://hub.docker.com/r/curlimages/curl
###

COMMAND_NAMES+=curl
COMMAND_VARIABLE_PREFIX_curl:=CURL
ifndef CURL
CURL_DEFAULT_COMMAND:=curl
CURL_DIRECTORY?=.
CURL?=$(eval CURL:=$$(strip\
	$$(if $$(wildcard $$(filter-out .,$$(CURL_DIRECTORY))),cd "$$(CURL_DIRECTORY)" && ) \
	$$(shell $$(if $$(CURL_DIRECTORY),cd "$$(CURL_DIRECTORY)" && ) (\
		command -v $(CURL_DEFAULT_COMMAND) \
		|| which $(CURL_DEFAULT_COMMAND) 2>/dev/null \
		$$(if $$(and $$(DOCKER),$$(CURL_IMAGE_TAG)), || printf "%s" "bin/curl") \
	) ) \
))$(CURL)
endif
CURL_DEPENDENCY?=$(eval CURL_DEPENDENCY:=$$(if $$($CURL),curl.assure-usable,curl.not-found))$(CURL_DEPENDENCY)
CURL_USABILITY_CHECK_COMMAND?=$(CURL) --version 2>&1
CURL_IMAGE_VERSION?=
CURL_IMAGE_TAG?=curlimages/curl:$(or $(CURL_IMAGE_VERSION),latest)
CURL_CONTAINER_RUN_FLAGS?=--rm --interactive --tty
