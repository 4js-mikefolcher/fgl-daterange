# fgldaterange: the BDL library (com/fourjs/fgldaterange), its tests and the examples.
#
#   make            compile the library, each .42m beside its .4gl as the package ships it
#   make test       compile and run the fglunit suites (run `fglpkg install` once: fglunit
#                   is a dev dependency)
#   make examples   build the example application (see examples/Makefile)
#   make uitest     functional tests of the examples through GGC (4js-fgltest; needs Java and
#                   a GGC, see examples/Makefile for GGCDIR)
#   make check      fglpkg lint and fglpkg pack --list: what the package would contain
#   make clean
#
# Everything compiles with -Wall -Werror, so any warning fails the build. The library is
# imported as `IMPORT FGL com.fourjs.fgldaterange.DateRangeHelper`, so the top of this
# project is on FGLLDPATH. Use a Genero 6 fglcomp: `fglpkg pack` labels the package with the
# Genero major it finds on PATH.

LIBDIR := com/fourjs/fgldaterange
MODULES := DateRangeHelper
BUILD := build
SUITES := TestDateRangeHelper

export FGLLDPATH := $(CURDIR):$(CURDIR)/$(BUILD)$(if $(FGLLDPATH),:$(FGLLDPATH))

.PHONY: all test uitest examples check clean

all: $(MODULES:%=$(LIBDIR)/%.42m)

$(LIBDIR)/%.42m: $(LIBDIR)/%.4gl
	fglcomp -M -Wall -Werror $<

$(BUILD):
	mkdir -p $(BUILD)

# fglpkg env adds the installed packages (com.fourjs.fglunit) to FGLLDPATH
test: all | $(BUILD)
	eval "$$(fglpkg env)" && \
	for suite in $(SUITES); do \
	   fglcomp -M -Wall -Werror -o $(BUILD) tests/$$suite.4gl && \
	   fglrun $(BUILD)/$$suite.42m --color never --junit $(BUILD)/junit-$$suite.xml || exit 1; \
	done

examples: all
	$(MAKE) -C examples

uitest: all
	$(MAKE) -C examples uitest

check: all
	fglpkg lint
	fglpkg pack --list

clean:
	rm -rf $(BUILD) $(MODULES:%=$(LIBDIR)/%.42m)
	$(MAKE) -C examples clean
