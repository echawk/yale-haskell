;;; launcher.lisp -- the yale-haskell executable on Lisps other than SBCL
;;; (ECL, ABCL; doc/plans/PORTABILITY.md), whose path is the last
;;; command-line argument.  They cannot (portably) save an image, so the
;;; executable is a shell script that starts the Lisp on start.lisp,
;;; which loads the files runtime.lisp loads, already compiled here.
;;; On SBCL, image.lisp builds a saved image with ASDF instead.

(load "tools/build/runtime.lisp")

(in-package :mumble-user)

(lisp:setq lisp:*readtable* mumble-implementation:*mumble-readtable*)

;;; The environment the compiler reads (as the Makefile's dialect_env),
;;; and a check that the build is current: the launcher would otherwise
;;; recompile stale files at startup, unsafely when several run at once.

(define (launcher-environment root out)
  (let* ((build    (lisp:namestring
		    (lisp:make-pathname :name lisp:nil :defaults out)))
	 (dialect  (car (lisp:last (lisp:pathname-directory out))))
	 (lisp     (car (lisp:last (lisp:butlast (lisp:pathname-directory out))))))
    (format '#f "Y2=${Y2:-~a}
HASKELL=$Y2
PRELUDE=$Y2/lib/~a/prelude
PRELUDEBIN=~aprelude
HASKELL_LIBRARY=$Y2/lib/~a
LIBRARYBIN=~alib
export Y2 HASKELL PRELUDE PRELUDEBIN HASKELL_LIBRARY LIBRARYBIN
if [ -n \"$(find \"$Y2/src\" \"$Y2/tools/build\" -newer \"$Y2/build/~a/.compiler-stamp\" -name '*.*' 2>/dev/null | head -1)\" ]; then
  echo \"yale-haskell: sources changed since the build; run make LISP=~a.\" >&2
  exit 1
fi"
	    (string-right-trim-slash root) dialect build dialect build lisp lisp)))

(define (string-right-trim-slash s)
  (lisp:string-right-trim "/" s))

(let* ((out   (car (last (uiop:raw-command-line-arguments))))
       (start (lisp:namestring (lisp:truename "tools/build/start.lisp")))
       (lisp-command
	;; Haskell programs recurse deeply.  ECL runs them on the main
	;; thread, so its C stack is made as large as the system allows.
	#+ecl (format '#f "ulimit -s hard 2>/dev/null
case $(ulimit -s) in
  unlimited) stack=1073741824 ;;
  *) stack=$(( $(ulimit -s) * 1024 - 1048576 )) ;;
esac
exec ecl --norc --c-stack $stack --lisp-stack 268435456 --shell '~a' -- \"$@\"" start)
	;; ABCL: this JVM and abcl.jar, with a large stack for the
	;; interpreter thread
	#+abcl (format '#f "exec '~a/bin/java' -Xss512m -Xmx4g --add-opens java.base/java.lang=ALL-UNNAMED -cp '~a' org.armedbear.lisp.Main --noinit --noinform --batch --load '~a' -- \"$@\""
		       (java:jstatic "getProperty" "java.lang.System" "java.home")
		       (java:jstatic "getProperty" "java.lang.System" "java.class.path")
		       start)))
  (lisp:with-open-file (s (lisp:ensure-directories-exist out)
			  :direction :output :if-exists :supersede)
    (format s "#!/bin/sh~%# yale-haskell on ~a: load the compiled system and run.~%~a~%~a~%"
	    (lisp:lisp-implementation-type)
	    (launcher-environment (lisp:namestring (lisp:truename "./")) out)
	    lisp-command))
  (uiop:run-program (list "chmod" "+x" out))
  (exit 0))
