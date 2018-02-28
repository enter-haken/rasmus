.PHONY: all clean first_time
all:
	make -C ./scripts all
	make -C ./db
clean:
	make -C ./scripts clean
	make -C ./db clean

# on first time use, the rasmus db must be created
first_time:
	make -C ./db createdb

run:
	make -C ./db run
