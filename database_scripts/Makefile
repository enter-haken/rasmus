.PHONY: default
default: help

.PHONY: help 
help:
	@echo "clean - drops schema core"
	@echo "generate - create schema, insert tables..."
	@echo "seed - fire some test queries towwards the database - DO NOT USE IN PRODUCTION!"
	@echo "createdb - creates database rasmus, if not exists"
	@echo "all - target for: createdb, clean, generate, seed"

.PHONY: clean
clean:
	psql -U postgres -d rasmus -f clean.sql

.PHONY: generate
generate:
	psql -U postgres -d rasmus -f init.sql
	psql -U postgres -d rasmus -f notifications.sql
	psql -U postgres -d rasmus -f crud.sql
	psql -U postgres -d rasmus -f transfer.sql
	psql -U postgres -d rasmus -f privilege.sql
	psql -U postgres -d rasmus -f role.sql
	psql -U postgres -d rasmus -f user_account.sql
	psql -U postgres -d rasmus -f link.sql
	psql -U postgres -d rasmus -f person.sql 
	psql -U postgres -d rasmus -f appointment.sql 
	psql -U postgres -d rasmus -f list.sql 
	psql -U postgres -d rasmus -f graph_edge.sql
	psql -U postgres -d rasmus -f postcreate.sql

.PHONY: seed
seed:
	# DO NOT USE IN PRODUCTION!
	psql -U postgres -d rasmus -f seed.sql

.PHONY: init
init:
	./api_queries.sh

.PHONY: createdb
createdb:
	if [ `psql -U postgres -c "SELECT * from pg_database WHERE datname='rasmus'" | grep row | cut -c2` -eq "0" ]; then \
		createdb -U postgres rasmus; \
	fi;	

.PHONY: all
all: createdb clean generate
