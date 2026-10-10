;;;; yale-haskell.asd -- ASDF system definition for Yale Haskell.
;;;;
;;;; The compiler is written in "mumble", a Scheme-like dialect hosted on
;;;; Common Lisp, and is compiled by its own compilation-unit system
;;;; (src/mumble/compile.mumble), so the .mumble files are not ASDF
;;;; components.  Loading this system does what the Makefile build does
;;;; (tools/build/compiler.lisp, then prelude.lisp), sharing its compiler
;;;; and prelude FASLs under build/<lisp>/:
;;;;
;;;;   1. load mumble (mumble.asd; its FASLs go in ASDF's output cache);
;;;;   2. set up the environment the compiler reads ($Y2, $PRELUDE, ...);
;;;;   3. compile (if out of date) and load the compiler;
;;;;   4. compile the dialect's prelude if it has no binaries, then load it.
;;;;
;;;; Usage:
;;;;
;;;;   (asdf:load-system :yale-haskell)              ; Haskell 98
;;;;   (asdf:load-system :yale-haskell/haskell-1.2)  ; or Haskell 1.2
;;;;   (yale-haskell:run-file "examples/demo/queens.hs")
;;;;   (asdf:test-system :yale-haskell)              ; make test
;;;;
;;;; An image holds one dialect (it is fixed when the compiler loads).
;;;; :yale-haskell takes it from $YALE_HASKELL_DIALECT if set, as
;;;; bin/yale-haskell does, and otherwise uses haskell98.
;;;;
;;;; Mumble reads its sources with a private readtable and leaves
;;;; COMMON-LISP locked, so other systems can be loaded into the same
;;;; image before or after this one.  See doc/ASDF-PORTING.md.

(defpackage :yale-haskell-asd
  (:use :cl :asdf)
  (:export #:bootstrap #:loaded-dialect))

(in-package :yale-haskell-asd)

(defvar *loaded-dialect* nil
  "The dialect whose compiler and prelude are loaded in this image.")

(defun loaded-dialect () *loaded-dialect*)

(defun default-dialect ()
  (let ((d (uiop:getenv "YALE_HASKELL_DIALECT")))
    (if (and d (plusp (length d))) d "haskell98")))

(defun lisp-name ()
  ;; build/<lisp>/ as in the Makefile and src/mumble/cl-init.lisp
  #+sbcl "sbcl" #-sbcl (string-downcase (lisp-implementation-type)))

(defun set-dialect-environment (root dialect)
  "The variables the Makefile's dialect_env and bin/yale-haskell set."
  (let ((build (format nil "~abuild/~a/~a/" root (lisp-name) dialect)))
    (flet ((env (name value) (setf (uiop:getenv name) value)))
      (env "Y2" (string-right-trim "/" root))
      (env "HASKELL" (string-right-trim "/" root))
      (env "PRELUDE" (format nil "~alib/~a/prelude" root dialect))
      (env "PRELUDEBIN" (format nil "~aprelude" build))
      (env "HASKELL_LIBRARY" (format nil "~alib/~a" root dialect))
      (env "LIBRARYBIN" (format nil "~alib" build)))
    build))

(defun mumble-call (name &rest args)
  ;; The compiler interns symbols in the current package, so it is only
  ;; called with *package* bound to MUMBLE-USER.
  (let ((*package* (find-package "MUMBLE-USER")))
    (apply (uiop:find-symbol* name "MUMBLE-USER") args)))

(defun mumble-set (name value)
  (setf (symbol-value (uiop:find-symbol* name "MUMBLE-USER")) value))

(defun mumble-value (name)
  (symbol-value (uiop:find-symbol* name "MUMBLE-USER")))

(defun compile-prelude ()
  ;; The settings of tools/build/prelude.lisp.
  (mumble-set "*PRINTERS*" '())
  (mumble-set "*OPTIMIZERS*" (mumble-value "*ALL-OPTIMIZERS*"))
  (mumble-set "*CODE-CHUNK-SIZE*" 300)
  (mumble-set "*COMPILE-INTERFACE*" nil)
  (mumble-call "COMPILE/COMPILE" (mumble-value "*PRELUDE-UNIT-FILENAME*")))

(defun bootstrap (root dialect)
  (when *loaded-dialect*
    (unless (equal dialect *loaded-dialect*)
      (error "Yale Haskell ~a is already loaded; an image holds one dialect."
             *loaded-dialect*))
    (return-from bootstrap dialect))
  (let* ((root (namestring (truename root)))
         (build (set-dialect-environment root dialect))
         (*default-pathname-defaults* (pathname root)))
    ;; Compile (if out of date) and load the compiler, as
    ;; src/mumble/cl-init.lisp does after loading mumble.
    ;; (mumble-asd is defined by mumble.asd, loaded after this file is read.)
    (uiop:symbol-call :mumble-asd '#:call-with-mumble-syntax
      (lambda ()
        (funcall (uiop:find-symbol* "LOAD" "MUMBLE") "$Y2/src/compiler/system")
        (mumble-call "COMPILE-HASKELL")))
    ;; The prelude unit is :stable, so (like the Makefile) compile it
    ;; only when it has no binaries; delete build/<lisp>/<dialect>/prelude
    ;; after changing lib/<dialect>/prelude.
    (unless (directory (merge-pathnames "prelude/*.*" build))
      (compile-prelude))
    ;; As tools/build/image.lisp: user programs are compiled with the
    ;; optimizer on.
    (mumble-set "*PRINTERS*" '())
    (mumble-set "*OPTIMIZERS*" (mumble-value "*ALL-OPTIMIZERS*"))
    (mumble-call "COMPILE/LOAD" (mumble-value "*PRELUDE-UNIT-FILENAME*"))
    (setf *loaded-dialect* dialect)))

(defun run-test-suite (root)
  (uiop:run-program '("make" "test") :directory root
                    :output t :error-output t))

(defsystem :yale-haskell
  :description "Yale Haskell: a Haskell 1.2 / Haskell 98 compiler written in mumble, a Scheme-like dialect hosted on Common Lisp."
  :author "Yale Haskell Group (revived for SBCL)"
  :license "Free to copy and use with attribution to Yale University CS Dept."
  :version "2.0.6"
  :depends-on (:mumble)
  :components ((:file "tools/asdf/api"))
  :perform (load-op :after (o c)
             (declare (ignore o))
             (bootstrap (system-source-directory c) (default-dialect)))
  :in-order-to ((test-op (test-op :yale-haskell/test))))

(defsystem :yale-haskell/haskell-1.2
  :description "Yale Haskell with the Haskell 1.2 prelude."
  :depends-on (:mumble)
  :components ((:file "tools/asdf/api"))
  :perform (load-op :after (o c)
             (declare (ignore o))
             (bootstrap (system-source-directory c) "haskell-1.2")))

;;; The yale-haskell executable for the dialect loaded (as :yale-haskell
;;; picks it), saved by program-op on SBCL:
;;;
;;;   (asdf:make :yale-haskell/executable)
;;;
;;; It is written to $YALE_HASKELL_EXECUTABLE, or else
;;; build/<lisp>/<dialect>/yale-haskell.  The Makefile builds it with
;;; tools/build/image.lisp.  The heap and stack sizes are those of the
;;; Lisp that saves it (save-runtime-options).

(defclass executable-system (system) ())

(defmethod output-files ((o program-op) (s executable-system))
  (let ((out (uiop:getenv "YALE_HASKELL_EXECUTABLE")))
    (values (list (if (and out (plusp (length out)))
                      (uiop:ensure-absolute-pathname
                       (uiop:parse-native-namestring out) (uiop:getcwd))
                      (merge-pathnames
                       (format nil "build/~a/~a/yale-haskell"
                               (lisp-name) (default-dialect))
                       (system-source-directory s))))
            t)))

(defsystem :yale-haskell/executable
  :description "The yale-haskell command line: the compiler, the prelude, the runtime and the CLI, saved as an executable."
  :class executable-system
  :depends-on (:yale-haskell :clingon :cffi)
  :serial t
  :components ((:file "tools/build/executable")
               (:file "src/ffi/ffi-runtime")
               (:file "src/ffi/errno-darwin" :if-feature :darwin)
               (:file "src/base/base-runtime")
               (:file "src/cli/cli")
               (:file "src/cli/startup"))
  :build-operation "program-op"
  :entry-point "yale-haskell-cli:main")

(defsystem :yale-haskell/test
  :description "Run the Yale Haskell test suite (make test)."
  :perform (test-op (o c)
             (declare (ignore o))
             (run-test-suite (system-source-directory c))))
