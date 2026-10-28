#!/usr/bin/env python3
"""Stages GHC 8.0.2's stage-1 compiler for Yale Haskell.

stage.py GHC-DIR STAGE-DIR: STAGE-DIR/src has the compiler's modules (its
hs-source-dirs merged) and those of the boot libraries it needs that Yale
Haskell's library has not (ghc-boot, ghc-boot-th, template-haskell, hpc,
hoopl); STAGE-DIR/include the headers they include; STAGE-DIR/main the
driver's Main; STAGE-DIR/ghc.cabal a package for MicroCabal.  GHC-DIR has
been configured and has the generated headers and primop tables
(setup.sh)."""
import os
import re
import shutil
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import modern_base  # noqa: E402

ghc, stage = sys.argv[1], sys.argv[2]
src = os.path.join(stage, "src")
inc = os.path.join(stage, "include")
if os.path.exists(stage):
    shutil.rmtree(stage)
os.makedirs(src)
os.makedirs(inc)
os.makedirs(os.path.join(stage, "main"))
os.makedirs(os.path.join(stage, "cbits"))

HS = (".hs", ".hs-boot", ".lhs", ".hsc", ".x", ".y")


def module_name(path):
    head = open(path, errors="replace").read(20000)
    m = re.search(r"^module\s+([A-Za-z0-9_.']+)", head, re.M)
    return m.group(1) if m else None


