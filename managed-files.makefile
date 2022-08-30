###
##. Dependencies
###

#. POSIX dependencies - @see https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html
define check-managed-files-command
ifeq ($$(shell command -v $(1) || which $(1) 2>/dev/null),)
$$(error Please provide the command "$(1)" before including the "managed-files.makefile" file)
endif
endef
$(foreach command,mkdir find sort tail diff cp,$(eval $(call check-managed-files-command,$(command))))

###
##. Configuration
###

MANAGED_FILES?=$(if $(GIT),$(shell $(GIT) clean -nX 2>/dev/null | sed 's/Would remove //'))
MANAGED_FILES_ORIGIN_DIRECTORY?=.
MANAGED_FILES_BACKUP_DIRECTORY?=./.backups
MANAGED_FILES_BACKUP_EXTENSION?=.bck

###
##. Requirements
###

ifeq ($(MANAGED_FILES_ORIGIN_DIRECTORY),)
$(error Please provide the variable MANAGED_FILES_ORIGIN_DIRECTORY before including this file!)
endif
ifeq ($(MANAGED_FILES_BACKUP_DIRECTORY),)
$(error Please provide the variable MANAGED_FILES_BACKUP_DIRECTORY before including this file!)
endif
ifeq ($(MANAGED_FILES_BACKUP_EXTENSION),)
$(error Please provide the variable MANAGED_FILES_BACKUP_EXTENSION before including this file!)
endif

###
##. Functions
###

# $(1) is the relative file path from the MANAGED_FILES_ORIGIN_DIRECTORY
back-up-managed-file=\
	FILENAME="$(1)"; \
	if test ! -f "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; then \
		printf "$(STYLE_WARNING)%s\033[0m\n" "Could not find the file \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}\", skipped making a backup..."; \
	else \
		mkdir -p "$(MANAGED_FILES_BACKUP_DIRECTORY)"; \
		LATEST_BACKUP_FILE="$$(find "$(MANAGED_FILES_BACKUP_DIRECTORY)" -name "$${FILENAME}.*$(MANAGED_FILES_BACKUP_EXTENSION)" 2>/dev/null | sort | tail -1)"; \
		if test -z "$${LATEST_BACKUP_FILE}" || ! diff -q "$(1)" "$${LATEST_BACKUP_FILE}" &>/dev/null; then \
			NEW_BACKUP_FILE="$(MANAGED_FILES_BACKUP_DIRECTORY)/$${FILENAME}.$$(date +%s)$(MANAGED_FILES_BACKUP_EXTENSION)"; \
			cp "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}" "$${NEW_BACKUP_FILE}"; \
			printf "$(STYLE_SUCCESS)%s\033[0m\n" "The file \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}\" was backed up to \"$${NEW_BACKUP_FILE}\"."; \
		fi; \
	fi
# $(1) is the relative file path from the MANAGED_FILES_ORIGIN_DIRECTORY
recover-managed-file=\
	FILENAME="$(1)"; \
	if test -f "$(MANAGED_FILES_BACKUP_DIRECTORY)/$${FILENAME}"; then \
		if ! diff -q "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}" "$(MANAGED_FILES_BACKUP_DIRECTORY)/$${FILENAME}" &>/dev/null; then \
			if test -f "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; then \
				$(call back-up-managed-file,$${FILENAME}); \
			fi; \
			cp "$(MANAGED_FILES_BACKUP_DIRECTORY)/$${FILENAME}" "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; \
			printf "$(STYLE_SUCCESS)%s\033[0m\n" "Updated the file \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}\" from \"$(MANAGED_FILES_BACKUP_DIRECTORY)/$${FILENAME}\". The old version was backed up."; \
		fi; \
	else \
		LATEST_BACKUP_FILE="$$(find "$(MANAGED_FILES_BACKUP_DIRECTORY)" -wholename "$(MANAGED_FILES_BACKUP_DIRECTORY)/$${FILENAME}.*$(MANAGED_FILES_BACKUP_EXTENSION)" 2>/dev/null | sort | tail -1)"; \
		if test -f "$${LATEST_BACKUP_FILE}"; then \
			if ! diff -q "$${LATEST_BACKUP_FILE}" "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}" &>/dev/null; then \
				if test -f "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; then \
					$(call back-up-managed-file,$${FILENAME}); \
				fi; \
				cp "$${LATEST_BACKUP_FILE}" "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; \
				printf "$(STYLE_SUCCESS)%s\033[0m\n" "Updated the file \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}\" from \"$${LATEST_BACKUP_FILE}\"."; \
			fi; \
		else \
			if test -f "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}.dist"; then \
				cp "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}.dist" "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; \
				printf "$(STYLE_SUCCESS)%s\033[0m\n" "Created the file \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}\" from \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}.dist\"."; \
			else \
				printf "$(STYLE_WARNING)%s\033[0m\n" "Please create the file \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}\" manually."; \
				exit 1; \
			fi; \
		fi; \
	fi; \
	touch "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"
# $(1) is the relative file path from the MANAGED_FILES_ORIGIN_DIRECTORY
remove-managed-file=\
	FILENAME="$(1)"; \
	if test -f "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; then \
		$(call back-up-managed-file,$${FILENAME}); \
		rm -f "$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}"; \
		printf "$(STYLE_SUCCESS)%s\033[0m\n" "Removed the file \"$(MANAGED_FILES_ORIGIN_DIRECTORY)/$${FILENAME}\"."; \
	fi

###
## Managed Files
###

ifneq ($(MANAGED_FILES),)
#. Create the backups directory
$(MANAGED_FILES_BACKUP_DIRECTORY):
	@mkdir -p "$(@)"

# Back up the file %
$(foreach file,$(MANAGED_FILES),$(file).back-up):%.back-up: % | $(MANAGED_FILES_BACKUP_DIRECTORY)
	@$(call back-up-managed-file,$(*))

# Recover the file %
$(foreach file,$(MANAGED_FILES),$(file).recover):%.recover:
	@$(call recover-managed-file,$(*))

# Remove the file %
$(foreach file,$(MANAGED_FILES),$(file).remove):%.remove:
	@$(call remove-managed-file,$(*))
endif

# List all managed files
managed-files.list:
	@$(foreach file,$(MANAGED_FILES),printf "%s\n" "$(file)";)
.PHONY: managed-files.list

# Back up all managed files
managed-files.back-up: | $(foreach file,$(MANAGED_FILES),$(file).back-up)
	@true
.PHONY: managed-files.back-up

# Recover all managed files
managed-files.recover: | $(foreach file,$(MANAGED_FILES),$(file).recover)
	@true
.PHONY: managed-files.recover

# Remove all managed files, keep backups
managed-files.remove: | $(foreach file,$(MANAGED_FILES),$(file).remove)
	@true
.PHONY: managed-files.remove
