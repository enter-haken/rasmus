.PHONY: compile run clean

compile:
	if [ ! -d deps/ ]; then mix deps.get; fi
	mix compile

run:
	mix run --no-halt

clean: 
	rm _build/ -rf
	rm deps/ -rf
