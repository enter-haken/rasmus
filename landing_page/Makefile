PACKAGE_MANAGER = 'yarn'

.PHONY: default
default: build

.PHONY: build
build:
	if [ ! -d node_modules/ ]; then $(PACKAGE_MANAGER) install; fi
	gulp

.PHONY: deploy
deploy:
	rm ../docs -rf
	if [ ! -d dist ]; then make; fi
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
