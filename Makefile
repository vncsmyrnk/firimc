OUTPUT_DIR ?= dist
APP_DIR := $(OUTPUT_DIR)/firefox-minimal
INSTALL_DIR ?= $(HOME)/.local/firefox-minimal
RUN_ARGS ?=

.PHONY: build run install test

build:
	./scripts/build-prototype.sh "$(OUTPUT_DIR)"

run: build
	"$(APP_DIR)/launch.sh" $(RUN_ARGS)

install: build
	./scripts/install-prototype.sh "$(APP_DIR)" "$(INSTALL_DIR)"

test:
	bash tests/profile-assets.test.sh && \
	bash tests/build-prototype.test.sh && \
	bash tests/launch-prototype.test.sh && \
	bash tests/install-prototype.test.sh && \
	bash tests/makefile.test.sh && \
	bash tests/readme.test.sh
