###
## Help
###

# TODO Undocumented dependencies: awk, sort

.DEFAULT_GOAL:=help
HELP_TARGETS_TO_SKIP+=
HELP_FIRST_COLUMN_WIDTH?=34

# Show this help
help:
	@awk \
		-v show_pattern="$$($(MAKE) --file="$(firstword $(MAKEFILE_LIST))" list-make-targets-as-database | awk -F ";" '/^[a-zA-Z0-9_%\/\.-]+/{ if (skipped) printf "|"; printf "^%s:", $$3; skipped=1 }')" \
		-v skip_pattern="$(subst $(subst ,, ),|,$(foreach target,$(HELP_TARGETS_TO_SKIP),^$(target):))" \
		-v style_title="$(STYLE_TITLE)" \
		-v style_dim="$(STYLE_DIM)" \
		-v style_warning="$(STYLE_WARNING)" \
		-v style_reset="$(STYLE_RESET)" \
		-v title_length="$(HELP_FIRST_COLUMN_WIDTH)" \
		' \
			{ if (length(show_pattern) == 0) { show_pattern="empty" } } \
			{ if (length(skip_pattern) == 0) { skip_pattern="empty" } } \
			{ if (/^## /) { if (title_block != "true") { title=$$0; title_block="true" }; next } else { title_block="false" } } \
			{ if (/^$$/) { skip="false"; doc=""; next } } \
			{ if (/^#\. / && doc == "") { skip="true"; next } } \
			{ if (/^# / && doc == "") { skip="false"; indent=""; doc=substr($$0,3); next } } \
			{ if (/^#[^\.\s]+ / && doc == "") { skip="false"; indent=substr($$1,2)" "; doc=substr($$0,3+length(indent)-1); next } } \
			{ if (/^# @see / && doc) { link=substr($$0,8) } } \
			{ if ($$0 ~ show_pattern && $$0 !~ skip_pattern) { \
				if (skip == "true") { skip="false"; doc=""; next } \
				if (title != "") { if (title != last_title) { printf "\n%s\n",substr(title,4) }; last_title=title }; \
				gsub(/:.*/,"",$$1); \
				printf style_dim "%s" style_reset style_title "%-*s" style_reset, indent, title_length - length(indent), $$1; \
				if (doc == "") { doc=style_dim "No documentation" style_reset }; \
				if (doc ~ /# TODO/) { doc=substr(doc,1,match(doc,/# TODO/)-1) }; \
				if (doc ~ /#!/) { warning="$(ICON_WARNING)" substr(doc,match(doc,/#!/)+2); doc=substr(doc,1,match(doc,/#!/)-1) } ; \
				if (link) { printf " \033]8;;%s\033\\%s\033]8;;\033\\", link, doc } else { printf " %s", doc }; \
				if (warning) { printf style_warning "%s" style_reset,warning; }; \
				printf "\n"; \
				link=""; \
				indent=""; \
				doc=""; \
				warning=""; \
			} }; \
		' \
		$(shell $(MAKE) --file="$(firstword $(MAKEFILE_LIST))" list-makefiles)
.PHONY: help

###
##. Debug
###

#. List all included makefiles
list-makefiles:
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" --jobs=1 --always-make --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null \
		| awk -v MAKEFILE_LIST="$(MAKEFILE_LIST)" ' \
			{ if (/^# Variables/) { skip_segment=1 } } \
			{ if (/^# Directories/) { skip_segment=1 } } \
			{ if (/^# Implicit Rules/) { skip_segment=0 } } \
			{ if (/^# Files/) { skip_segment=0 } } \
			{ if (skip_segment==1) { next } } \
			\
			{ if (/^\.PHONY|^\.SUFFIXES|^\.DEFAULT|^\.PRECIOUS/) { next } } \
			{ if (/^[\t]/) { next } } \
			\
			{ if (/^# Not a target:/) { include="yes"; next } } \
			{ if (/^.:/) { next } } \
			{ if (/^([^#]+):/) { if (include=="yes") { match($$0,/:/); file=substr($$0,1,RSTART-1) } } } \
			{ if (/^$$|^[\t]+$$/) { if (file) { search=replace=file; gsub(" ","\\ ",replace); gsub(" "search,"\n*"replace"*\n",MAKEFILE_LIST) }; original=""; file=""; include="no"; } } \
			\
			END { print MAKEFILE_LIST } \
		' \
		| awk '/\*([^\*]+)\*/ { print substr($$1,2,length($$1)-2) }'
.PHONY: list-makefiles

#. List the value for a make variable
list-make-variable-%:
	@printf "$(STYLE_TITLE)%s$(STYLE_RESET)=%s%s\\n" \
		'$(*)' \
		'$($(*))' \
		"$$(if test '$(value $(*))' != '$($(*))'; then printf " $(STYLE_DIM)%s$(STYLE_RESET)\\n" '$(value $(*))'; fi)"

