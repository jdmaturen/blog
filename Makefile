# Configuration
HUGO_VERSION ?= 0.14
HUGO_THEME ?= ""
GIT_COMMITTER_NAME ?= autohugo
GIT_COMMITTER_EMAIL ?= autohugo@autohugo.local

# System
OS = amd64
ifeq ($(OS),Windows_NT)
    ARCH = windows
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
			ARCH = linux
    endif
    ifeq ($(UNAME_S),Darwin)
			ARCH = darwin
    endif
endif

# Environment
SHELL := /bin/bash
BASE_PATH := $(shell pwd)
PUBLIC_PATH := $(BASE_PATH)/public
THEMES_PATH := $(BASE_PATH)/themes
THEME_NAME := $(shell basename $(HUGO_THEME))
THEME_PATH := $(THEMES_PATH)/$(THEME_NAME)
HUGO_PATH := $(BASE_PATH)/.hugo
HUGO_URL = github.com/spf13/hugo
HUGO_NAME := hugo_$(HUGO_VERSION)_$(ARCH)_$(OS)

# Tools
CURL = curl -L
HUGO = $(HUGO_PATH)/$(HUGO_NAME)/$(HUGO_NAME)
MKDIR = mkdir -p
GIT = git

# Rules
all: build

init:
	@if [ "$(HUGO_THEME)" == "" ]; then \
		echo "Please set the env variable 'HUGO_THEME' (http://mcuadros.github.io/autohugo/documentation/working-with-autohugo/)"; \
	  exit 1; \
	fi;

dependencies: init
	@if [[ ! -f $(HUGO) ]]; then \
		$(MKDIR) $(HUGO_PATH); \
		cd $(HUGO_PATH); \
		ext="zip"; \
		if [ "$(ARCH)" == "linux" ]; then ext="tar.gz"; fi; \
		file="hugo.$${ext}"; \
		$(CURL) https://$(HUGO_URL)/releases/download/v$(HUGO_VERSION)/$(HUGO_NAME).$${ext} -o $${file}; \
		if [ "$(ARCH)" == "linux" ]; then tar -xvzf $${file}; else unzip $${file}; fi; \
	fi;
	@if [[ ! -d $(THEME_PATH) ]]; then \
		$(MKDIR) $(THEMES_PATH); \
		cd $(THEMES_PATH); \
		$(GIT) clone $(HUGO_THEME) $(THEME_NAME); \
	fi;

build: dependencies
	$(HUGO) -t $(THEME_NAME)

server: build
	$(HUGO) server -t $(THEME_NAME) -D -w

publish: init
	cp -rf $(THEME_PATH)/static/* $(PUBLIC_PATH)/
	mv .gitignore .gitignore.inactive
	$(GIT) commit -m "updating site [ci skip]" --author="$(GIT_COMMITTER_NAME) <$(GIT_COMMITTER_EMAIL)>" -a
	mv .gitignore.inactive .gitignore
	$(GIT) push origin :gh-pages
	$(GIT) subtree push --prefix=public git@github.com:$(CIRCLE_PROJECT_USERNAME)/$(CIRCLE_PROJECT_REPONAME).git gh-pages
	$(GIT) reset --soft HEAD~1
clean:
	rm -rf $(HUGO_PATH)
	rm -rf $(THEME_PATH)
