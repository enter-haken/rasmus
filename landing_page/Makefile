.PHONY: default
default: build

.PHONY: build
build:
	if [ ! -d node_modules/ ]; then npm install; fi
	gulp

.PHONY: deploy
deploy:
	rm ../docs -rf
	gulp deploy

.PHONY: clean
clean:
	rm dist/ -rf

.PHONY: clean_node_modules 
clean_node_modules:
	rm node_modules/ -rf

.PHONY: deep_clean
deep_clean: clean clean_node_modules

.PHONY: all
all: clean build deploy
