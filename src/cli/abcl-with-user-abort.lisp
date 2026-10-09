;;; abcl-with-user-abort.lisp -- the with-user-abort library (a clingon
;;; dependency) for ABCL, which it does not support.  Loaded in place of
;;; it (tools/build/runtime.lisp).  ^C is not caught: user-abort is never
;;; signalled.

(defpackage with-user-abort
  (:use :cl)
  (:export :user-abort :with-user-abort))

(in-package :with-user-abort)

(define-condition user-abort (condition) ())

(defun user-abort (&optional condition)
  (declare (ignore condition))
  (signal 'user-abort))

(defmacro with-user-abort (&body body)
  `(progn ,@body))
