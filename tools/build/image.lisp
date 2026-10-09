;;; image.lisp -- build the yale-haskell executable, whose path is the
;;; last command-line argument.  On SBCL this saves an image holding
;;; everything runtime.lisp loads.  Other Lisps cannot (portably) save
;;; one, so the executable is a shell script that starts the Lisp on
;;; start.lisp, which loads the same files, already compiled here.

(load "tools/build/runtime.lisp")

(in-package :mumble-user)

(lisp:setq lisp:*readtable* mumble-implementation:*mumble-readtable*)

#+sbcl
(sb-ext:save-lisp-and-die (car (last sb-ext:*posix-argv*))
  :toplevel 'haskell-toplevel
  :executable '#t
  :save-runtime-options '#t)

#-sbcl
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
    (format s "#!/bin/sh~%# yale-haskell on ~a: load the compiled system and run.~%: \"${Y2:=~a}\"~%export Y2~%~a~%"
	    (lisp:lisp-implementation-type)
	    (lisp:namestring (lisp:truename "./"))
	    lisp-command))
  (uiop:run-program (list "chmod" "+x" out))
  (exit 0))
