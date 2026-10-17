;;;; cli.lisp -- the yale-haskell command line (doc/REVIVAL-PLAN.md, M10)
;;;;
;;;;   yale-haskell [OPTIONS] FILE [ARGS...]   compile FILE and run Main.main
;;;;   yale-haskell [OPTIONS] repl [FILE...]   the interactive system
;;;;   yale-haskell [OPTIONS]                  likewise, with no files
;;;;   yale-haskell [OPTIONS] -e EXPR [FILE...] evaluate EXPR and exit
;;;;
;;;; Plain Common Lisp over clingon; the compiler and the interactive
;;;; system (command-interface/repl.mumble) are mumble, in MUMBLE-USER.
;;;; An image holds one dialect; src/cli/startup.lisp picks the image.

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
   (clingon:make-option :flag :long-name "haskell2010" :key :haskell2010 :persistent t
                        :description "Haskell 2010 mode: the 2010 Prelude (no catch)")
   (clingon:make-option :flag :long-name "modern-prelude" :key :modern-prelude :persistent t
                        :description "GHC base's Prelude names too (Applicative, MonadFail, Semigroup, ...); implies --haskell2010")
   (clingon:make-option :flag :long-name "ghc2021" :key :ghc2021 :persistent t
                        :description "GHC2021, GHC's default language: its extensions in every module, and --modern-prelude")
   (clingon:make-option :flag :long-name "ghc2024" :key :ghc2024 :persistent t
                        :description "GHC2024: GHC2021 and DataKinds, GADTs, LambdaCase, ...; implies --modern-prelude")
   (clingon:make-option :list :long-name "extension" :short-name #\X :key :extension :persistent t
                        :description "turn on an extension in every module, as -XName does for GHC (repeatable; NoName turns one off)")
   (clingon:make-option :flag :long-name "no-optimize" :short-name #\O
                      :key :no-optimize :persistent t
                      :description "turn off the FLIC optimizer")
   (clingon:make-option :string :long-name "optimizers" :key :optimizers :persistent t
                        :description "FLIC optimizers, comma-separated: names (exactly these), +name, -name, all, none; of foldr,inline,constant,lisp")
   (clingon:make-option :flag :long-name "cpp" :key :cpp :persistent t
                        :description "run the C preprocessor on every source file (files with {-# LANGUAGE CPP #-} always are)")
   (clingon:make-option :list :long-name "define" :short-name #\D :key :define :persistent t
                        :description "define a CPP macro: NAME or NAME=VALUE (repeatable)")
   (clingon:make-option :list :long-name "include-dir" :short-name #\I :key :include-dir :persistent t
                        :description "a directory for CPP's #include (repeatable)")
   (clingon:make-option :string :long-name "emit" :key :emit :persistent t
                        :description "compile without running and write these stages, comma-separated: scope,depend,cfn,flic,optimize,strictness,grin,codegen,lisp,asm")
   (clingon:make-option :string :long-name "output" :short-name #\o :key :output :persistent t
                        :description "file for --emit's output (default: standard output)")
   (clingon:make-option :string :long-name "grin-optimizations" :short-name #\g
                        :key :grin-optimizations :persistent t
                        :description "GRIN optimizations, comma-separated: names (exactly these), +name, -name, all, none; of fold,speculate,inline-eval,self-local,rep-types,ftype")
   (clingon:make-option :list :long-name "search-dir" :short-name #\i
                        :key :search-dir :persistent t
                        :description "a directory to look for imported modules in (repeatable; also $YALE_HASKELL_PATH)")
   (clingon:make-option :list :long-name "package-db" :key :package-db :persistent t
                        :description "a directory of installed packages (repeatable; also $YALE_HASKELL_PACKAGE_DB)")
   (clingon:make-option :flag :long-name "numeric-version" :key :numeric-version :persistent t
                        :description "print the version number and exit")
   (clingon:make-option :list :long-name "foreign-library" :short-name #\l
                        :key :foreign-library :persistent t
                        :description "load a C shared library for foreign imports (repeatable)")
   (clingon:make-option :list :long-name "eval" :short-name #\e
                        :key :eval :persistent t
                        :description "evaluate an expression (repeatable) and exit")))

;;; Options that take a value, for splitting the program's own arguments
;;; off the command line.
(defparameter *value-options*
  '("-b" "--backend" "-p" "--printers" "-e" "--eval" "-g" "--grin-optimizations"
    "-l" "--foreign-library" "-D" "--define" "-I" "--include-dir" "--optimizers" "--emit" "-o" "--output"
    "-i" "--search-dir" "--package-db" "-X" "--extension"))

