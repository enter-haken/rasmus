TARGET = '../priv/static'
PACKAGE_MANAGER = 'yarn'
	
.PHONY: default
default: build

.PHONY: build
build:
	if [ ! -d node_modules ]; then $(PACKAGE_MANAGER) install; fi
	$(PACKAGE_MANAGER) run build

.PHONY: deploy
deploy:
	rm ../priv/static/* -rf
	if [ ! -d build ]; then make; fi
	cp ./build/index.html $(TARGET)	
	cp ./build/asset-manifest.json $(TARGET)
	cp ./build/favicon.ico $(TARGET)
	cp ./build/manifest.json $(TARGET)
	mkdir -p $(TARGET)/static/js
	cp ./build/static/js/* $(TARGET)/static/js

.PHONY: clean
clean:
	rm build/ -rf

.PHONY: clean_node_modules 
clean_node_modules:
	rm node_modules/ -rf

.PHONY: deep_clean
deep_clean: clean clean_node_modules

.PHONY: run
run: 
	$(PACKAGE_MANAGER) run start

.PHONY: all
all: clean build deploy

.PHONY: run
run: 
	$(PACKAGE_MANAGER) run start
