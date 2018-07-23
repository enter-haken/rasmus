.PHONY: default
default: all

.PHONY: init_database
init_database:
	make -C ./database_scripts all

.PHONY: compile
compile:
	if [ ! -d deps ]; then mix deps.get; fi
	if [ ! -d priv/static ]; then make all -C ./frontend/; fi
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
	rm priv/static -rf
	make -C ./database_scripts clean
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
