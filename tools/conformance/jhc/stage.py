#!/usr/bin/env python3
"""Stages JHC 0.8.2 (http://repetae.net/computer/jhc/) for Yale Haskell.

stage.py JHC-DIR STAGE-DIR: STAGE-DIR/src is JHC-DIR's src with its
drift_processed over it (the Makefile's -i order), with the config headers
configure would write, and fixups for today's base (JHC 0.8.2 was written
for GHC 7.x); STAGE-DIR/main/Main.hs is its main module and STAGE-DIR/
jhc.cabal a package for MicroCabal (setup.sh)."""
import os
import re
import shutil
import sys

jhc, stage = sys.argv[1], sys.argv[2]
src = os.path.join(stage, "src")
if os.path.exists(stage):
    shutil.rmtree(stage)
shutil.copytree(os.path.join(jhc, "src"), src)
shutil.copytree(os.path.join(jhc, "drift_processed"), src, dirs_exist_ok=True)
os.makedirs(os.path.join(stage, "main"))
shutil.move(os.path.join(src, "Main.hs"), os.path.join(stage, "main", "Main.hs"))


def fill(template, out, subst):
    text = open(template).read()
    for k, v in subst.items():
        text = text.replace("@%s@" % k, v)
    open(out, "w").write(text)


# configure's results for Yale Haskell's libraries
fill(os.path.join(src, "hs_src_config.h.in"), os.path.join(src, "hs_src_config.h"),
     {"HAS_MONOID_DOC": "1", "HAS_SHOW_IDENTITY": "1", "HAS_TRAVERSABLE_INTMAP": "1",
      "HAS_FUNCTOR_TUPLE": "1", "HAS_FUNCTOR_TUPLE3": "0", "HAS_FOLDABLE_TUPLE": "1",
      "HAS_FOLDABLE_TUPLE3": "0", "USE_READLINE": "0", "USE_EDITLINE": "0"})
fill(os.path.join(src, "cbits", "config.h.in"), os.path.join(src, "cbits", "config.h"),
     {"BYTE_ORDER": "1234"})
fill(os.path.join(src, "data", "targets.ini.in"), os.path.join(src, "data", "targets.ini"),
     {"MINGW": ""})
version = os.path.join(jhc, "src", "Version", "Config.hs")
if os.path.exists(version):
    shutil.copy(version, os.path.join(src, "Version", "Config.hs"))


def module_name(path):
    head = open(path, errors="replace").read(6000)
    m = re.search(r"^module +([A-Za-z0-9_.]+)", head, re.M)
    return m.group(1) if m else None


modules = []
for root, _, files in os.walk(src):
    for f in files:
        if not (f.endswith(".hs") or f.endswith(".hsc")):
            continue
        path = os.path.join(root, f)
        rel = os.path.relpath(path, src)
        expected = re.sub(r"\.(hs|hsc)$", "", rel).replace(os.sep, ".")
        if module_name(path) == expected:
            modules.append((expected, path))
modules.sort()

# Fixups: today's Prelude has <> and <$>, which GHC 7.x's had not, so
# JHC's own (Doc.DocLike's) clash with them.
for name, path in modules:
    text = open(path, errors="replace").read()
    if not re.search(r"<>|<\$>", text):
        continue
    if re.search(r"^import +(qualified +)?Prelude\b", text, re.M):
        m = re.search(r"^import +Prelude +hiding *\(", text, re.M)
        if m:
            text = text[:m.end()] + "(<>), (<$>), " + text[m.end():]
            open(path, "w").write(text)
        continue
    # (after the module header: a first import may be inside an #if)
    m = re.search(r"^module\b.*?\bwhere\b[^\n]*\n", text, re.M | re.S)
    if m:
        text = text[:m.end()] + "import Prelude hiding ((<>), (<$>))\n" + text[m.end():]
        open(path, "w").write(text)

# Monoid instances want Semigroup ones now (base 4.11): one beside each
# Monoid instance, and Semigroup derived beside a derived Monoid.
def add_import(text, line):
    m = re.search(r"^module\b.*?\bwhere\b[^\n]*\n", text, re.M | re.S)
    return text[:m.end()] + line + "\n" + text[m.end():] if m else text