(defparameter *sub-commands* '("repl" "run" "compile" "help"))

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
    (when (clingon:getopt* cmd :haskell2010)
      (mumble-set "*HASKELL2010?*" t))
    (when (or (clingon:getopt* cmd :modern-prelude)
              (clingon:getopt* cmd :ghc2021)
              (clingon:getopt* cmd :ghc2024))
      (mumble-set "*MODERN-PRELUDE?*" t))
    ;; the language standard's extensions, then -X's, in every module
    ;; that is not an installed package's (src/compiler/parser/lexer.mumble)
    (mumble-set "*DEFAULT-LANGUAGE-EXTENSIONS*"
                (append (cond ((clingon:getopt* cmd :ghc2024) (list "GHC2024"))
                              ((clingon:getopt* cmd :ghc2021) (list "GHC2021"))
                              (t '()))
                        (clingon:getopt* cmd :extension)))
    (when (clingon:getopt* cmd :cpp)
      (mumble-set "*CPP?*" t))
    (when (clingon:getopt* cmd :define)
      (mumble-set "*CPP-DEFINES*" (clingon:getopt* cmd :define)))
    (when (clingon:getopt* cmd :include-dir)
      (mumble-set "*CPP-INCLUDE-DIRS*"
                  (mapcar (lambda (d) (namestring (merge-pathnames
                                                   (uiop:ensure-directory-pathname d)
                                                   (uiop:getcwd))))
                          (clingon:getopt* cmd :include-dir))))
    (when (clingon:getopt* cmd :numeric-version)
      (format t "~a~%" (mumble-value "*HASKELL-COMPILER-VERSION*"))
      (uiop:quit 0))
    (flet ((dirs (key)
             (mapcar (lambda (d) (namestring (merge-pathnames
                                              (uiop:ensure-directory-pathname d)
                                              (uiop:getcwd))))
                     (clingon:getopt* cmd key))))
      (when (clingon:getopt* cmd :search-dir)
        (mumble-set "*MODULE-SEARCH-PATH*" (dirs :search-dir)))
      (when (clingon:getopt* cmd :package-db)
        (mumble-set "*PACKAGE-DBS*" (dirs :package-db))))
    (when (clingon:getopt* cmd :no-optimize)
      (mumble-set "*OPTIMIZERS*" '()))
    (let ((opts (clingon:getopt* cmd :optimizers)))
      (when opts
        (mumble-set "*OPTIMIZERS*"
                    (mumble-call "OPTION-LIST"
                                 (uiop:split-string opts :separator ",")
                                 (mumble-value "*OPTIMIZERS*")
                                 (mumble-value "*ALL-OPTIMIZERS*")
                                 "optimizer"))))
    (dolist (lib (clingon:getopt* cmd :foreign-library))
      (handler-case (mumble-call "PRIM.LOAD-LIBRARY" lib)
        (error (c)
          (format *error-output* "yale-haskell: ~a~%" c)
          (uiop:quit 1))))
    (let ((grin (clingon:getopt* cmd :grin-optimizations)))
      (when grin
        (mumble-set "*GRIN-OPTIMIZATIONS*"
                    (mumble-call "GRIN-OPTIMIZATION-LIST"
                                 (uiop:split-string grin :separator ",")
                                 (mumble-value "*GRIN-OPTIMIZATIONS*")))))))

(defun emit-stages (cmd)
  (let ((emit (clingon:getopt* cmd :emit)))
    (and emit (uiop:split-string emit :separator ","))))

(defun top-handler (cmd)
  (apply-options cmd)
  (let ((args (clingon:command-arguments cmd))
        (exprs (clingon:getopt* cmd :eval)))
    (cond (exprs (mumble-call "REPL-BATCH-EVAL" args exprs))
          ((and args (emit-stages cmd)) (compile-handler cmd))
          (args (mumble-call "BATCH-RUN" (first args) (rest args)))
          (t (mumble-call "REPL" '())))))

;;; yale-haskell compile FILE [--emit STAGES] [-o OUT]: compile without
;;; running (src/compiler/command-interface/batch.mumble).  Without
;;; --emit it only reports errors.
(defun compile-handler (cmd)
  (apply-options cmd)
  (let ((args (clingon:command-arguments cmd)))
    (unless (= (length args) 1)
      (format *error-output* "yale-haskell compile: one FILE expected~%")
      (uiop:quit 64))
    (mumble-call "EMIT-RUN" (first args) (emit-stages cmd)
                 (clingon:getopt* cmd :output))))

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
   :usage "[options] [FILE [ARGS...] | repl [FILE...] | compile FILE --emit STAGES [-o OUT] | -e EXPR [FILE...]]"
   :options (options)
   :handler #'top-handler
   :sub-commands
   (list (clingon:make-command :name "repl" :usage "[FILE...]"
                               :description "the interactive system (GHCi-like)"
                               :handler #'repl-handler)
         (clingon:make-command :name "compile" :usage "FILE [--emit STAGES] [-o OUT]"
                               :description "compile FILE without running it; --emit writes compiler stages"
                               :handler #'compile-handler)
         (clingon:make-command :name "run" :usage "FILE [ARGS...]"
                               :description "compile FILE and run Main.main"
                               :handler #'run-handler))))

(defun main (&optional (argv (uiop:command-line-arguments)))
  ;; The saved executable sets up its environment and picks the image
  ;; (src/cli/startup.lisp); a launcher script does that on other Lisps.
  (when (fboundp 'startup)
    (setf argv (funcall 'startup argv)))
  ;; The compiler interns symbols in the current package and reads with
  ;; mumble's readtable.
  (setf *package* (find-package "MUMBLE-USER"))
  (setf *readtable* (symbol-value (find-symbol "*MUMBLE-READTABLE*"
                                               "MUMBLE-IMPLEMENTATION")))
  (let ((args (split-program-args argv)))
    #+sbcl (run-with-program-stack (lambda () (clingon:run (command) args)))
    #-sbcl (clingon:run (command) args))
  ;; the executable's entry point (uiop:restore-image): true is status 0
  t)

;;; The compiler and the program run in a thread of their own, whose
;;; control stack is $YALE_HASKELL_STACK_MB (default 512) MB: lazy
;;; programs recurse deeply.  The main thread's stack is small (the
;;; Makefile's IMAGE_STACK_MB), because SBCL on macOS makes the main
;;; thread's whole stack resident at startup: with 512 MB there, every
;;; run, hello world included, took 620 MB.  A thread's stack is
;;; resident only as far as it is used.  An interrupt (C-c), which SBCL
;;; delivers to the main thread, is passed on to the worker: the
;;; interactive system handles it; elsewhere it ends the program (130).

#+sbcl
(defun program-stack-bytes ()
  (let* ((env (uiop:getenv "YALE_HASKELL_STACK_MB"))
         (mb (or (and env (ignore-errors (parse-integer env))) 512)))
    (* (max mb 2) 1048576)))

#+sbcl
(defun interruptible-p ()
  (let ((sym (find-symbol "*REPL-INTERRUPTIBLE?*" "MUMBLE-USER")))
    (and sym (boundp sym) (symbol-value sym))))

;;; uiop:quit in the worker (clingon's --help and --version, our own
;;; option errors) flushes the output and exits at once: SBCL's orderly
;;; exit from a thread other than the main one unwinds it and has the
;;; main thread exit, and with a stack of 64 MB or more that faulted.
#+sbcl
(defun quit-from-worker (quit code &rest args)
  (if (eq sb-thread:*current-thread* (sb-thread:main-thread))
      (apply quit code args)
      (progn
        (ignore-errors (finish-output *standard-output*))
        (ignore-errors (finish-output *error-output*))
        (sb-ext:exit :code code :abort t))))

#+sbcl
(defun run-with-program-stack (fn)
  (setf (sb-alien:extern-alien "thread_control_stack_size" sb-alien:unsigned)
        (program-stack-bytes))
  (unless (sb-int:encapsulated-p 'uiop:quit 'quit-from-worker)
    (sb-int:encapsulate 'uiop:quit 'quit-from-worker #'quit-from-worker))
  (let* ((package *package*)
         (readtable *readtable*)
         (main sb-thread:*current-thread*)
         (worker (sb-thread:make-thread
                  (lambda ()
                    (let ((*package* package) (*readtable* readtable))
                      (funcall fn)))
                  :name "yale-haskell")))
    ;; after passing an interrupt on, back to waiting (SBCL's SIGINT
    ;; handler offers no restart to return to)
    (loop
      (block interrupted
        (handler-bind ((sb-sys:interactive-interrupt
                         (lambda (c)
                           (declare (ignore c))
                           (sb-thread:interrupt-thread
                            worker
                            (lambda ()
                              (if (interruptible-p)
                                  ;; the interactive system's command
                                  ;; is abandoned
                                  (signal (make-condition 'sb-sys:interactive-interrupt))
                                  ;; otherwise the program ends, from the
                                  ;; main thread: unwinding the worker from
                                  ;; inside its interrupt (clingon's handler
                                  ;; exits) faulted
                                  (progn
                                    (ignore-errors (finish-output))
                                    (sb-thread:interrupt-thread
                                     main (lambda () (sb-ext:exit :code 130 :abort t)))))))
                           (return-from interrupted))))
          (return (sb-thread:join-thread worker :default nil)))))))
