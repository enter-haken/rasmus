.PHONY: all clean first_time
all:
	make -C ./scripts all
	make -C ./backend
clean:
	make -C ./scripts clean
	make -C ./backend clean

# on first time use, the rasmus db must be created
first_time:
	make -C ./scripts/core createdb

run:
	make -C ./backend run
