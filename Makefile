# Makefile for Yale Haskell.
#
#   make            build the compiler and an executable for each dialect
#   make test       run the test suite (tests/README.md)
#   make clean      delete everything under build/
#   make ref        clone the reference implementations into ref/
#
# Dialects are the Prelude/library trees under lib/: haskell-1.2 (the
# original system) and haskell98 (in progress).  Each gets its own
# compiled prelude and executable, build/$(LISP)/<dialect>/yale-haskell;
# bin/yale-haskell picks one.  Build logs go to build/$(LISP)/logs.
#
# Only SBCL is supported at present.

LISP     ?= sbcl
SBCL     ?= sbcl
HEAP_MB  ?= 4096
DIALECTS ?= haskell-1.2 haskell98

Y2       := $(CURDIR)
BUILD    := build/$(LISP)
LOGS     := $(BUILD)/logs

export Y2
export HASKELL := $(Y2)

COMPILER_SOURCES := $(shell find src tools/build -name '*.mumble' -o -name '*.lisp')

RUN_SBCL = $(SBCL) --dynamic-space-size $(HEAP_MB) --non-interactive --no-userinit

# Environment the compiler expects for dialect $(1).
dialect_env = PRELUDE=$(Y2)/lib/$(1)/prelude \
  PRELUDEBIN=$(Y2)/$(BUILD)/$(1)/prelude \
  HASKELL_LIBRARY=$(Y2)/lib/$(1) \
  LIBRARYBIN=$(Y2)/$(BUILD)/$(1)/lib

# Run a build step quietly, keeping the full output in a log file.
# $(1) = log name, $(2) = command.
define step
	@mkdir -p $(LOGS)
	@printf '  %-22s %s\n' $(1) '$(LOGS)/$(1).log'
	@$(2) > $(LOGS)/$(1).log 2>&1 || { tail -40 $(LOGS)/$(1).log; \
	  echo "*** $(1) failed; full log in $(LOGS)/$(1).log"; exit 1; }
endef

.PHONY: all compiler test clean ref $(DIALECTS)
.SECONDEXPANSION:
.SECONDARY:

all: $(DIALECTS)
	@echo "Built $(foreach d,$(DIALECTS),$(BUILD)/$(d)/yale-haskell).  Run bin/yale-haskell [--haskell98] [file.hs]."

compiler: $(BUILD)/.compiler-stamp

$(DIALECTS): %: $(BUILD)/%/yale-haskell

$(BUILD)/.compiler-stamp: $(COMPILER_SOURCES)
	$(call step,compiler,$(RUN_SBCL) --load tools/build/compiler.lisp)
	@touch $@

# The compiler reports Haskell errors without failing, so the prelude
# step also checks its log for them.
HASKELL_ERRORS := \] (Phase error|Recoverable error|Fatal error|Internal-error) in

# The prelude unit is :stable (its sources are never rechecked), so its
# old binaries must be removed for it to be recompiled.
$(BUILD)/%/.prelude-stamp: $(BUILD)/.compiler-stamp $$(wildcard lib/%/prelude/*)
	@rm -rf $(BUILD)/$*/prelude
	$(call step,$*-prelude,env $(call dialect_env,$*) $(RUN_SBCL) --load tools/build/prelude.lisp)
	@if grep -aEq '$(HASKELL_ERRORS)' $(LOGS)/$*-prelude.log; then \
	  grep -aE -A3 '$(HASKELL_ERRORS)' $(LOGS)/$*-prelude.log | head -40; \
	  echo "*** $*-prelude had compile errors; full log in $(LOGS)/$*-prelude.log"; exit 1; fi
	@touch $@

$(BUILD)/%/yale-haskell: $(BUILD)/%/.prelude-stamp
	$(call step,$*-image,env $(call dialect_env,$*) $(RUN_SBCL) --load tools/build/image.lisp $(Y2)/$@)

test: all
	@tests/run-tests

clean:
	rm -rf build

ref: ref/hugs98 ref/haskell-report ref/haskell-1.x ref/ghc-3.02

ref/hugs98:
	git clone --depth 1 https://github.com/augustss/hugs98-plus-Sep2006 $@

ref/haskell-report:
	git clone --depth 1 -b h98 https://github.com/haskell/haskell-report $@

# Haskell 1.2/1.3/1.4 Reports.  PostScript is converted to PDF and text
# when Ghostscript and pdftotext are installed.
OLD_REPORTS := haskell-report-1.2.ps.gz haskell-report-1.3.ps.gz \
	haskell-report-1.4.ps.gz haskell-report-1.4-html.tar.gz \
	haskell-library-1.4.ps.gz haskell-library-1.4-html.tar.gz \
	from12to13.html from13to14.html

ref/haskell-1.x:
	mkdir -p $@.tmp
	cd $@.tmp && for f in $(OLD_REPORTS); do \
	  curl -sfLO https://www.haskell.org/definition/$$f || exit 1; done
	cd $@.tmp && for t in *.tar.gz; do tar xzf $$t; done
	-cd $@.tmp && for p in *.ps.gz; do b=$${p%.ps.gz}; \
	  gunzip -c $$p > $$b.ps && ps2pdf $$b.ps $$b.pdf && \
	  pdftotext -layout $$b.pdf $$b.txt; rm -f $$b.ps; done
	mv $@.tmp $@

# GHC 3.02 (1998), a Haskell 1.4 implementation.  The tarball unpacks
# as fptools/.
ref/ghc-3.02:
	mkdir -p $@.tmp
	curl -sfL https://downloads.haskell.org/~ghc/3.02/ghc-3.02-src.tar.gz \
	  | tar xz -C $@.tmp
	mv $@.tmp/fptools $@ && rmdir $@.tmp
