;;; prelude.lisp -- compile the standard prelude into $PRELUDEBIN.

(load "tools/build/compiler.lisp")

(in-package :mumble-user)

;;; Read the rest of this file with mumble's #t/#f syntax.
(lisp:setq lisp:*readtable* mumble-implementation:*mumble-readtable*)

(setf *printers* '(phase-time))
(setf *optimizers* *all-optimizers*)
(setf *code-chunk-size* 300)
(setf *compile-interface* '#f)
(compile/compile *prelude-unit-filename*)
