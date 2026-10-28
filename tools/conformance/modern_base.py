#!/usr/bin/env python3
"""Fixups for sources written for an older base, for Yale Haskell's
(base 4.13 and later: MonadFail, Semigroup).

modern_base.py FILE...: applies them to each FILE in place.  The stage
scripts (ghc/stage.py) import the functions."""
import re
import sys


def add_import(text, line):
    """LINE after the module header (a first import may be inside an #if)."""
    m = re.search(r"^module\b.*?\bwhere\b[^\n]*\n", text, re.M | re.S)
    return text[:m.end()] + line + "\n" + text[m.end():] if m else text


def outside_cpp(text, pos):
    """Whether POS is outside every #if (whose branch may not be taken)."""
    depth = 0
    for line in text[:pos].split("\n"):
        if re.match(r"#\s*if", line):
            depth += 1
        elif re.match(r"#\s*endif", line):
            depth -= 1
    return depth <= 0


def blank_comments(text):
    """TEXT with its block comments ({- -}, nested) blanked, positions kept."""
    out, depth, i = [], 0, 0
    while i < len(text):
        two = text[i:i + 2]
        if two == "{-":
            depth += 1
            out.append("  ")
            i += 2
        elif two == "-}" and depth > 0:
            depth -= 1
            out.append("  ")
            i += 2
        else:
            ch = text[i]
            out.append(ch if depth == 0 or ch == "\n" else " ")
            i += 1
    return "".join(out)


def hide_prelude(text, names):
    """Today's Prelude has NAMES (<>: base 4.11), which the module's own or
    another library's clash with: the Prelude's hidden."""
    hidden = "import Prelude hiding (%s)" % ", ".join(names)
    code = blank_comments(text)
    m = re.search(r"^import\s+Prelude\s+hiding\s*\(", code, re.M)
    if m and outside_cpp(text, m.start()):
        return text[:m.end()] + " ".join(n + "," for n in names) + " " + text[m.end():]
    m = re.search(r"^import\s+Prelude[ \t]*(--[^\n]*)?$", code, re.M)
    if m and outside_cpp(text, m.start()):
        return text[:m.start()] + hidden + text[m.end():]
    m = re.search(r"^import\s+(qualified\s+)?Prelude\b", code, re.M)
    if m and outside_cpp(text, m.start()):
        # (an import list, or qualified only: no implicit Prelude)
        return text
    # (none, or only under an #if: GHC 7's)
    return add_import(text, hidden)


def split_fail(text):
    """A Monad instance's fail is a MonadFail instance's now (base 4.13)."""
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
        out.extend(block[:k] + block[e:])
        # (one the module has already: GHC 8.0's, under #if)
        ty = re.escape(m.group(2).strip()).replace(r"\ ", r"\s+")
        if re.search(r"instance\s+(?:[^\n]*=>\s*)?(?:[\w.]*\.)?MonadFail\s+" + ty + r"\s+where", text):
            i = j
            continue
        out.append("")
        # (its context's Monad m is MonadFail m: a transformer's fail is m's)
        ctx = re.sub(r"\bMonad(\s+[a-z])", r"MonadFail\1", m.group(1))
        out.append("instance %sControl.Monad.Fail.MonadFail %s where" % (ctx, m.group(2)))
        out.extend(fail_lines)
        out.append("")
        i = j
    new = "\n".join(out)
    if new != text and not re.search(r"^import\s+(qualified\s+)?Control\.Monad\.Fail\b", new, re.M):
        new = add_import(new, "import qualified Control.Monad.Fail")
    return new


def add_semigroup(text):
    """Monoid instances want Semigroup ones (base 4.11): one beside each
    Monoid instance whose module has none, (<>) its mappend."""
    def semigroup(m):
        ctx, ty = m.group(2), m.group(3)
        if "=>" in ty or "=>" in (ctx or ""):
            return m.group(0)
        bare = re.escape(ty.strip()).replace(r"\ ", r"\s+")
        if re.search(r"instance\s+(?:[^\n]*=>\s*)?(?:[A-Z]\w*\.)*Semigroup\s+" + bare + r"\s+where", text):
            return m.group(0)
        head = (ctx + " => " if ctx else "") + "Data.Semigroup.Semigroup " + ty
        return ("%sinstance %s where\n    (<>) = mappend\n\n%s"
                % (m.group(1), head, m.group(0)))
    new = re.sub(r"^(\s*)instance\s+(?:\(?([^\n]*?)\)?\s*=>\s*)?(?:Data\.Monoid\.)?Monoid\s+([^\n]+?)\s+where\b",
                 semigroup, text, flags=re.M)
    if new != text:
        new = add_import(new, "import qualified Data.Semigroup")
    return new


if __name__ == "__main__":
    for path in sys.argv[1:]:
        text = open(path, errors="replace").read()
        new = add_semigroup(split_fail(text))
        if new != text:
            open(path, "w").write(new)
