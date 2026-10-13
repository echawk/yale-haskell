#!/usr/bin/env python3
"""Build darcs 1.0.9 with Yale Haskell and run a scripted session with it.

    tools/conformance/darcs.py [-v] [--unit]

darcs 1.0.9 (2007, GPL; about 25,000 lines of Haskell 98 with GHC 6.6
extensions) is fetched into ref/ and copied to build/conformance/darcs,
where it runs as `yale-haskell --haskell98 --cpp -D__GLASGOW_HASKELL__=606
darcs.lhs`.  The build copy is adapted as configure would, and for the
base library GHC 6.6 had:

- Autoconf.lhs and ThisVersion.lhs are filled in from their .in
  templates (no libcurl, no mmap; sendmail, colour);
- Workaround.hs is configure's output for a POSIX system
  (tools/conformance/darcs/Workaround.hs);
- Control.Exception is base 3's, the Exception data type: darcs imports
  OldException (tools/conformance/darcs/OldException.hs) instead;
- DarcsUtils.lhs used GHC.IOBase's IOException fields
  (tools/conformance/darcs/DarcsUtils.patch);
- darcs's C helpers (fpstring.c, atomic_create.c, ...) are built into
  libdarcs.dylib (or .so) and loaded with -l.

The session (init, add, record, whatsnew, changes, get, pull, a conflict,
diff, annotate, unrecord) is compared with tools/conformance/darcs/
session.out, after dates are replaced.  --unit also runs darcs's own
QuickCheck tests (unit.lhs, about a minute); their cases are random, so
only the counts are reported.  Those not passing are darcs's own as far as
we can tell: properties whose subcommute darcs's generators never exercise
(the Conflictor ones) end "Arguments exhausted", and the occasional
falsification involves a merger of conflicting patches or a "-conflict"
name (the double commute fails by commute_nameconflict); with a fixed seed
the results are the same with the optimizers off and on the FLIC back end.
"""

import argparse
import glob
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERE = os.path.join(ROOT, 'tools', 'conformance', 'darcs')
REF = os.path.join(ROOT, 'ref', 'darcs-1.0.9')
WORK = os.path.join(ROOT, 'build', 'conformance', 'darcs')
YALE = os.path.join(ROOT, 'bin', 'yale-haskell')
URL = 'http://darcs.net/releases/darcs-1.0.9.tar.gz'
SHA256 = 'a5fe4d5a743d8052d6cbfcea480a44593f821afd8a42e6d6d4ae37d40ed23cd8'
LIB = 'libdarcs.dylib' if sys.platform == 'darwin' else 'libdarcs.so'
C_FILES = ['fpstring.c', 'atomic_create.c', 'c_compat.c', 'maybe_relink.c', 'umask.c']

AUTOCONF = {
    'configure_input': 'written for Yale Haskell (tools/conformance/darcs.py)',
    'sysconfdir': '/usr/local/etc', 'datadir': '/usr/local/share',
    'libexecdir': '/usr/local/libexec', 'HAVE_LIBCURL': 'False',
    'USE_COLOR': 'True', 'USE_MMAP': 'False', 'SENDMAIL': '/usr/sbin/sendmail',
    'HAVE_SENDMAIL': 'True', 'HAVE_MAPI': 'False', 'DIFF': 'diff',
    'GHC_SEPARATOR': ':', 'BIGENDIAN': 'False',
    'DARCS_VERSION': '1.0.9', 'DARCS_VERSION_STATE': 'release',
}


def fetch():
    if os.path.isdir(REF):
        return
    tmp = REF + '.tar.gz'
    urllib.request.urlretrieve(URL, tmp)
    with open(tmp, 'rb') as f:
        if hashlib.sha256(f.read()).hexdigest() != SHA256:
            sys.exit('darcs-1.0.9.tar.gz is not the version expected')
    with tarfile.open(tmp) as t:
        t.extractall(os.path.dirname(REF), filter='data')
    os.remove(tmp)


