;;;; mumble.asd -- ASDF system definition for mumble, the Scheme-like
;;;; dialect hosted on Common Lisp that Yale Haskell is written in.
;;;;
;;;; The CL layer (src/mumble/cl-*.lisp) defines the MUMBLE package, its
;;;; readtable (#t, #f) and the MUMBLE-USER package that mumble programs
;;;; are read in.  The .mumble files after it are mumble's library: the
;;;; compilation-unit system (compile), utilities, and the portable XP
;;;; pretty printer and format.  They are MUMBLE-FILE components, compiled
;;;; and loaded in MUMBLE-USER with mumble's readtable.
;;;;
;;;;   (asdf:load-system :mumble)
;;;;   (mumble-asd:with-mumble-syntax () (mumble:load "foo.mumble"))
;;;;
;;;; The Makefile build loads the same files through src/mumble/cl-init.lisp
;;;; and src/mumble/support.mumble instead.

(defpackage :mumble-asd
  (:use :cl :asdf)
  (:export #:mumble-file #:call-with-mumble-syntax #:with-mumble-syntax))

(in-package :mumble-asd)

(defun call-with-mumble-syntax (thunk)
  (let ((*package* (find-package "MUMBLE-USER"))
        (*readtable* (symbol-value
                      (find-symbol "*MUMBLE-READTABLE*"
                                   "MUMBLE-IMPLEMENTATION"))))
    (funcall thunk)))

(defmacro with-mumble-syntax (() &body body)
  `(call-with-mumble-syntax (lambda () ,@body)))

(defclass mumble-file (cl-source-file)
  ((type :initform "mumble")))

(defmethod perform :around ((o compile-op) (c mumble-file))
  (call-with-mumble-syntax (lambda () (call-next-method))))

(defmethod perform :around ((o load-op) (c mumble-file))
  (call-with-mumble-syntax (lambda () (call-next-method))))

(defsystem :mumble
  :description "Mumble: a Scheme-like dialect hosted on Common Lisp (from Yale Haskell)."
  :author "Sandra Loosemore and the Yale Haskell Group"
  :license "Free to copy and use with attribution to Yale University CS Dept."
  :pathname "src/mumble/"
  :serial t
  :components ((:file "cl-setup")
               (:file "cl-config")
               (:file "cl-support")
               (:file "cl-definitions")
               (:file "cl-types")
               (:file "cl-structs")
               (:file "mumble-user")
               (:mumble-file "units")
               (:mumble-file "compile")
               (:mumble-file "utils")
               (:mumble-file "pprint")
               (:mumble-file "format"))
  :perform (load-op :after (o c)
             (declare (ignore o c))
             (pushnew :mumble *features*)))
