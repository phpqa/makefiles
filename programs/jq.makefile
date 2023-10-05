###
##. jq
##. Lightweight and flexible command-line JSON processor
##. @see https://stedolan.github.io/jq/
###

COMMAND_NAMES+=jq
COMMAND_VARIABLE_PREFIX_jq:=JQ
ifndef JQ
JQ_DEFAULT_COMMAND:=jq
JQ_DIRECTORY?=.
JQ?=$(eval JQ:=$$(strip\
	$$(if $$(wildcard $$(filter-out .,$$(JQ_DIRECTORY))),cd "$$(JQ_DIRECTORY)" && ) \
	$$(shell $$(if $$(JQ_DIRECTORY),cd "$$(JQ_DIRECTORY)" && ) (\
		command -v $(JQ_DEFAULT_COMMAND) \
		|| which $(JQ_DEFAULT_COMMAND) 2>/dev/null \
		$$(if $$(and $$(DOCKER),$$(JQ_IMAGE_TAG)), || printf "%s" "bin/jq") \
	) ) \
))$(JQ)
endif
JQ_DEPENDENCY?=$(eval JQ_DEPENDENCY:=$$(if $$($JQ),jq.assure-usable,jq.not-found))$(JQ_DEPENDENCY)
JQ_USABILITY_CHECK_COMMAND?=$(JQ) --version 2>&1
JQ_IMAGE_VERSION?=
JQ_IMAGE_TAG?=ghcr.io/jqlang/jq:$(or $(JQ_IMAGE_VERSION),latest)
JQ_CONTAINER_RUN_FLAGS?=--version