def setup():
    """The build copy: darcs's sources, adapted; reused while current."""
    stamp = os.path.join(WORK, '.yale-setup')
    inputs = [f for f in glob.glob(os.path.join(HERE, '*')) if not f.endswith('.out')]
    inputs.append(os.path.abspath(__file__))
    if (os.path.exists(stamp) and os.path.exists(os.path.join(WORK, LIB))
            and all(os.path.getmtime(f) < os.path.getmtime(stamp) for f in inputs)):
        return
    if os.path.isdir(WORK):
        shutil.rmtree(WORK)
    os.makedirs(WORK)
    for f in os.listdir(REF):
        if f.endswith(('.lhs', '.hs', '.c', '.h')):
            shutil.copy(os.path.join(REF, f), WORK)
    for name in ['Autoconf.lhs', 'ThisVersion.lhs']:
        s = open(os.path.join(REF, name + '.in')).read()
        s = re.sub(r'@(\w+)@', lambda m: AUTOCONF[m.group(1)], s)
        open(os.path.join(WORK, name), 'w').write(s)
    for f in glob.glob(os.path.join(WORK, '*hs')):
        s = open(f, encoding='latin-1').read()
        if 'Control.Exception' in s:
            open(f, 'w', encoding='latin-1').write(s.replace('Control.Exception', 'OldException'))
    shutil.copy(os.path.join(HERE, 'OldException.hs'), WORK)
    shutil.copy(os.path.join(HERE, 'Workaround.hs'), WORK)
    subprocess.run(['patch', '-s', '-p0', '-i', os.path.join(HERE, 'DarcsUtils.patch')],
                   cwd=WORK, check=True)
    subprocess.run(['cc', '-O2', '-shared', '-fPIC', '-I', os.path.join(HERE, 'include'),
                    '-o', LIB] + C_FILES + ['-lz'], cwd=WORK, check=True)
    open(stamp, 'w').close()


def darcs_command():
    return [YALE, '--haskell98', '--cpp', '-D__GLASGOW_HASKELL__=606',
            '-l', os.path.join(WORK, LIB), os.path.join(WORK, 'darcs.lhs')]


# The session: shell steps run in a scratch directory with `darcs' meaning
# the Yale-built darcs.  Each step's command and output go to the log.
SESSION = r'''
darcs init --repodir=a
cd a; printf 'hello\nworld\n' > hello.txt; mkdir src; printf 'main = print 1\n' > src/Main.hs
cd a; darcs add hello.txt src src/Main.hs
cd a; darcs whatsnew --summary
cd a; darcs record --all --author=tester@example.com -m 'First version'
cd a; printf 'hello\nthere\nworld\n' > hello.txt; darcs whatsnew
cd a; darcs record --all --author=tester@example.com -m 'Say there'
cd a; darcs changes --summary
darcs get a b
cd b; printf 'hello\nthere\nworld\nagain\n' > hello.txt; darcs record --all --author=other@example.com -m 'Again'
cd a; darcs pull --all ../b
cd a; cat hello.txt; darcs changes --last=1
cd a; darcs mv src/Main.hs src/Hello.hs; darcs record --all --author=tester@example.com -m 'Rename'
cd a; darcs changes --last=1 --summary
cd a; printf 'HELLO\nthere\nworld\nagain\n' > hello.txt; darcs record --all --author=tester@example.com -m 'Shout'
cd b; printf 'Hello\nthere\nworld\nagain\n' > hello.txt; darcs record --all --author=other@example.com -m 'Capitalize'
cd a; darcs pull --all ../b
cd a; cat hello.txt
cd a; darcs whatsnew
cd a; darcs revert --all; cat hello.txt
cd b; darcs diff -u --last=1
cd b; darcs annotate hello.txt
cd b; darcs unrecord --last=1 --all; darcs changes
cd b; darcs whatsnew
cd b; darcs check
'''


def normalize(text, scratch):
    text = text.replace(scratch, '<dir>')
    # progress reports, overwritten with \r and shown only on a slow step
    text = re.sub(r'(Copying|Applying) patch \d+ of \d+\.\.\.( done\.)?', '', text)
    text = re.sub(r'[\r\n]*\r', '', text)
    text = re.sub(r'(\$ [^\n]*\n)\s*\n', r'\1', text)
    # darcs's dates: "Tue Oct 13 10:20:30 EDT 2026", patch hashes and times
    text = re.sub(r'\w{3} \w{3} [ \d]\d \d\d:\d\d:\d\d \w+ \d{4}', '<date>', text)
    text = re.sub(r'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d', '<date>', text)
    text = re.sub(r'\d{14}', '<time>', text)
    return text


