RELEASE_FILE=_build/prod/rel/example_app/releases/0.1.0/example_app.tar.gz
FILE_NAME=$(shell basename $(RELEASE_FILE))
build:
	@mix deps.get
	@MIX_ENV=prod mix compile
	@MIX_ENV=prod mix release --env=prod
	@cp $(RELEASE_FILE) $(FILE_NAME)
