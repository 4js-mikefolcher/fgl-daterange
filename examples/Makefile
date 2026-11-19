# Date range examples: IMPORT FGL modules, no link step. Everything is written to bin/,
# which must be on FGLLDPATH (and FGLRESOURCEPATH for the .4st) to run:
#   make && FGLPROFILE=$PWD/fglprofile fglrun bin/MainController.42m
# The library is the one in this repository (../com/fourjs/fgldaterange), so the top of the
# repository is on FGLLDPATH. An application that installs the package uses `fglpkg env`.
# Any compiler warning fails the build. fglform has no error switch and still writes
# the form when it only warns, so its output is checked and the form deleted.
#   make test   runs the fglunit suites (fglunit is a dev dependency: fglpkg install)
#   make uitest runs the 4js-fgltest functional suite, which drives the application through
#               GGC (4js-fgltest is a dev dependency too). It needs Java and a GGC:
#                  make uitest [GGCDIR=/path/to/testing_utilities/ggc] [UIPORT=6517]
#               GGC is in testing_utilities/ggc of recent Genero installs and is found there
#               by default. Use a GGC whose path has no space.

BIN := bin
GGCDIR ?= $(FGLDIR)/testing_utilities/ggc
UIPORT ?= 6517
UIDIR := $(BIN)/uitest
LIBSOURCE := ../com/fourjs/fgldaterange/DateRangeHelper.4gl
LIBMODULE := ../com/fourjs/fgldaterange/DateRangeHelper.42m
DATABASE := daterangedemo.db

# Libraries before the modules that import them
MODULES := InputDemoModel InputDemoController \
   ConstructDemoModel ConstructDemoController \
   DisplayDemoModel DisplayDemoController \
   ArrayDemoModel ArrayDemoController \
   MainMenuController MainController
FORMS := InputDemo ConstructDemo DisplayDemo ArrayDemo
SUITES := TestInputDemoModel TestInputDemoController TestConstructDemoModel \
   TestDisplayDemoModel TestArrayDemoModel TestArrayDemoController

export FGLLDPATH := $(CURDIR)/$(BIN):$(CURDIR)/..$(if $(FGLLDPATH),:$(FGLLDPATH))
export FGLPROFILE := $(CURDIR)/fglprofile

.PHONY: all clean test uitest

all: $(MODULES:%=$(BIN)/%.42m) $(FORMS:%=$(BIN)/%.42f) $(BIN)/DateRangeDemo.4st $(DATABASE)

# The SQLite driver opens the database file but does not create it: an empty file is enough,
# the CONSTRUCT example creates and fills its table.
$(DATABASE):
	touch $@

$(BIN):
	mkdir -p $(BIN)

$(LIBMODULE): $(LIBSOURCE)
	$(MAKE) -C .. all

$(BIN)/InputDemoModel.42m: InputDemoModel.4gl $(LIBMODULE) | $(BIN)
$(BIN)/InputDemoController.42m: InputDemoController.4gl $(BIN)/InputDemoModel.42m | $(BIN)
$(BIN)/ConstructDemoModel.42m: ConstructDemoModel.4gl | $(BIN)
$(BIN)/ConstructDemoController.42m: ConstructDemoController.4gl $(BIN)/ConstructDemoModel.42m | $(BIN)
$(BIN)/DisplayDemoModel.42m: DisplayDemoModel.4gl $(LIBMODULE) | $(BIN)
$(BIN)/DisplayDemoController.42m: DisplayDemoController.4gl $(BIN)/DisplayDemoModel.42m | $(BIN)
$(BIN)/ArrayDemoModel.42m: ArrayDemoModel.4gl $(LIBMODULE) | $(BIN)
$(BIN)/ArrayDemoController.42m: ArrayDemoController.4gl $(BIN)/ArrayDemoModel.42m | $(BIN)
$(BIN)/MainMenuController.42m: MainMenuController.4gl $(BIN)/InputDemoController.42m \
   $(BIN)/ConstructDemoController.42m $(BIN)/DisplayDemoController.42m $(BIN)/ArrayDemoController.42m | $(BIN)
$(BIN)/MainController.42m: MainController.4gl $(BIN)/MainMenuController.42m | $(BIN)

$(BIN)/%.42m:
	fglcomp -M -Wall -Werror -o $(BIN) $<

$(BIN)/%.42f: %.per | $(BIN)
	@out=$$(fglform -M -W all -o $(BIN) $< 2>&1); status=$$?; \
	if [ -n "$$out" ]; then echo "$$out"; fi; \
	if [ $$status -ne 0 ] || [ -n "$$out" ]; then rm -f $@; exit 1; fi

$(BIN)/%.4st: %.4st | $(BIN)
	cp $< $@

# fglpkg env adds the installed packages (com.fourjs.fglunit) to FGLLDPATH. The
# ConstructDemoModel suite connects to the demo database through FGLPROFILE.
test: all
	eval "$$(fglpkg env)" && \
	for suite in $(SUITES); do \
	   fglcomp -M -Wall -Werror -o $(BIN) tests/$$suite.4gl && \
	   fglrun $(BIN)/$$suite.42m --color never --junit $(BIN)/junit-$$suite.xml || exit 1; \
	done

# The suite needs what the Makefile sets here, not what the shell happens to have:
#   DBDATE=MDY4/     the CONSTRUCT criteria are typed as mm/dd/yyyy
#   an empty SQLite file as the database, in the directory the application runs in (the
#   Construct screen rewrites its orders table, so the tests never touch $(DATABASE))
#   the GGC jar, its fglcomp libraries and ggcadmin, which envggc would add (it needs bash)
# The scenario server inherits the environment of whoever starts it, so a left-over one is
# stopped first. Reports and logs: $(UIDIR)/out.
uitest: all
	@test -f "$(GGCDIR)/ggc.jar" || { \
	   echo "GGC not found: $(GGCDIR)/ggc.jar. Set GGCDIR to a testing_utilities/ggc directory."; exit 1; }
	rm -rf $(UIDIR)
	mkdir -p $(UIDIR)/run
	touch $(UIDIR)/run/$(DATABASE)
	eval "$$(fglpkg env)" && \
	fglcomp -M -Wall -Werror -o $(BIN) uitests/TestExamplesUi.4gl && \
	export CLASSPATH="$(GGCDIR)/ggc.jar$${CLASSPATH:+:$$CLASSPATH}" \
	   FGLLDPATH="$(GGCDIR)/lib:$$FGLLDPATH" \
	   PATH="$(GGCDIR)/bin:$$PATH" \
	   FGLRESOURCEPATH="$(CURDIR)/$(BIN)$${FGLRESOURCEPATH:+:$$FGLRESOURCEPATH}" \
	   DBDATE=MDY4/ \
	   FGLTEST_PORT=$(UIPORT) && \
	{ ggcadmin stopbdlserver -p $(UIPORT) >/dev/null 2>&1 || true; } && \
	fglpkg bdl 4js-fgltest fgltest "$(CURDIR)/uitests/fgltest.json"

clean:
	rm -rf $(BIN) $(DATABASE)
