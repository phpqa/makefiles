## Installation
        
Add the following in your project's makefile:

```makefile
###
##. Makefiles
###

#. Install and update the makefiles
MAKEFILES_REPOSITORY:=https://github.com/phpqa/makefiles.git
MAKEFILES_DIRECTORY:=$(abspath $(dir $(firstword $(MAKEFILE_LIST)))/.makefiles)
MAKEFILES_TAG:=$(shell git ls-remote --tags --refs --sort="version:refname" "$(MAKEFILES_REPOSITORY)" "v*.*.*" | tail -n 1 | awk -F/ '{ print $$3 }')
MAKEFILES_LOG:=$(shell \
	if test ! -d $(MAKEFILES_DIRECTORY); then git clone $(MAKEFILES_REPOSITORY) "$(MAKEFILES_DIRECTORY)"; fi; \
	if test -n "$(MAKEFILES_TAG)" && test -z "$$(git -C "$(MAKEFILES_DIRECTORY)" --no-pager describe --tags --always --dirty | grep "^$(MAKEFILES_TAG)")"; then \
		git -C "$(MAKEFILES_DIRECTORY)" fetch --all --tags; \
		git -C "$(MAKEFILES_DIRECTORY)" reset --hard "tags/$(MAKEFILES_TAG)"; \
	fi \
)

###
## About
###

#. Load the base and help makefiles
include $(MAKEFILES_DIRECTORY)/base.makefile
include $(MAKEFILES_DIRECTORY)/help.makefile
```

Change the MAKEFILES_TAG variable to the latest tag of this project, or the tag of the version you want to use:

```makefile
MAKEFILES_TAG:=v0.0.0
```

Add the directory mentioned in the MAKEFILES_DIRECTORY variable to your .gitignore file:

```.gitignore
/.makefiles
```

Run the following command to see if it works:

```shell
make help
```

## Other makefiles

### `include $(MAKEFILES_DIRECTORY)/help.makefile`

Automatically load the documentation from all included makefiles.

### `include $(MAKEFILES_DIRECTORY)/env.makefile`

Read variables from a .env file.

### `include $(MAKEFILES_DIRECTORY)/repositories.makefile`

Clone and pull your repositories.

### `include $(MAKEFILES_DIRECTORY)/parent-makefile.makefile`

Add a makefile to the parent directory to redirect

## Planned

- Replace @ by $(-)
- bin/php should detect docker-compose vs docker compose on the fly, and it should fallback to the local php if none of the other options are available
- bin/php should always be the same file, and it should save the builded image, if ever it cannot run directly on compose
- define variables warned for with --warn-undefined-variables in the base.makefile
- stop using the @ to silence commands, but use the .SILENT: target? does that work?
- What happens if you use the makefile from another repo, that has not yet loaded the .makefiles subfolder?
- Add DOCKER_CONFIG as a volume to any container that needs to pull images from remote registries
- Use docker container names, instead of docker-compose service names to depend upon
- create a simple phpqa image with some simple tools: make, git, curl...
- Check the undocumented dependencies
- Limit the dependencies on make and docker, by using a make image with docker daemon forwarding to the host
- Add phars for the different tools
- make it possible to run the phpqa tools from common, by setting the php directory
- use phar files for tools that have them
