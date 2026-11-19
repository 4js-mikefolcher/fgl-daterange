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
#   make gas    builds the widget into a GBC and starts a standalone httpdispatch that serves
#               the examples, to try the widget in a browser. It needs a GBC project (the
#               source tree with customization/sample, where the `gbc` tool and Node work):
#                  make gas GBCPROJECT=/path/to/gbc-project [GASDIR=/path/to/gas] [GASPORT=6395]
#               then open http://localhost:6395/ua/r/DateRangeDemo. GASDIR is the Genero
#               Application Server directory (FGLASDIR if that is set). The dispatcher has its
#               own appdata and ports, so a GAS of your own is not touched. For development
#               only: it listens on every interface and has no authentication.
#   make gas-stop [GASPORT=6395]   stops it

BIN := bin
GGCDIR ?= $(FGLDIR)/testing_utilities/ggc
UIPORT ?= 6517
UIDIR := $(BIN)/uitest
GASDIR ?= $(FGLASDIR)
GASPORT ?= 6395
GBCPROJECT ?=
GBCNAME ?= fgldaterange
GBC ?= gbc
GASRUN := $(CURDIR)/$(BIN)/gas/$(GASPORT)
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

.PHONY: all clean test uitest gbc gas gas-start gas-stop

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

# The widget in a GBC: the steps of GBC-SETUP.md, into customization/$(GBCNAME) of the GBC
# project, then a Vite build. The folder is made again on every run, so it is only replaced
# when this Makefile made it (the .fgldaterange marker): another customization is never touched.
gbc:
	@test -n "$(GBCPROJECT)" || { \
	   echo "Set GBCPROJECT to a GBC project directory, for example: make $@ GBCPROJECT=~/gbc-6.00.09"; exit 1; }
	@test -d "$(GBCPROJECT)/customization/sample" || { \
	   echo "$(GBCPROJECT)/customization/sample not found: GBCPROJECT is not a GBC project directory."; exit 1; }
	@command -v $(GBC) >/dev/null || { \
	   echo "$(GBC) not found on PATH. Set GBC=/path/to/gbc (the GBC command line tool, it needs Node)."; exit 1; }
	@dest="$(GBCPROJECT)/customization/$(GBCNAME)"; \
	if [ -e "$$dest" ] && [ ! -f "$$dest/.fgldaterange" ]; then \
	   echo "$$dest exists and was not made by this Makefile: set GBCNAME to another name."; exit 1; fi; \
	rm -rf "$$dest" && cp -R "$(GBCPROJECT)/customization/sample" "$$dest" && \
	mkdir -p "$$dest/js" "$$dest/vendor" && \
	cp -R ../gbc/js/daterange "$$dest/js/" && cp -R ../gbc/vendor/daterange "$$dest/vendor/" && \
	printf '\n@import "../js/daterange/DateRangeWidget";\n' >> "$$dest/sass/customization.scss" && \
	touch "$$dest/.fgldaterange" && \
	mkdir -p "$(CURDIR)/$(BIN)" && cd "$(GBCPROJECT)" && \
	{ $(GBC) build --vite -c "customization/$(GBCNAME)" > "$(CURDIR)/$(BIN)/gbc-build.log" 2>&1 || { \
	   tail -40 "$(CURDIR)/$(BIN)/gbc-build.log"; echo "The GBC build failed: $(CURDIR)/$(BIN)/gbc-build.log"; exit 1; }; } && \
	echo "GBC built: $(GBCPROJECT)/dist/customization/$(GBCNAME)"

