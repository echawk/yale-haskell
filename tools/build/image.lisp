;;; image.lisp -- load the compiler and the compiled prelude and save
;;; a standalone executable.  The output path is the last command-line
;;; argument.  This is read in MUMBLE-USER after the first form, where
;;; CL symbols need a lisp: prefix.

(load "tools/build/compiler.lisp")

(in-package :mumble-user)

;;; Read the rest of this file with mumble's #t/#f syntax.
(lisp:setq lisp:*readtable* mumble-implementation:*mumble-readtable*)

(setf lisp:*load-verbose* '#f)
(setf lisp:*compile-verbose* '#f)
(setf *printers* '(compiling loading))
(setf *optimizers* *all-optimizers*)
(setf *compile-interface* '#f)

(compile/load *prelude-unit-filename*)

;;; string->symbol interns in the current package, so the compiler only
;;; works when *package* is MUMBLE-USER, as it is while this file loads.
;;;
;;; With a file argument, compile and run its Main.main and exit;
;;; otherwise start the interactive command interface.
;;;
;;; In batch mode the program's output is the only thing on stdout;
;;; errors go to stderr and give exit status 1.  The host compiler's
;;; style warnings about generated code are muffled.

(lisp:declaim (sb-ext:muffle-conditions lisp:style-warning
					sb-ext:compiler-note))

(define (batch-run file args)
  ;; getArgs, getProgName and exitWith (src/runtime/system-prims.mumble)
  (set-haskell-program-args file args)
  (setf *haskell-batch-mode* '#t)
  ;; compiler diagnostics go to stderr, leaving stdout to the program
  (setf *error-output-port* lisp:*error-output*)
  ;; Haskell runtime errors (error, head [], ...) normally return to the
  ;; REPL; in batch mode they end the program with status 1.
  (setf (lisp:symbol-function 'haskell-runtime-error)
	(lambda (msg)
	  (lisp:force-output)
	  (lisp:format lisp:*error-output* "~&Haskell runtime abort.~%~a~%" msg)
	  (lisp:finish-output lisp:*error-output*)
	  (sb-ext:exit :code 1 :abort '#t)))
  (let ((status
	 (lisp:handler-case
	     (lisp:handler-bind ((lisp:warning
				  (lambda (c)
				    (lisp:muffle-warning c))))
	       (if (run-program file) 0 1))
	   (lisp:error (c)
	     (lisp:force-output)
	     (lisp:format lisp:*error-output* "~&yale-haskell: ~a~%" c)
	     1))))
    (lisp:force-output)
    (lisp:finish-output lisp:*error-output*)
    (sb-ext:exit :code status :abort '#t)))


;;; The statistical profiler, for the interactive system's :profile: a
;;; saved executable cannot find SBCL's contrib modules to require them
;;; later, so it is loaded now.
(lisp:require :sb-sprof)

;;; The command line (src/cli/cli.lisp, plain CL over clingon, installed
;;; with ocicl) is the executable's entry point.

(lisp:require :asdf)
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(lisp:merge-pathnames "ocicl/" (lisp:truename "./")))
		    :inherit-configuration))
(lisp:handler-case (lisp:let ((lisp:*package* (lisp:find-package "CL-USER"))
			      (lisp:*readtable* (lisp:copy-readtable lisp:nil)))
		     (asdf:load-system :clingon))
  (lisp:error (c)
    (lisp:format lisp:*error-output*
		 "~&Cannot load clingon (~a).~%Run `ocicl install' in the source directory.~%" c)
    (sb-ext:exit :code 1)))
;;; cli.lisp is plain CL: compile it in CL-USER with the standard readtable.
(lisp:let ((lisp:*package* (lisp:find-package "CL-USER"))
	   (lisp:*readtable* (lisp:copy-readtable lisp:nil)))
  (lisp:load (lisp:compile-file "src/cli/cli.lisp"
				:output-file (lisp:merge-pathnames
					      "build/sbcl/cli.fasl" (lisp:truename "./")))))

(define (haskell-toplevel)
  (lisp:funcall (lisp:find-symbol "MAIN" "YALE-HASKELL-CLI")))

(sb-ext:save-lisp-and-die (car (last sb-ext:*posix-argv*))
  :toplevel 'haskell-toplevel
  :executable '#t
  :save-runtime-options '#t)
