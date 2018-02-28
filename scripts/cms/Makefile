.PHONY: help clean generate seed createdb dropdb
help:
	@echo "clean - drops schema cms"
	@echo "generate - create schema, insert tables..."
	@echo "seed - insert inital values for tables"
	@echo "createdb - creates database rasmus"
	@echo "dropdb - drops database rasmus"
	@echo "all - target for: clean, generate, seed"

clean:
	psql -U postgres -d rasmus -f clean.sql

generate:
	psql -U postgres -d rasmus -f init.sql
	psql -U postgres -d rasmus -f tables.sql
	psql -U postgres -d rasmus -f postcreate.sql

seed:
	psql -U postgres -d rasmus -f seed.sql

createdb:
	createdb -U postgres rasmus

dropdb:
	dropdb -U postgres rasmus

all: clean generate seed
