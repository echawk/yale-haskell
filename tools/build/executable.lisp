;;; executable.lisp -- the first component of yale-haskell/executable
;;; (yale-haskell.asd): settings for the files after it and for the
;;; saved executable.

(in-package :cl-user)

;;; CFFI works on SBCL, so the base runtime uses it (src/base/base-runtime.lisp
;;; has portable fallbacks for Lisps where it does not: tools/build/runtime.lisp).
(eval-when (:compile-toplevel :load-toplevel :execute)
  (pushnew :yale-cffi *features*))

;;; The host compiler's style warnings and notes about generated code are
;;; noise in batch runs and the interactive system.
#+sbcl
(declaim (sb-ext:muffle-conditions style-warning sb-ext:compiler-note))

;;; The statistical profiler, for the interactive system's :profile: a
;;; saved executable cannot find SBCL's contrib modules to require them
;;; later.
#+sbcl
(require :sb-sprof)
