BEAM_DIR=beam
SRCS=$(wildcard src/*.ex)
ELIXIRC=$(shell which elixirc)

build:
	@$(ELIXIRC) --ignore-module-conflict -o $(BEAM_DIR) $(SRCS)

clean:
	@rm $(BEAM_DIR)/*.beam
