.PHONY: default
default: all

.PHONY: init_database
init_database:
	make -C ./database_scripts all

.PHONY: compile
compile:
	if [ ! -d deps ]; then mix deps.get; fi
	if [ ! -d landing_page/dist ]; then make -C ./landing_page; fi
	if [ ! -d frontend/dist ]; then make -C ./frontend/; fi
	mix compile

.PHONY: run
run:
	if [ ! -d _build ]; then make; fi
	iex -S mix run 

.PHONY: clean
clean: 
	rm _build/ -rf
	rm deps/ -rf
	rm api-doc/ -rf
	make -C ./database_scripts clean
	make -C ./landing_page deep_clean
	make -C ./frontend deep_clean

.PHONY: docs
docs:
	rm api-doc/ -rf
	mix docs -o api-doc

.PHONY: core_schema
core_schema:
	if [ ! -f schema/schema.sh ]; then git submodule update --init --recursive; fi
	schema/schema.sh -u postgres -d rasmus -s core | dot -Tpng > core_schema.png

.PHONY: all
all: init_database compile docs
