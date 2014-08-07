REPORTER = spec
TESTFILES = $(shell find test/ -name '*.test.js')

install:
	@echo "Installing production"
	@npm install --production
	@echo "Install complete"

test:
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--reporter $(REPORTER) \
		$(TESTFILES)

lint:
	@echo "Linting..."
	@jshint \
	  --config .jshintrc \
	  index.js test/*.js

coverage:
	@echo "Generating coverage report.."
	@istanbul cover _mocha
	@echo "Done: ./coverage/lcov-report/index.html"

docs:
	@jsdoc index.js Readme.md

.PHONY: install test lint coverage docs
