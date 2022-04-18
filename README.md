## Installation
        
Add the following in your project's makefile:

```makefile
###
##. Includes
###

ifeq ($(wildcard includes),)
$(shell git clone git@github.com:phpqa/includes.git)
endif

include includes/builtins.makefile
include includes/base.makefile
include includes/docker-compose.makefile
```

Run the following command to see if it works:

```shell
make help
```
