.PHONY: compile run clean

compile:
	if [ ! -d deps/ ]; then mix deps.get; fi
	mix compile

run:
	iex -S mix run 

clean: 
	rm _build/ -rf
	rm deps/ -rf
