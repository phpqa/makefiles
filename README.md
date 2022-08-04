## Installation
        
Add the following in your project's makefile:

```makefile
###
##. Configuration
###

#. This installs/updates the included makefiles
MAKEFILES_REPOSITORY:=https://github.com/phpqa/makefiles.git
MAKEFILES_DIRECTORY:=.makefiles
MAKEFILES_TAG:=$(shell git ls-remote --tags --refs --sort="version:refname" "$(MAKEFILES_REPOSITORY)" "v*.*.*" | tail -n 1 | awk -F/ '{ print $$3 }')
MAKEFILES_LOG:=$(shell \
	if test ! -d $(MAKEFILES_DIRECTORY); then git clone $(MAKEFILES_REPOSITORY) "$(MAKEFILES_DIRECTORY)"; fi; \
	if test -n "$(MAKEFILES_TAG)" && test -z "$$(git -C "$(MAKEFILES_DIRECTORY)" --no-pager describe --always --dirty | grep "^$(MAKEFILES_TAG)")"; then \
		git -C "$(MAKEFILES_DIRECTORY)" fetch --all --tags; \
		git -C "$(MAKEFILES_DIRECTORY)" reset --hard "tags/$(MAKEFILES_TAG)"; \
	fi \
)

#. At least include the base.makefile file
include $(MAKEFILES_DIRECTORY)/base.makefile         # Provide some base functionality
include $(MAKEFILES_DIRECTORY)/help.makefile         # Provide documentation automatically
include $(MAKEFILES_DIRECTORY)/repositories.makefile # Add repository management
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

## Planned

- What happens if you use the makefile from another repo, that has not yet loaded the .makefiles subfolder?
- Add DOCKER_CONFIG as a volume to any container that needs to pull images from remote registries
- Use docker container names, instead of docker-compose service names to depend upon
- Check the undocumented dependencies
- Add phars for the different tools
- Add docker wait until the sidecars are exiting - and check on its exit code, return an error message