for name, path in modules:
    text = open(path, errors="replace").read()
    new = text
    def semigroup(m):
        ctx, ty = m.group(2), m.group(3)
        head = (ctx + " => " if ctx else "") + "Data.Semigroup.Semigroup " + ty
        return ("%sinstance %s where\n    (<>) = mappend\n\n%s"
                % (m.group(1), head, m.group(0)))
    new = re.sub(r"^(\s*)instance\s+(?:\(?([^\n]*?)\)?\s*=>\s*)?Monoid\s+([^\n]+?)\s+where\b",
                 # (not Monoid in a context: instance Monoid x => FreeVars () x)
                 lambda m: semigroup(m) if "=>" not in m.group(3) and "=>" not in (m.group(2) or "") else m.group(0),
                 new, flags=re.M)
    new = re.sub(r"(deriving\s*\([^)]*?)\bMonoid\b", r"\1Data.Semigroup.Semigroup,Monoid", new)
    if new != text:
        new = add_import(new, "import qualified Data.Semigroup")
        open(path, "w").write(new)

# fail is MonadFail's now (base 4.13): a function whose signature has
# Monad m and whose clauses use fail gets MonadFail m.
def top_blocks(lines):
    blocks, cur = [], []
    for line in lines:
        if line and not line[0].isspace() and not line.startswith("--") and cur:
            blocks.append(cur)
            cur = []
        cur.append(line)
    if cur:
        blocks.append(cur)
    return blocks


failing = {"fail"}   # names whose use needs MonadFail (to a fixpoint)
# (not names any module may define for itself: a local f or mapM using
# fail is not another module's)
COMMON = {"mapM", "mapM_", "lookup", "match", "literal", "layout", "constant",
          "annotate", "con", "readHex", "sequence", "forM", "forM_", "when",
          "unless", "return", "fmap", "filter", "foldM", "zipWithM"}


def propagates(name):
    return len(name) >= 4 and name not in COMMON
changed_any = True
while changed_any:
    changed_any = False
    pattern = re.compile(r"\b(%s)\b" % "|".join(re.escape(n) for n in sorted(failing)))
    for name, path in modules:
        text = open(path, errors="replace").read()
        if not pattern.search(text):
            continue
        blocks = top_blocks(text.split("\n"))
        changed = False
        for i, b in enumerate(blocks):
            m = re.match(r"([a-z_][A-Za-z0-9_']*)\s*::", b[0])
            if not m:
                continue
            sig = "\n".join(b)
            fname = m.group(1)
            if not re.search(r"\bMonad\s+[a-z]", sig):
                continue
            body = []
            for b2 in blocks[i + 1:]:
                if re.match(re.escape(fname) + r"\b", b2[0]) or b2[0].startswith("--") or b2[0] == "":
                    body.extend(b2)
                else:
                    break
            if pattern.search("\n".join(body)):
                blocks[i] = re.sub(r"\bMonad(\s+[a-z])", r"MonadFail\1", sig).split("\n")
                if propagates(fname):
                    failing.add(fname)
                changed = True
        text2 = "\n".join("\n".join(b) for b in blocks)
        # class methods: an indented signature, and the method's clauses
        # anywhere in the module (its instances' and default's)
        lines = text2.split("\n")
        for i, line in enumerate(lines):
            m = re.match(r"(\s+)([a-z_][A-Za-z0-9_']*)\s*::(.*)", line)
            if not m or not re.search(r"\bMonad\s+[a-z]", m.group(3)):
                continue
            meth = m.group(2)
            body = []
            for j, l2 in enumerate(lines):
                m2 = re.match(r"(\s*)" + re.escape(meth) + r"\b[^:\n]*=", l2)
                if m2 and j != i:
                    ind = len(m2.group(1))
                    body.append(l2)
                    for l3 in lines[j + 1:]:
                        if l3.strip() == "" or len(l3) - len(l3.lstrip()) > ind:
                            body.append(l3)
                        else:
                            break
            if pattern.search("\n".join(body)):
                lines[i] = re.sub(r"\bMonad(\s+[a-z])", r"MonadFail\1", line)
                if propagates(meth):
                    failing.add(meth)
                changed = True
        if changed:
            changed_any = True
            open(path, "w").write("\n".join(lines))

# A Monad instance's fail is a MonadFail instance's now; a newtype deriving
# Monad (from State, whose fail was error) in a module using fail gets one
# whose fail is error.
def split_fail(text):
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"instance\s+((?:.*=>\s*)?)Monad\s+(.+?)\s+where\s*$", line)
        if not m:
            out.append(line)
            i += 1
            continue
        block = [line]
        j = i + 1
        while j < len(lines) and (lines[j].strip() == "" or lines[j][0].isspace()):
            block.append(lines[j])
            j += 1
        # the fail clause: its first line and those indented more
        k = next((n for n, l in enumerate(block) if re.match(r"\s+fail\b", l)), None)
        if k is None:
            out.extend(block)
            i = j
            continue
        ind = len(block[k]) - len(block[k].lstrip())
        e = k + 1
        while e < len(block) and (block[e].strip() == "" or len(block[e]) - len(block[e].lstrip()) > ind):
            e += 1
        fail_lines = block[k:e]
        rest = block[:k] + block[e:]
        out.extend(rest)
        out.append("")
        # (its context's Monad m is MonadFail m: RWST's fail is m's)
        ctx = re.sub(r"\bMonad(\s+[a-z])", r"MonadFail\1", m.group(1))
        out.append("instance %sMonadFail %s where" % (ctx, m.group(2)))
        out.extend(fail_lines)
        out.append("")
        i = j
    return "\n".join(out)


