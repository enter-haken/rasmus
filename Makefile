.PHONY: compile run clean docs first_time init_database all core_schema

all: init_database compile docs

init_database:
	make -C ./database_scripts all

compile:
	if [ ! -d deps/ ]; then mix deps.get; fi
	mix compile

run:
	iex -S mix run 

clean: 
	rm _build/ -rf
	rm deps/ -rf
	rm doc/ -rf
	make -C ./database_scripts clean

docs:
	mix docs

core_schema:
	if [ ! -f schema/schema.sh ]; then git submodule update --init --recursive; fi
	schema/schema.sh -u postgres -d rasmus -s core | dot -Tpng > core_schema.png