# The dispatcher is configured at launch with -E, as the fourjs-gas-runtime skill describes:
#   res.appdata.path    its own appdata, bin/gas/<port>/appdata, with DateRangeDemo.xcf in app/
#   res.ic.*.port       the port and the next one (admin), so a GAS of your own is not in the way
#   res.fgldir          the Genero that compiled the examples runs them
#   res.path.gbc.user   a directory OF named GBCs: bin/gas/<port>/gbc/$(GBCNAME) -> the build
#                       (a wrong layout falls back silently to the default GBC)
#   res.gbc             the GBC to serve: ours
#   res.daterange.*     the two paths DateRangeDemo.xcf uses
# FGLLDPATH and FGLPROFILE of this Makefile are taken out of the dispatcher's environment, so
# that the .xcf alone defines what the application runs with.
gas: all
	@test -x "$(GASDIR)/bin/httpdispatch" || { \
	   echo "httpdispatch not found: set GASDIR to the Genero Application Server directory (FGLASDIR)."; exit 1; }
	@test -n "$(FGLDIR)" || { \
	   echo "FGLDIR is not set: the dispatcher must run the examples with the Genero that compiled them."; exit 1; }
	@if [ -f "$(GASRUN)/httpdispatch.pid" ] && kill -0 "$$(cat "$(GASRUN)/httpdispatch.pid")" 2>/dev/null; then \
	   echo "Already running: http://localhost:$(GASPORT)/ua/r/DateRangeDemo (make gas-stop GASPORT=$(GASPORT) to stop it)"; \
	else \
	   $(MAKE) --no-print-directory gbc gas-start; \
	fi

gas-start:
	rm -rf $(GASRUN)
	mkdir -p $(GASRUN)/gbc
	for d in app services session tmp log public gbc_deployment; do mkdir -p $(GASRUN)/appdata/$$d; done
	cp DateRangeDemo.xcf $(GASRUN)/appdata/app/
	ln -s "$(abspath $(GBCPROJECT))/dist/customization/$(GBCNAME)" $(GASRUN)/gbc/$(GBCNAME)
	@env -u FGLLDPATH -u FGLPROFILE nohup "$(GASDIR)/bin/httpdispatch" -p "$(GASDIR)" \
	   --pid-file "$(GASRUN)/httpdispatch.pid" \
	   -E res.appdata.path="$(GASRUN)/appdata" \
	   -E res.ic.server.port=$(GASPORT) -E res.ic.admin.port=$$(($(GASPORT) + 1)) \
	   -E res.fgldir="$(FGLDIR)" \
	   -E res.path.gbc.user="$(GASRUN)/gbc" -E res.gbc=$(GBCNAME) \
	   -E res.daterange.examples="$(CURDIR)" -E res.daterange.library="$(abspath ..)" \
	   -E res.log.output.type=DAILYFILE -E res.log.output.path="$(GASRUN)/appdata/log" \
	   > "$(GASRUN)/httpdispatch.out" 2>&1 & \
	for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do \
	   if grep -q '\[done\]' "$(GASRUN)/httpdispatch.out"; then \
	      echo "Serving the examples: http://localhost:$(GASPORT)/ua/r/DateRangeDemo"; \
	      echo "Stop it with: make gas-stop GASPORT=$(GASPORT). Logs: $(GASRUN)/appdata/log"; exit 0; fi; \
	   if grep -q '\[fail\]' "$(GASRUN)/httpdispatch.out"; then cat "$(GASRUN)/httpdispatch.out"; exit 1; fi; \
	   sleep 0.5; \
	done; \
	echo "The dispatcher did not report startup: $(GASRUN)/httpdispatch.out"; exit 1

# Waits until the process is gone, so that a restart on the same port does not fail to bind.
gas-stop:
	@if [ -f "$(GASRUN)/httpdispatch.pid" ]; then \
	   pid=$$(cat "$(GASRUN)/httpdispatch.pid"); kill $$pid 2>/dev/null; \
	   for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do kill -0 $$pid 2>/dev/null || break; sleep 0.5; done; \
	   rm -f "$(GASRUN)/httpdispatch.pid"; echo "Stopped the dispatcher on port $(GASPORT)."; \
	else \
	   echo "No dispatcher recorded for port $(GASPORT)."; \
	fi

# A dispatcher started by `make gas` is stopped first (and waited for): its appdata is in $(BIN).
clean:
	@for f in $(BIN)/gas/*/httpdispatch.pid; do \
	   [ -f "$$f" ] || continue; \
	   pid=$$(cat "$$f"); kill $$pid 2>/dev/null; \
	   for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do kill -0 $$pid 2>/dev/null || break; sleep 0.5; done; \
	done; true
	rm -rf $(BIN) $(DATABASE)
