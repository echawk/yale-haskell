;;; runtime.lisp -- load the compiler, the compiled prelude, the
;;; command line and the base and FFI runtimes: everything the
;;; yale-haskell executable holds, on Lisps other than SBCL:
;;; launcher.lisp writes a launcher that loads it at startup
;;; (start.lisp).  On SBCL the executable is built with ASDF instead
;;; (yale-haskell/executable in yale-haskell.asd, tools/build/image.lisp).  Run from the top of the source tree ($Y2).  This is read
;;; in MUMBLE-USER after the first form, where CL symbols need a lisp:
;;; prefix.

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

#+sbcl
(lisp:declaim (sb-ext:muffle-conditions lisp:style-warning
					sb-ext:compiler-note))

;;; batch-run and emit-run, the command line's drivers, are in
;;; src/compiler/command-interface/batch.mumble.


;;; The statistical profiler, for the interactive system's :profile: a
;;; saved executable cannot find SBCL's contrib modules to require them
;;; later, so it is loaded now.
#+sbcl
(lisp:require :sb-sprof)

;;; Plain CL files (the command line, src/cli/cli.lisp, and the base and
;;; FFI runtimes) are compiled in CL-USER with the standard readtable,
;;; into build/<lisp>/, when out of date.

(define (load-plain-cl-file source)
  (let* ((root    (lisp:truename "./"))
	 (src     (lisp:merge-pathnames source root))
	 (fasl    (lisp:merge-pathnames
		   (lisp:compile-file-pathname
		    (lisp:concatenate 'lisp:string
		      "build/" mumble-implementation::*lisp-implementation-name*
		      "/" (lisp:pathname-name src) ".lisp"))
		   root)))
    (lisp:let ((lisp:*package* (lisp:find-package "CL-USER"))
	       (lisp:*readtable* (lisp:copy-readtable lisp:nil)))
      (when (or (not (lisp:probe-file fasl))
		(< (lisp:file-write-date fasl) (lisp:file-write-date src)))
	(lisp:compile-file src :output-file (lisp:ensure-directories-exist fasl)))
      (lisp:load fasl))))

;;; The command line is plain CL over clingon, and the foreign function
;;; interface uses CFFI, both installed with ocicl.

(lisp:require :asdf)
(asdf:initialize-source-registry
 `(:source-registry (:tree ,(lisp:merge-pathnames "ocicl/" (lisp:truename "./")))
		    :inherit-configuration))

(define (load-asdf-system name)
  (lisp:handler-case (lisp:let ((lisp:*package* (lisp:find-package "CL-USER"))
				(lisp:*readtable* (lisp:copy-readtable lisp:nil)))
		       (asdf:load-system name))
    (lisp:error (c)
      (lisp:format lisp:*error-output*
		   "~&Cannot load ~(~a~) (~a).~%Run `ocicl install' in the source directory.~%"
		   name c)
      (exit 1))))

;;; with-user-abort, which clingon uses, does not know ABCL.
#+abcl
(begin
  (load-plain-cl-file "src/cli/abcl-with-user-abort.lisp")
  (asdf:register-immutable-system "with-user-abort"))
(load-asdf-system :clingon)

;;; CFFI needs JNA on ABCL; without it there is no foreign function
;;; interface, and the base runtime uses portable fallbacks (feature
;;; :yale-cffi).
(lisp:when (lisp:ignore-errors
	    (lisp:let ((lisp:*package* (lisp:find-package "CL-USER"))
		       (lisp:*readtable* (lisp:copy-readtable lisp:nil)))
	      (asdf:load-system :cffi)
	      ;; on ABCL the system loads but needs JNA to work
	      (lisp:funcall (lisp:intern "FOREIGN-SYMBOL-POINTER" "CFFI") "getenv")))
  (lisp:pushnew ':yale-cffi lisp:*features*)
  (load-plain-cl-file "src/ffi/ffi-runtime.lisp")
  ;; errno values (tools/gen/gen-errno.sh), when generated for this system
  (let ((errnos (lisp:format lisp:nil "src/ffi/errno-~(~a~).lisp"
			     (lisp:software-type))))
    (when (lisp:probe-file errnos)
      (load-plain-cl-file errnos))))
(load-plain-cl-file "src/base/base-runtime.lisp")
(load-plain-cl-file "src/cli/cli.lisp")

(define (haskell-toplevel)
  (lisp:funcall (lisp:find-symbol "MAIN" "YALE-HASKELL-CLI")))
