BUILD_DIR := build
SITE_DIR := site
INDEX_FILE := index.json

# Assume that soupault is somewhere in $PATH
SOUPAULT := soupault

.PHONY: site
site:
	$(SOUPAULT)

.PHONY: all
all: site external

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/*

.PHONY: serve
serve:
	python3 -m http.server --directory $(BUILD_DIR)

.PHONY: deploy
deploy:
	rsync -a -e "ssh" $(BUILD_DIR)/ lucytasker.com:/var/www/lucytasker.com/
