;;;; api.lisp -- a Common Lisp interface to Yale Haskell, for images that
;;;; load it with ASDF (yale-haskell.asd).  The compiler lives in the
;;;; MUMBLE-USER package and expects *package* to be MUMBLE-USER and mumble's
;;;; readtable while it runs; these functions arrange both.

(defpackage :yale-haskell
  (:use :cl)
  (:shadow #:compile-file)
  (:export #:compile-file #:load-file #:run-file #:repl #:dialect))

(in-package :yale-haskell)

(defun call-mumble (name &rest args)
  (let ((*package* (find-package "MUMBLE-USER"))
        (*readtable* (symbol-value
                      (uiop:find-symbol* "*MUMBLE-READTABLE*"
                                         "MUMBLE-IMPLEMENTATION"))))
    (apply (uiop:find-symbol* name "MUMBLE-USER") args)))

(defun compile-file (file)
  "Compile a Haskell module (or .hu unit) to binaries without loading it."
  (call-mumble "COMPILE/COMPILE" (namestring file)))

(defun load-file (file)
  "Compile a Haskell module if needed and load it."
  (call-mumble "COMPILE/LOAD" (namestring file)))

(defun run-file (file)
  "Compile and load a Haskell program, then run Main.main.  Returns true
if the program was compiled and run."
  (call-mumble "RUN-PROGRAM" (namestring file)))

(defun repl ()
  "Start the interactive Yale Haskell command interface."
  (call-mumble "HEVAL"))

(defun dialect ()
  "The Haskell dialect loaded in this image, e.g. \"haskell98\"."
  (uiop:symbol-call :yale-haskell-asd '#:loaded-dialect))
