# Makefile for Yale Haskell.
#
#   make            build the compiler, the prelude and bin/yale-haskell
#   make test       run the test suite
#   make clean      delete everything under build/
#   make ref        clone the reference implementations into ref/
#
# Only SBCL is supported at present.  Build logs go to build/$(LISP)/logs.

LISP     ?= sbcl
SBCL     ?= sbcl
HEAP_MB  ?= 4096

Y2       := $(CURDIR)
BUILD    := build/$(LISP)
LOGS     := $(BUILD)/logs
PRELUDE  := progs/prelude
EXE      := $(BUILD)/yale-haskell

export Y2
export HASKELL         := $(Y2)
export PRELUDE         := $(Y2)/$(PRELUDE)
export PRELUDEBIN      := $(Y2)/$(BUILD)/prelude
export HASKELL_LIBRARY := $(Y2)/progs/lib
export LIBRARYBIN      := $(Y2)/$(BUILD)/lib

COMPILER_SOURCES := $(shell find . \( -path ./build -o -path ./ref -o -path ./progs -o -path ./.git \) -prune \
                      -o \( -name '*.scm' -o -name '*.lisp' \) -print)
PRELUDE_SOURCES  := $(wildcard $(PRELUDE)/*.hs $(PRELUDE)/*.hi $(PRELUDE)/*.hu)

RUN_SBCL = $(SBCL) --dynamic-space-size $(HEAP_MB) --non-interactive --no-userinit

# Run a build step quietly, keeping the full output in a log file.
define step
	@mkdir -p $(LOGS)
	@printf '  %-10s %s\n' $(1) '$(LOGS)/$(1).log'
	@$(2) > $(LOGS)/$(1).log 2>&1 || { tail -40 $(LOGS)/$(1).log; \
	  echo "*** $(1) failed; full log in $(LOGS)/$(1).log"; exit 1; }
endef

.PHONY: all compiler prelude image test clean ref

all: image
	@echo "Built $(EXE).  Run bin/yale-haskell [file.hs]."

compiler: $(BUILD)/.compiler-stamp
prelude:  $(BUILD)/.prelude-stamp
image:    $(EXE)

$(BUILD)/.compiler-stamp: $(COMPILER_SOURCES)
	$(call step,compiler,$(RUN_SBCL) --load tools/build/compiler.lisp)
	@touch $@

$(BUILD)/.prelude-stamp: $(BUILD)/.compiler-stamp $(PRELUDE_SOURCES)
	$(call step,prelude,$(RUN_SBCL) --load tools/build/prelude.lisp)
	@touch $@

$(EXE): $(BUILD)/.prelude-stamp
	$(call step,image,$(RUN_SBCL) --load tools/build/image.lisp $(Y2)/$(EXE))

test: image
	@tests/run-smoke

clean:
	rm -rf build

ref: ref/hugs98 ref/haskell-report

ref/hugs98:
	git clone --depth 1 https://github.com/augustss/hugs98-plus-Sep2006 $@

ref/haskell-report:
	git clone --depth 1 -b h98 https://github.com/haskell/haskell-report $@