for name, path in modules:
    text = open(path, errors="replace").read()
    new = split_fail(text)
    if re.search(r"\bfail\b", new):
        def monadfail(m):
            params = m.group(2).split()
            if len(params) > 1:
                # over a transformer of its parameter m (VarNameT's StateT ..
                # m): MonadFail derived too, m's fail as before
                return re.sub(r"\bMonad\b", "Monad, MonadFail", m.group(0), count=1) \
                    if "deriving" in m.group(0) else m.group(0)
            return m.group(0) + "\ninstance MonadFail %s where\n    fail = error\n" % m.group(1)
        new = re.sub(r"^newtype\s+([A-Z][A-Za-z0-9_']*)((?:\s+[a-z][A-Za-z0-9_']*)*)\s*=[^\n]*\n(?:[ \t]+[^\n]*\n)*?[ \t]*deriving\s*\([^)]*\bMonad\b[^)]*\)[^\n]*",
                     monadfail, new, flags=re.M)
    if new != text:
        open(path, "w").write(new)

# old mtl's Monad (Either e) failed with Left (Error's strMsg); JHC's
# options parsing fails in Either String.
gen = os.path.join(src, "GenUtil.hs")
text = open(gen).read()
text = text.rstrip("\n") + ("\n\n-- (old mtl's: Either String's fail is Left)\n"
                            "instance MonadFail (Either String) where\n    fail = Left\n")
if "FlexibleInstances" not in text.split("\n")[0]:
    text = "{-# LANGUAGE FlexibleInstances #-}\n" + text
open(gen, "w").write(text)

# StringTable.Atom's addrToAtom_, a foreign import at Addr# for string
# literals ("Data.Ix"# 7#): the C function at the literal's characters.
atom = os.path.join(src, "StringTable", "Atom.hsc")
text = open(atom).read()
old = ('foreign import ccall unsafe "stringtable_lookup" addrToAtom_ '
       ':: Addr## -> Int## -> IO Atom')
assert old in text
text = text.replace(old, "addrToAtom_ :: Addr## -> Int## -> IO Atom\n"
                    "addrToAtom_ a n = withCStringLen (take (I## n) (unpackCString## a)) "
                    "(\\(p, l) -> stAdd p (fromIntegral l))")
open(atom, "w").write(text)

exts = """TypeFamilies ViewPatterns UndecidableInstances OverlappingInstances
    RecordWildCards RecursiveDo TupleSections ParallelListComp
    GeneralizedNewtypeDeriving ScopedTypeVariables FlexibleInstances
    TypeSynonymInstances MultiParamTypeClasses DeriveDataTypeable
    NoMonoLocalBinds NamedFieldPuns
    ForeignFunctionInterface UnliftedFFITypes ImplicitParams UnboxedTuples
    StandaloneDeriving DeriveFunctor DeriveFoldable DeriveTraversable DeriveGeneric
    FlexibleContexts ConstrainedClassMethods FunctionalDependencies MagicHash
    PolymorphicComponents ExistentialQuantification UnicodeSyntax PostfixOperators
    PatternGuards LiberalTypeSynonyms RankNTypes TypeOperators
    EmptyDataDecls KindSignatures BangPatterns"""
cabal = """cabal-version: 2.0
name: jhc
version: 0.8.2
build-type: Simple

library
  hs-source-dirs: src
  default-language: Haskell2010
  default-extensions: %s
  build-depends: base, array, binary, bytestring, containers, directory, fgl,
    filepath, HsSyck, mtl, old-time, pretty, process, random, regex-compat,
    syb, unix, utf8-string, zlib
  include-dirs: src src/data src/StringTable src/cbits
  cc-options: -std=c99 -O2
  c-sources: src/StringTable/StringTable_cbits.c src/cbits/md5sum.c src/cbits/lookup3.c
  exposed-modules:
%s

executable jhc
  hs-source-dirs: main
  main-is: Main.hs
  default-language: Haskell2010
  build-depends: base, jhc
""" % (exts, "\n".join("    " + n for n, _ in modules))
open(os.path.join(stage, "jhc.cabal"), "w").write(cabal)
print("%d modules" % len(modules))
