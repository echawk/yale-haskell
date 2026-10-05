;;; prelude.lisp -- compile the standard prelude into $PRELUDEBIN.

(load "tools/build/compiler.lisp")

(in-package :mumble-user)

(setf *printers* '(phase-time))
(setf *optimizers* *all-optimizers*)
(setf *code-chunk-size* 300)
(setf *compile-interface* '#f)
(compile/compile *prelude-unit-filename*)
