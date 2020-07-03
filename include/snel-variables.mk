# This sets the variables that all of `snel` needs; included by every file.

# Location of this makefile
BASE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Installation directories
PREFIX := /usr/local
INCLUDE_DIR := $(PREFIX)/include
SHARE_DIR := $(PREFIX)/share/snel

# If installed in $PREFIX/include, we find other assets in $PREFIX/share/snel.
# Otherwise, we find them relative to the current makefile
ifeq ($(BASE_DIR),$(INCLUDE_DIR))
    ASSET_DIR := $(SHARE_DIR)
    JQ_DIR := $(SHARE_DIR)
    PANDOC_DIR := $(SHARE_DIR)/pandoc
else
    ASSET_DIR := $(BASE_DIR)/../share
    JQ_DIR := $(BASE_DIR)/../share
    PANDOC_DIR := $(BASE_DIR)/../share/pandoc
endif

# Source and destination directories, and FTP credentials. These are
# expected to be changed in the `make` call or before the `include` statement.
ifndef SRC
    SRC := .
endif
ifndef DEST
    DEST := build
endif
ifndef STYLE
    STYLE := letter
endif
ifndef CACHE
    CACHE := $(DEST)/cache
endif
ifndef IGNORE
    IGNORE=Makefile .git .gitignore
endif
ifndef HIDE_WEB_INFO
	HIDE_WEB_INFO=
endif
