.PHONY: all
all: init_database compile docs

.PHONY: init_database
init_database:
	make -C ./database_scripts all

.PHONY: compile
compile:
	if [ ! -d deps/ ]; then mix deps.get; fi
	mix compile

.PHONY: run
run:
	iex -S mix run 

.PHONY: clean
clean: 
	rm _build/ -rf
	rm deps/ -rf
	rm doc/ -rf
	make -C ./database_scripts clean

.PHONY: docs
docs:
	mix docs

.PHONY: core_schema
core_schema:
	if [ ! -f schema/schema.sh ]; then git submodule update --init --recursive; fi
	schema/schema.sh -u postgres -d rasmus -s core | dot -Tpng > core_schema.png
