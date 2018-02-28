.PHONY: compile clean run
compile:
	rebar3 compile
clean:
	rebar3 clean
	if [ -d _build/ ]; then rm _build/ -rf; fi;
run:
	rebar3 shell
