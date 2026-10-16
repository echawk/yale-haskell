;;; cl-support.lisp -- compile-time support for building mumble
;;;
;;; author :  Sandra Loosemore
;;; date   :  10 Oct 1991
;;;
;;; This file must be loaded before compiling the cl-definitions file.
;;; However, it is not needed when loading the compiled file.

(in-package "MUMBLE-IMPLEMENTATION")


;;; Modern hosts implement only ANSI CL, so provide the CLtL1 setf-method names
;;; that the rest of the support code uses.

#+(or sbcl ecl abcl)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defmacro define-setf-method (access-fn lambda-list &body body)
    `(define-setf-expander ,access-fn ,lambda-list ,@body))
  (defun get-setf-method (form &optional env)
    (get-setf-expansion form env)))


;;; SBCL signals an error when a DEFCONSTANT is re-evaluated with a value
;;; that is EQUAL but not EQL (e.g. strings), which happens routinely
;;; when a file is compiled and then loaded.  Reuse the existing value.

(defmacro define-mumble-constant (name value)
  #+(or sbcl ecl abcl)
  `(defconstant ,name (if (boundp ',name) (symbol-value ',name) ,value))
  #-(or sbcl ecl abcl)
  `(defconstant ,name ,value))


;;; Use this macro for defining an exported mumble function.

(defmacro define-mumble-function (name &rest stuff)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute) (export (list ',name) "MUMBLE"))
     (defun ,name ,@stuff)))


;;; This is similar, but also does some stuff to try to inline the
;;; function definition.  

(defmacro define-mumble-function-inline (name &rest stuff)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute) (export (list ',name) "MUMBLE"))
#+lcl
     (lcl:defsubst ,name ,@stuff)
#-lcl
     (progn
       ;; declaim, not proclaim: the declaration must be in effect when
       ;; the defun is compiled, or the inline expansion is not recorded
       ;; and every call stays a full call.
       (declaim (inline ,name))
       (defun ,name ,@stuff))
     ',name))


;;; Use this macro for defining an exported mumble macro.

(defmacro define-mumble-macro (name &rest stuff)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute) (export (list ',name) "MUMBLE"))
     (defmacro ,name ,@stuff)))


;;; Use this macro for importing a random symbol into the MUMBLE
;;; package.  This is useful for things that can share directly with
;;; built-in Common Lisp definitions.

(defmacro define-mumble-import (name)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute) (import (list ',name) "MUMBLE"))
     (eval-when (:compile-toplevel :load-toplevel :execute) (export (list ',name) "MUMBLE"))
     ',name))


;;; Use this macro for defining a function in the MUMBLE package that
;;; is a synonym for some Common Lisp function.  Try to do some stuff
;;; to make the function compile inline.

;;; Mumble also applies these to its own pretty-printer streams (xp in
;;; pprint.mumble), which the CL functions' declared types do not allow.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *synonyms-kept-as-calls*
    '(close write-char terpri fresh-line finish-output force-output
      clear-output input-stream-p output-stream-p)))

(defmacro define-mumble-synonym (name cl-name)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute) (export (list ',name) "MUMBLE"))
     ;; ABCL's built-in function may be an autoload stub, which is
     ;; resolved (by calling sys::resolve) before being copied.
     #+abcl (sys::resolve ',cl-name)
     (setf (symbol-function ',name) (symbol-function ',cl-name))
     ;; A call compiles as a call of the CL function itself, so that the
     ;; host's transforms and inline expansions apply: without this,
     ;; (vector tag a b) in generated code (make-tagged-data) was a full
     ;; call of VECTOR through its &rest list, which SBCL compiles as an
     ;; inline allocation when it sees CL:VECTOR.
#+lcl
     (lcl:def-compiler-macro ,name (&rest args)
       (cons ',cl-name args))
#-lcl
     ,@(unless (member cl-name *synonyms-kept-as-calls*)
	 `((define-compiler-macro ,name (&rest args)
	     (cons ',cl-name args))))
     ',name))



;;; Use this macro to define a type synonym.

(defmacro define-mumble-type (name &rest stuff)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute) (export (list ',name) "MUMBLE"))
     (deftype ,name ,@stuff)))


;;; This macro is used to signal a compile-time error in situations
;;; where an implementation-specific definition is missing.

(defmacro missing-mumble-definition (name)
  (error "No definition has been provided for ~s." name))