#. List all make variables as semi-colon separated list
list-make-variables-as-database:
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" --jobs=1 --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null \
		| awk ' \
			{ if (/^# Variables/) { skip_segment=0 } } \
			{ if (/^# Directories/) { skip_segment=1 } } \
			{ if (/^# Implicit Rules/) { skip_segment=1 } } \
			{ if (/^# Files/) { skip_segment=1 } } \
			{ if (skip_segment==1) { next } } \
			\
			{ if (/^# makefile \(from/) { \
				match($$0,/makefile \(from [^\)]+, line /); \
				file=substr($$0,RSTART+16,RLENGTH-24); \
				gsub(" ","\\ ",file); \
				match($$0,/line [0-9]+/); \
				line=substr($$0,RSTART+5,RLENGTH-5); \
				source="included"; \
				next \
			} } \
			{ if (/^#/) { \
				file=""; line=""; source=substr($$0,3); \
				next \
			} } \
			\
			{ if (/^[A-Z0-9_-][a-zA-Z0-9_-]+ ?(=|\?=|:=)/ && file && line) { \
				if ($$1 != "MAKEFILE_LIST") { \
					printf "%s;%s;%s;%s\n",file,substr("000000" line, 1 + length(line)),$$1,source; \
				} \
				file=""; line=""; source=""; \
			} } \
		' \
		| sort -t ";" -k 1,1 -k 2,2 -u
.PHONY: list-make-variables-as-database

#. List all make variables
list-make-variables:
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" list-make-variables-as-database \
		| awk -F ";" \
			-v style_underlined="$(STYLE_UNDERLINED)" \
			-v style_reset="$(STYLE_RESET)" \
			' \
				{ \
					if ($$1 != printed_file) { printf "\n" style_underlined "%s" style_reset "\n",$$1; printed_file=$$1 } \
					system("make list-make-variable-" $$3) \
				} \
			'
.PHONY: list-make-variables

#. List all make targets as semi-colon separated list
list-make-targets-as-database:
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" --jobs=1 --always-make --print-data-base --no-builtin-rules --no-builtin-variables : 2>/dev/null \
		| awk ' \
			{ if (/^# Variables/) { skip_segment=1 } } \
			{ if (/^# Directories/) { skip_segment=1 } } \
			{ if (/^# Implicit Rules/) { skip_segment=0 } } \
			{ if (/^# Files/) { skip_segment=0 } } \
			{ if (skip_segment==1) { next } } \
			\
			{ if (/^\.PHONY|^\.SUFFIXES|^\.DEFAULT|^\.PRECIOUS/) { next } } \
			{ if (/^[\t]/) { next } } \
			\
			{ \
				if (/^$$|^[\t]+$$/) { \
					if (command && include=="yes") { \
						printf "%s;%s;%s;%s\n", \
						file ? file : "data-base", \
						line ? substr("000000" line, 1 + length(line)) : substr("000000" NR, 1 + length(NR)), \
						command, \
						is_phony=="yes" ? "phony" : "" \
					}; \
					command=""; \
					include="yes"; \
					is_phony="no"; \
					file=""; \
					line=""; \
				} \
			} \
			{ if (/^([^#]+):/) { match($$0,/:/); command=substr($$0,0,RSTART-1) } } \
			{ if (/^# Not a target:/) { include="no"; next } } \
			{ if (/^#  Phony target/) { is_phony="yes"; next } } \
			{ if (/^#  recipe to execute/) { \
				match($$0,/from [^[:alnum:]][^\)]+[^[:alnum:]],/); \
				file=substr($$0,RSTART+6,RLENGTH-8); \
				gsub(" ","\\ ",file); \
				match($$0,/line [0-9]+/); \
				line=substr($$0,RSTART+5,RLENGTH-5); \
				next \
			} } \
		' \
		| sort -t ";" -k 1,1 -k 2,2 -u
.PHONY: list-make-targets-as-database

#. List all make targets
list-make-targets:
	@$(MAKE) --file="$(firstword $(MAKEFILE_LIST))" list-make-targets-as-database  \
		| awk -F ";" \
			-v style_underlined="$(STYLE_UNDERLINED)" \
			-v style_title="$(STYLE_TITLE)" \
			-v style_warning="$(STYLE_WARNING)" \
			-v style_reset="$(STYLE_RESET)" \
			' \
				{ \
					{ if ($$1 != printed_file) { printf "\n" style_underlined "%s" style_reset "\n",$$1; printed_file=$$1 } } \
					{ printf "%s%s\n",style_title $$3 style_reset,$$4=="phony"?style_warning "*" style_reset:"" } \
				} \
			'
.PHONY: list-make-targets
