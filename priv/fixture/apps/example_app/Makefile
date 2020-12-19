RELEASE_FILE=_build/prod/example_app-0.1.0.tar.gz
TARGET_DIR=../tarball
FILE_NAME=$(shell basename $(RELEASE_FILE))
build:
	@mix deps.get
	@MIX_ENV=prod mix compile
	@MIX_ENV=prod mix release --overwrite
	@cp $(RELEASE_FILE) $(TARGET_DIR)/$(FILE_NAME)
