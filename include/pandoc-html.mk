# This adds recipes for generating HTML documents, plus styles, favicons and
# index pages.

ifeq (,$(filter %/pandoc.mk pandoc.mk,$(MAKEFILE_LIST)))
$(error The main pandoc.mk module was not loaded)
endif

ifneq (,$(wildcard $(SRC)/favicon.*))
EXTRA_LINKED+=$(addprefix $(DEST)/,favicon.ico apple-touch-icon.png)
endif

$(DEST)/%.css: $(STYLE_DIR)/%.scss $(wildcard $(STYLE_DIR)/_*.scss)
	@-mkdir -p $(@D)
	sassc --style compressed $< $@

EXTRA_LINKED+=$(DEST)/index.html
$(DEST)/index.html: $(CACHE)/index.json $(PANDOC_DIR)/page.html $(PANDOC_DIR)/nav.html $(DEST)/web.css
	@-mkdir -p $(@D)
	@echo "Generating index page \"$@\"..." 1>&2
	@echo | pandoc \
		--template="$(PANDOC_DIR)/page.html" \
		--metadata-file "$(CACHE)/index.json" \
		--metadata title="Table of contents" \
		$(if $(findstring favicon,$(EXTRA_LINKED)),--metadata favicon='$(shell realpath $(DEST)/favicon.ico --relative-to $(@D) --canonicalize-missing)') \
		--metadata style='web' \
		> $@

$(DEST)/%.html: \
		$(SRC)/%.md \
		$(PANDOC_DIR)/page.html \
		$(wildcard $(SRC)/*.bib) \
		$(PANDOC_DIR)/dry-links.lua
	@echo "Generating document \"$@\"..." 1>&2
	@-mkdir -p "$(@D)"
	@-mkdir -p "$(patsubst $(DEST)/%,$(CACHE)/%,$(@D))"
	@pandoc  \
		--metadata path='$(shell realpath $(@D) --relative-to $(DEST) --canonicalize-missing)' \
		--metadata root='$(shell realpath $(DEST) --relative-to $(@D) --canonicalize-missing)' \
		--metadata index='$(shell realpath $(DEST)/index.html --relative-to $(@D) --canonicalize-missing)' \
		--metadata last-modified='$(shell date -r "$<" '+%Y-%m-%d')' \
		$(EXTRA_PANDOC_ARGS) \
		$(if $(wildcard $(SRC)/favicon.*),--metadata favicon='$(shell realpath $(DEST)/favicon.ico --relative-to $(@D) --canonicalize-missing)') \
		--from markdown+smart+fenced_divs+inline_notes+table_captions \
		--to html5 \
		--standalone \
		--template '$(PANDOC_DIR)/page.html' \
		--filter pandoc-citeproc \
		$(foreach F,\
			$(filter %.bib, $^),\
			--bibliography='$(F)' \
		)\
		$(foreach F,$(filter %.lua, $^), --lua-filter='$(F)') \
		--shift-heading-level-by=1 \
		--ascii \
		--strip-comments \
		--email-obfuscation=references \
		--highlight-style=kate \
		$< \
		| sed ':a;N;$$!ba;s|>\s*<|><|g' \
		> $@