def run_session(verbose):
    scratch = tempfile.mkdtemp(prefix='darcs-session-')
    bindir = os.path.join(scratch, 'bin')
    os.makedirs(bindir)
    wrapper = os.path.join(bindir, 'darcs')
    with open(wrapper, 'w') as f:
        f.write('#!/bin/sh\nexec %s "$@"\n' % ' '.join("'%s'" % a for a in darcs_command()))
    os.chmod(wrapper, 0o755)
    # HOME is the scratch directory (darcs reads ~/.darcs); the unit cache
    # stays where it was
    cache = (os.environ.get('YALE_HASKELL_CACHE_DIR')
             or os.path.join(os.environ.get('XDG_CACHE_HOME')
                             or os.path.join(os.environ['HOME'], '.cache'), 'yale-haskell'))
    env = dict(os.environ, PATH=bindir + os.pathsep + os.environ['PATH'],
               HOME=scratch, YALE_HASKELL_CACHE_DIR=cache, DARCS_DONT_COLOR='1', DARCS_DONT_ESCAPE_ANYTHING='1',
               TZ='UTC', LC_ALL='C')
    env.pop('DARCS_EMAIL', None)
    env.pop('EMAIL', None)
    log = []
    for step in SESSION.strip().split('\n'):
        p = subprocess.run(['/bin/sh', '-c', step], cwd=scratch, env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        out = p.stdout.decode('utf-8', 'replace')
        log.append('$ %s\n%s%s' % (step, out, '' if p.returncode == 0
                                   else '[exit %d]\n' % p.returncode))
        if verbose:
            sys.stdout.write(log[-1])
    shutil.rmtree(scratch)
    return normalize(''.join(log), scratch)


def run_unit():
    start = time.time()
    p = subprocess.run(darcs_command()[:-1] + [os.path.join(WORK, 'unit.lhs')],
                       cwd=WORK, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out = p.stdout.decode('utf-8', 'replace').replace('\b', '')
    out = re.sub(r'\.\.\. \d+', '... ', out)
    counts = [(k, len(re.findall(k, out))) for k in
              ['OK, passed', 'Arguments exhausted', 'Falsifiable']]
    print('unit.lhs: %s (%.0fs)' % (', '.join('%d %s' % (n, k) for k, n in counts),
                                   time.time() - start))
    for m in re.finditer(r'Checking ([^\n]*?)\.\.\. *Falsifiable[^\n]*\n((?:[^\n]+\n)*)', out):
        print('  falsified: %s\n    %s' % (m.group(1), m.group(2).strip().replace('\n', '\n    ')))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-v', action='store_true', help='show the session as it runs')
    ap.add_argument('--unit', action='store_true', help="also run darcs's unit tests")
    ap.add_argument('--accept', action='store_true', help='write session.out')
    a = ap.parse_args()
    fetch()
    setup()
    start = time.time()
    # the first run compiles darcs (into the unit cache)
    p = subprocess.run(darcs_command() + ['--version'], stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    if p.returncode != 0:
        print(p.stderr.decode('utf-8', 'replace')[-3000:])
        sys.exit('darcs did not compile')
    print('darcs %s compiled (%.0fs)' % (p.stdout.decode().strip(), time.time() - start))
    start = time.time()
    out = run_session(a.v)
    expected = os.path.join(HERE, 'session.out')
    if a.accept:
        open(expected, 'w').write(out)
    want = open(expected).read()
    steps = out.count('\n$ ') + 1
    if out == want:
        print('session: %d steps match (%.0fs)' % (steps, time.time() - start))
    else:
        import difflib
        sys.stdout.writelines(difflib.unified_diff(want.splitlines(True), out.splitlines(True),
                                                   'session.out', 'got'))
    if a.unit:
        run_unit()
    if out != want:
        sys.exit(1)


if __name__ == '__main__':
    main()
