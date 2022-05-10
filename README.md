## Installation
        
Add the following in your project's makefile:

```makefile
###
##. Configuration
###

#. This installs/updates the included makefiles
MAKEFILES_REPOSITORY:=https://github.com/phpqa/makefiles.git
MAKEFILES_DIRECTORY:=.makefiles
MAKEFILES_TAG:=v0.2.8
MAKEFILES_LOG:=$(shell \
	if test ! -d $(MAKEFILES_DIRECTORY); then git clone $(MAKEFILES_REPOSITORY) "$(MAKEFILES_DIRECTORY)"; fi; \
	cd "$(MAKEFILES_DIRECTORY)"; \
	if test -z "$$(git --no-pager describe --always --dirty | grep "^$(MAKEFILES_TAG)")"; then git fetch --all --tags; git reset --hard "tags/$(MAKEFILES_TAG)"; fi \
)

#. This section contains the variables required by the included makefiles, before including the makefiles themselves.
#. In this case, these variables define the own directory as repository to update with the commands in git.makefile
REPOSITORIES=self
REPOSITORY_DIRECTORY_self=.

#. At least include the includes/base.makefile and includes/git.makefile files
include $(MAKEFILES_DIRECTORY)/builtins.makefile  # Reset the default makefile builtins
include $(MAKEFILES_DIRECTORY)/base.makefile      # Base functionality
include $(MAKEFILES_DIRECTORY)/git.makefile       # Git management
```

Add the directory mentioned in the MAKEFILES_DIRECTORY variable to your .gitignore file:

```.gitignore
/.makefiles
```

Run the following command to see if it works:

```shell
make help
```
