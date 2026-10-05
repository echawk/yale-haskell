;;; image.lisp -- load the compiler and the compiled prelude and save
;;; a standalone executable.  The output path is the last command-line
;;; argument.  This is read in MUMBLE-USER after the first form, where
;;; CL symbols need a lisp: prefix.

(load "tools/build/compiler.lisp")

(in-package :mumble-user)

(setf lisp:*load-verbose* '#f)
(setf lisp:*compile-verbose* '#f)
(setf *printers* '(compiling loading))
(setf *optimizers* '())
(setf *compile-interface* '#f)

(compile/load *prelude-unit-filename*)

;;; string->symbol interns in the current package, so the compiler only
;;; works when *package* is MUMBLE-USER, as it is while this file loads.
;;;
;;; With a file argument, compile and run its Main.main and exit;
;;; otherwise start the interactive command interface.

(define (haskell-toplevel)
  (setf lisp:*package* (lisp:find-package "MUMBLE-USER"))
  (let ((args (cdr sb-ext:*posix-argv*)))
    (if (pair? args)
	(begin
	  (setf *printers* '())
	  (run-program (car args))
	  (lisp:force-output)
	  (sb-ext:exit :code 0))
	(begin
	  (load-init-files)
	  (do () ('#f)
	    (lisp:with-simple-restart (restart-haskell "Restart Haskell.")
	      (heval)))))))

(define (restart-haskell)
  (lisp:invoke-restart 'restart-haskell))

(sb-ext:save-lisp-and-die (car (last sb-ext:*posix-argv*))
  :toplevel 'haskell-toplevel
  :executable '#t
  :save-runtime-options '#t)
