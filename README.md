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
include $(MAKEFILES_DIRECTORY)/builtins.makefile     # Reset the default makefile builtins
include $(MAKEFILES_DIRECTORY)/base.makefile         # Base functionality

#. This section contains the variables required by the included makefiles, before including the makefiles themselves.
#. In this case, these variables define the own directory as repository to update with the commands in git.makefile
REPOSITORIES=self
REPOSITORY_DIRECTORY_self=.

#. Then include the repositories.makefile file

include $(MAKEFILES_DIRECTORY)/repositories.makefile # Repositories management
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
