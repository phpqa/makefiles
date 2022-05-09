## Installation
        
Add the following in your project's makefile:

```makefile
###
##. Includes
###

ifeq ($(wildcard includes),)
#. This installs the includes directory during first run on a new system
SILENT_INSTALL:=$(shell git clone $(REPOSITORY_URL_includes) includes && $(MAKE) pull)
endif

#. These settings define the own directory and the includes directory as repositories to update
REPOSITORIES=self includes
REPOSITORY_DIRECTORY_self=.
REPOSITORY_DIRECTORY_includes=./includes
REPOSITORY_URL_includes=https://github.com/phpqa/includes.git
REPOSITORY_TAG_includes=v0.2.*

#. At least include the includes/base.makefile and includes/git.makefile files
include includes/builtins.makefile  # Reset the default makefile builtins
include includes/base.makefile      # Base functionality
include includes/git.makefile       # Git management
```

Add the includes directory to your .gitignore file:

```.gitignore
/includes
```

Run the following command to see if it works:

```shell
make help
```
