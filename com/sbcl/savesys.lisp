;;; savesys.lisp -- body of the com/sbcl/savesys script.
;;; This is read in MUMBLE-USER, where CL symbols need a lisp: prefix.

(in-package :mumble-user)

(setf lisp:*load-verbose* '#f)
(setf lisp:*compile-verbose* '#f)
(setf *printers* '(compiling loading))
(setf *optimizers* '())
(setf *compile-interface* '#f)

(compile/load *prelude-unit-filename*)

;;; With a file argument, compile and run its Main.main and exit;
;;; otherwise start the interactive command interface.

;;; string->symbol interns in the current package, so the compiler only
;;; works when *package* is MUMBLE-USER, as it was when this was loaded.

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

(sb-ext:save-lisp-and-die "build/sbcl/yale-haskell.core"
  :toplevel 'haskell-toplevel)
