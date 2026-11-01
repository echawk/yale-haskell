;;;; runtime.lisp -- the first component of yale-haskell/runtime
;;;; (yale-haskell.asd).

(in-package :cl-user)

;;; CFFI works on SBCL, so the base runtime uses it (src/base/base-runtime.lisp
;;; has portable fallbacks for Lisps where it does not: tools/build/runtime.lisp).
(eval-when (:compile-toplevel :load-toplevel :execute)
  (pushnew :yale-cffi *features*))
