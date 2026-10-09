#!/usr/bin/env python3
"""Check that each Haskell 2010 library module (Report Part II) exports what
the Report lists: for each module, import exactly its export list and see
whether Yale Haskell accepts it.

    tools/conformance/h2010-exports.py [MODULE...]

Needs ref/haskell2010-report (git clone https://github.com/haskell/haskell-report)
and a built haskell98 dialect.  Prints the names each module lacks."""

import os, re, subprocess, sys, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIBS = os.path.join(ROOT, "ref/haskell2010-report/report/libs")

def exports(tex):
    text = open(tex).read()
    m = re.search(r"module\s+([\w.]+)\s*\((.*?)\)\s*where", text, re.S)
    name, body = m.group(1), m.group(2)
    items, depth, cur = [], 0, ""
    for ch in body:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            items.append(cur.strip()); cur = ""
        else:
            cur += ch
    if cur.strip():
        items.append(cur.strip())
    items = [i for i in items if i and not i.startswith("module ")]
    # the Report writes an operator constructor as Complex(:+)
    items = [re.sub(r"\((:[^\w\s(),]+)\)$", r"((\1))", re.sub(r"\s+", " ", i)) for i in items]
    return name, items

def check(module, items):
    """The items Yale Haskell rejects: try them all, then one at a time."""
    def ok(names):
        with tempfile.TemporaryDirectory() as d:
            f = os.path.join(d, "Check.hs")
            imp = ", ".join("(%s)" % n if re.match(r"^[^\w(]", n) else n for n in names)
            open(f, "w").write("module Main where\nimport %s (%s)\nmain :: IO ()\nmain = return ()\n" % (module, imp))
            r = subprocess.run([os.path.join(ROOT, "bin/yale-haskell"), "--haskell98",
                                "--haskell2010", f], capture_output=True, text=True)
            out = r.stdout + r.stderr
            return r.returncode == 0 and "error" not in out.lower(), out
    good, out = ok(items)
    if good:
        return [], None
    if "Cannot find module" in out or "UNDEFINED-MODULE" in out:
        return items, "module missing"
    return [i for i in items if not ok([i])[0]], None

def main():
    wanted = sys.argv[1:]
    total = 0
    for tex in sorted(os.listdir(LIBS)):
        module, items = exports(os.path.join(LIBS, tex))
        if wanted and module not in wanted:
            continue
        missing, note = check(module, items)
        total += len(missing)
        if note:
            print("%-28s %s" % (module, note))
        elif missing:
            print("%-28s missing %d: %s" % (module, len(missing), " ".join(missing)))
        else:
            print("%-28s ok (%d)" % (module, len(items)))
    sys.exit(1 if total else 0)

main()
