;;;; cli.lisp -- the yale-haskell command line (doc/REVIVAL-PLAN.md, M10)
;;;;
;;;;   yale-haskell [OPTIONS] FILE [ARGS...]   compile FILE and run Main.main
;;;;   yale-haskell [OPTIONS] repl [FILE...]   the interactive system
;;;;   yale-haskell [OPTIONS]                  likewise, with no files
;;;;   yale-haskell [OPTIONS] -e EXPR [FILE...] evaluate EXPR and exit
;;;;
;;;; Plain Common Lisp over clingon; the compiler and the interactive
;;;; system (command-interface/repl.mumble) are mumble, in MUMBLE-USER.
;;;; The dialect is chosen by bin/yale-haskell, which picks the image.

(defpackage :yale-haskell-cli
  (:use :cl)
  (:export #:main))

(in-package :yale-haskell-cli)

(defun mumble-fn (name)
  (symbol-function (find-symbol name "MUMBLE-USER")))

(defun mumble-call (name &rest args)
  (apply (mumble-fn name) args))

(defun mumble-set (name value)
  (setf (symbol-value (find-symbol name "MUMBLE-USER")) value))

(defun mumble-value (name)
  (symbol-value (find-symbol name "MUMBLE-USER")))

(defun options ()
  (list
   (clingon:make-option :choice :long-name "backend" :short-name #\b
                        :key :backend :items '("grin" "flic") :persistent t
                        :description "code generator (default grin)")
   (clingon:make-option :string :long-name "printers" :short-name #\p
                        :key :printers :persistent t
                        :description "compiler passes to print, comma-separated (e.g. grin,codegen)")
   (clingon:make-option :flag :long-name "no-optimize" :short-name #\O
                      :key :no-optimize :persistent t
                      :description "turn off the FLIC optimizer")
   (clingon:make-option :list :long-name "eval" :short-name #\e
                        :key :eval :persistent t
                        :description "evaluate an expression (repeatable) and exit")))

;;; Options that take a value, for splitting the program's own arguments
;;; off the command line.
(defparameter *value-options* '("-b" "--backend" "-p" "--printers" "-e" "--eval"))

(defparameter *sub-commands* '("repl" "run" "help"))

;;; yale-haskell [opts] FILE ARGS...: everything after FILE belongs to the
;;; program, so it is passed after "--" (clingon would parse "-x" as ours).
(defun split-program-args (argv)
  (let ((arg (first argv)))
    (cond ((null argv) '())
          ((member arg *value-options* :test #'string=)
           (if (rest argv)
               (list* arg (second argv) (split-program-args (cddr argv)))
               argv))
          ((string= arg "--") argv)
          ((and (plusp (length arg)) (char= (char arg 0) #\-))
           (cons arg (split-program-args (rest argv))))
          ((member arg *sub-commands* :test #'string=) argv)
          (t (list* arg "--" (rest argv))))))

(defun apply-options (cmd)
  ;; batch runs print only the program's output; :set printers changes it
  (mumble-set "*PRINTERS*" '())
  (let ((backend (clingon:getopt* cmd :backend))
        (printers (clingon:getopt* cmd :printers)))
    (when backend
      (mumble-set "*BACKEND*" (intern (string-upcase backend) "MUMBLE-USER")))
    (when printers
      (mumble-set "*PRINTERS*"
                  (mumble-call "SET-PRINTERS"
                               (uiop:split-string printers :separator ",")
                               (intern "=" "MUMBLE-USER"))))
    (when (clingon:getopt* cmd :no-optimize)
      (mumble-set "*OPTIMIZERS*" '()))))

(defun top-handler (cmd)
  (apply-options cmd)
  (let ((args (clingon:command-arguments cmd))
        (exprs (clingon:getopt* cmd :eval)))
    (cond (exprs (mumble-call "REPL-BATCH-EVAL" args exprs))
          (args (mumble-call "BATCH-RUN" (first args) (rest args)))
          (t (mumble-call "REPL" '())))))

(defun run-handler (cmd)
  (apply-options cmd)
  (let ((args (clingon:command-arguments cmd)))
    (if args
        (mumble-call "BATCH-RUN" (first args) (rest args))
        (progn (format *error-output* "yale-haskell run: no file~%")
               (uiop:quit 64)))))

(defun repl-handler (cmd)
  (apply-options cmd)
  (let ((exprs (clingon:getopt* cmd :eval)))
    (if exprs
        (mumble-call "REPL-BATCH-EVAL" (clingon:command-arguments cmd) exprs)
        (mumble-call "REPL" (clingon:command-arguments cmd)))))

(defun command ()
  (clingon:make-command
   :name "yale-haskell"
   :description "the Yale Haskell compiler and interactive system"
   :version (mumble-value "*HASKELL-COMPILER-VERSION*")
   :usage "[options] [FILE [ARGS...] | repl [FILE...] | -e EXPR [FILE...]]"
   :options (options)
   :handler #'top-handler
   :sub-commands
   (list (clingon:make-command :name "repl" :usage "[FILE...]"
                               :description "the interactive system (GHCi-like)"
                               :handler #'repl-handler)
         (clingon:make-command :name "run" :usage "FILE [ARGS...]"
                               :description "compile FILE and run Main.main"
                               :handler #'run-handler))))

(defun main ()
  ;; The compiler interns symbols in the current package and reads with
  ;; mumble's readtable.
  (setf *package* (find-package "MUMBLE-USER"))
  (setf *readtable* (symbol-value (find-symbol "*MUMBLE-READTABLE*"
                                               "MUMBLE-IMPLEMENTATION")))
  (clingon:run (command) (split-program-args (uiop:command-line-arguments))))