def copy_tree(root, skip=()):
    """ROOT's modules into src, by their module names."""
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if x not in ("dist", "dist-boot", "dist-install", "tests", "stage1", "stage2")]
        for f in files:
            if not f.endswith(HS) or f == "Setup.hs" or f in skip:
                continue
            path = os.path.join(d, f)
            rel = os.path.relpath(path, root)
            dst = os.path.join(src, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy(path, dst)


# The compiler: its hs-source-dirs merged (module names are flat or
# hierarchical below each).
cabal_in = open(os.path.join(ghc, "compiler", "ghc.cabal.in")).read()
dirs = re.search(r"hs-source-dirs:\s*\n((?:\s+\S+\n)+)", cabal_in).group(1).split()
for d in dirs:
    copy_tree(os.path.join(ghc, "compiler", d))
# (the lexer and parser from their sources: Yale's alex and happy)
for f in ("Lexer.hs", "Parser.hs"):
    os.remove(os.path.join(src, f))
shutil.copy(os.path.join(ghc, "compiler", "parser", "Lexer.x.source"), os.path.join(src, "Lexer.x"))
shutil.copy(os.path.join(ghc, "compiler", "parser", "Parser.y.source"), os.path.join(src, "Parser.y"))

# The modules: the library's, not those of GHCi (stage 1 has none).
mods = []
sections = re.split(r"\n    (?=\S)", cabal_in)
for s in sections:
    if s.startswith("Exposed-Modules:"):
        mods += s.split()[1:]
mods = [m for m in mods if not m.startswith("--")]

# The boot libraries.
for lib in ("ghc-boot", "ghc-boot-th", "template-haskell", "hpc"):
    copy_tree(os.path.join(ghc, "libraries", lib))
copy_tree(os.path.join(ghc, "libraries", "hoopl", "src"))
for lib in ("ghc-boot", "ghc-boot-th", "template-haskell", "hpc", "hoopl"):
    text = open(os.path.join(ghc, "libraries", lib, lib + ".cabal")).read()
    for s in re.split(r"\n\s*(?=[A-Za-z-]+:)", text):
        if re.match(r"(?i)(exposed|other)-modules:", s):
            mods += [m for m in re.split(r"[\s,]+", s.split(":", 1)[1]) if m and not m.startswith("--")]

shutil.copy(os.path.join(ghc, "ghc", "Main.hs"), os.path.join(stage, "main", "Main.hs"))

# Config.hs, as compiler/ghc.mk writes it, for an unregisterised stage 1
# without GHCi on integer-simple.
config = open(os.path.join(ghc, "compiler", "stage1", "build", "Config.hs")).read()
for k, v in {"cIntegerLibrary": '"integer-simple"', "cIntegerLibraryType": "IntegerSimple",
             "cGhcWithInterpreter": '"NO"', "cGhcRTSWays": '""',
             "cGhcEnableTablesNextToCode": '"NO"', "cLeadingUnderscore": '"YES"',
             "cLibFFI": "False", "cGhcThreaded": "False"}.items():
    config, n = re.subn(r"^(%s\s*=\s*).*$" % k, lambda m: m.group(1) + v, config, flags=re.M)
    assert n == 1, k
open(os.path.join(src, "Config.hs"), "w").write(config)

# Headers: the compiler's, the stage's, the RTS's includes and the
# generated ones; #include "../includes/X" is #include "X".
for d in ("compiler", "compiler/parser", "compiler/utils", "compiler/stage1",
          "compiler/stage1/build", "includes/dist-derivedconstants/header"):
    for f in os.listdir(os.path.join(ghc, d)):
        if f.endswith((".h", ".hs-incl")) or (d.endswith("header") and f.endswith(".hs")):
            shutil.copy(os.path.join(ghc, d, f), os.path.join(inc, f))
for f in os.listdir(os.path.join(ghc, "includes")):
    p = os.path.join(ghc, "includes", f)
    if os.path.isdir(p):
        if f in ("rts", "stg"):
            shutil.copytree(p, os.path.join(inc, f))
    elif f.endswith((".h", ".hs")):
        shutil.copy(p, os.path.join(inc, f))
for root, _, files in list(os.walk(src)) + list(os.walk(inc)):
    for f in files:
        path = os.path.join(root, f)
        text = open(path, errors="replace").read()
        new = re.sub(r'#include\s+"(?:\.\./)+includes/(?:dist-derivedconstants/header/)?([^"]+)"',
                     r'#include "\1"', text)
        if new != text:
            open(path, "w").write(new)

shutil.copy(os.path.join(ghc, "compiler", "cbits", "genSym.c"), os.path.join(stage, "cbits", "genSym.c"))
# parser/cutils.c, but the driver's RTS flags (+RTS -t, -H) are no-ops:
# Yale Haskell has not GHC's RTS.
open(os.path.join(stage, "cbits", "cutils.c"), "w").write("""\
#include <string.h>
#include "HsFFI.h"

HsInt ghc_strlen(HsPtr a) { return strlen((char *)a); }
HsInt ghc_memcmp(HsPtr a1, HsPtr a2, HsInt len) { return memcmp((char *)a1, a2, len); }
void enableTimingStats(void) { }
void setHeapSize(HsInt size) { (void)size; }
""")

# Today's base: fail is MonadFail's, Monoid wants Semigroup.
for root, _, files in os.walk(src):
    for f in files:
        if f.endswith(HS):
            path = os.path.join(root, f)
            text = open(path, errors="replace").read()
            new = modern_base.add_semigroup(modern_base.split_fail(text))
            if new != text:
                open(path, "w").write(new)

# containers 0.6 removed fold and foldWithKey (foldr, foldrWithKey).
for root, _, files in os.walk(src):
    for f in files:
        if not f.endswith(HS):
            continue
        path = os.path.join(root, f)
        text = open(path, errors="replace").read()
        aliases = re.findall(r"^import\s+qualified\s+Data\.(?:Map|IntMap|Set|IntSet)(?:\.Strict|\.Lazy)?\b[^\n]*?\bas\s+([A-Z][\w.]*)",
                             text, re.M)
        new = text
        for a in set(aliases):
            new = re.sub(r"\b%s\.fold(WithKey)?\b" % re.escape(a),
                         lambda m: a + ".foldr" + (m.group(1) or ""), new)
        if new != text:
            open(path, "w").write(new)

mods = sorted(set(mods))
missing = [m for m in mods if not any(os.path.exists(os.path.join(src, m.replace(".", "/") + e))
                                      for e in (".hs", ".lhs", ".hsc", ".x", ".y"))]
for m in missing:
    print("no source:", m)
mods = [m for m in mods if m not in missing]

cabal = """cabal-version: 2.0
name: ghc
version: 8.0.2
build-type: Simple

library
  hs-source-dirs: src
  default-language: Haskell2010
  build-depends: base, array, binary, bytestring, containers, deepseq,
    directory, filepath, process, time, transformers, unix, pretty
  include-dirs: include
  cpp-options: -DSTAGE=1 -D__GLASGOW_HASKELL__=800
  cc-options: -DUSE_MINIINTERPRETER -DNOSMP
  c-sources: cbits/cutils.c cbits/genSym.c
  exposed-modules:
%s

executable ghc
  hs-source-dirs: main
  main-is: Main.hs
  default-language: Haskell2010
  cpp-options: -DSTAGE=1 -D__GLASGOW_HASKELL__=800
  build-depends: base, ghc, directory, filepath, process
""" % "\n".join("    " + m for m in mods)
open(os.path.join(stage, "ghc.cabal"), "w").write(cabal)
print("%d modules" % len(mods))
