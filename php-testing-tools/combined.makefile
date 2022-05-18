###
## PHP Testing Tools
## ! If you include this file, always include it AFTER the makefiles of the tools
###

# Run all tests
php.test: \
	$(if $(PHPUNIT),phpunit) \

.PHONY: php.test
