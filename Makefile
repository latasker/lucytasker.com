BUILD_DIR := build
SITE_DIR := site

# Assume that soupault is somewhere in $PATH
SOUPAULT := soupault

.PHONY: site
site:
	$(SOUPAULT)

.PHONY: all
all: site

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/*

.PHONY: serve
serve:
	python3 -m http.server --directory $(BUILD_DIR)

