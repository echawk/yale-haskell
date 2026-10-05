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

$(BUILD)/%/.prelude-stamp: $(BUILD)/.compiler-stamp $$(wildcard lib/%/prelude/*)
	$(call step,$*-prelude,env $(call dialect_env,$*) $(RUN_SBCL) --load tools/build/prelude.lisp)
	@touch $@

$(BUILD)/%/yale-haskell: $(BUILD)/%/.prelude-stamp
	$(call step,$*-image,env $(call dialect_env,$*) $(RUN_SBCL) --load tools/build/image.lisp $(Y2)/$@)

test: all
	@tests/run-tests

clean:
	rm -rf build

ref: ref/hugs98 ref/haskell-report

ref/hugs98:
	git clone --depth 1 https://github.com/augustss/hugs98-plus-Sep2006 $@

ref/haskell-report:
	git clone --depth 1 -b h98 https://github.com/haskell/haskell-report $@
