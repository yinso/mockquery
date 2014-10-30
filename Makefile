VPATH=src
BUILDDIR=lib
TESTDIR=test


BEANDIR=.
JSONDIR=.

COFFEE_SOURCES= $(wildcard $(VPATH)/*.coffee)
COFFEE_OBJECTS=$(patsubst $(VPATH)/%.coffee, $(BUILDDIR)/%.js, $(COFFEE_SOURCES))

BEAN_FILES=$(wildcard $(BEANDIR)/*.yml)
JSON_FILES=$(patsubst $(BEANDIR)/%.yml, $(JSONDIR)/%.json, $(BEAN_FILES))

GRAMMAR_DIR=grammar

GRAMMAR_FILES=$(wildcard $(GRAMMAR_DIR)/*.pegjs)
GRAMMAR_JS_FILES=$(patsubst $(GRAMMAR_DIR)/%.pegjs, $(GRAMMAR_DIR)/%.js, $(GRAMMAR_FILES))

all: build

.PHONY: build
build: node_modules objects 

.PHONY: objects
objects: $(COFFEE_OBJECTS) $(JSON_FILES) $(GRAMMAR_JS_FILES) 
	
$(JSONDIR)/%.json: $(BEANDIR)/%.yml
	./node_modules/.bin/bean --source $<

$(GRAMMAR_DIR)/%.js: $(GRAMMAR_DIR)/%.pegjs
	./node_modules/.bin/pegjs $< $@

#src/parser.js: src/parser.pegjs
#	./node_modules/.bin/pegjs src/parser.pegjs src/parser.js

#lib/parser.js: src/parser.js
#	cp src/parser.js lib/parser.js

#	#./node_modules/.bin/mocha --ignore-leaks --compilers coffee:coffee-script --reporter spec  -g exec # proxy runtime parse exec compile # for running test cases that matches the name
.PHONY: test
test: build
	./node_modules/.bin/testlet


.PHONY: clean
clean:
	rm -f $(COFFEE_OBJECTS)

.PHONE: pristine
pristine: clean
	rm -rf node_modules

node_modules:
	npm install -d

$(BUILDDIR)/%.js: $(VPATH)/%.coffee
	coffee -o $(BUILDDIR) -c $<

$(TESTDIR)/%.js: $(TESTDIR)/%.coffee
	coffee -o $(TESTDIR) -c $<

.PHONY: watch
watch:
	coffee --watch -o $(BUILDDIR) -c $(VPATH)

.PHONY: start
start:	all
	./node_modules/.bin/supervisor -w routes,views,lib,src,client -e coffee,hbs,js,json -q run.js
