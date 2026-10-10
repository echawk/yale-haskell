;;;; startup.lisp -- what the saved executable does before the command
;;;; line is parsed (SBCL; src/cli/cli.lisp calls startup).  It replaces
;;;; the shell script bin/yale-haskell used to be:
;;;;
;;;; 1. The environment the compiler reads ($Y2, $PRELUDE, $PRELUDEBIN,
;;;;    $HASKELL_LIBRARY, $LIBRARYBIN, $HASKELL), from where the
;;;;    executable is: <root>/build/<lisp>/<dialect>/yale-haskell.
;;;; 2. The image: one holds one dialect, so a leading --haskell98 or
;;;;    --haskell1.2, or $YALE_HASKELL_DIALECT, naming another dialect
;;;;    (or $YALE_HASKELL_LISP another Lisp) runs that build's executable
;;;;    in place of this process.
;;;; 3. Line editing: the interactive system on a terminal runs under
;;;;    rlwrap, when it is installed, with history in
;;;;    ~/.yale_haskell_history; YALE_HASKELL_RLWRAP=no turns it off.

(in-package :yale-haskell-cli)

;;; The dialect of this image and the source tree it was built from,
;;; fixed when the image is built.
(defvar *image-dialect*
  (or (uiop:getenv "YALE_HASKELL_DIALECT") "haskell98"))
(defvar *build-root* (namestring (uiop:getcwd)))

(defun startup (argv)
  "Sets up the environment and returns the arguments left for the command
line, or replaces this process with the executable that should run them."
  (let* ((root (or (root-from-executable) *build-root*))
         (flag (dialect-flag (first argv)))
         (argv (if flag (rest argv) argv))
         (dialect (or flag (nonempty (uiop:getenv "YALE_HASKELL_DIALECT"))
                      *image-dialect*))
         (lisp (or (nonempty (uiop:getenv "YALE_HASKELL_LISP")) "sbcl")))
    (unless (and (string= dialect *image-dialect*) (string= lisp "sbcl"))
      (let ((exe (format nil "~abuild/~a/~a/yale-haskell" root lisp dialect)))
        (unless (probe-file exe)
          (format *error-output* "yale-haskell: ~a not found; run make~@[ LISP=~a~] first.~%"
                  exe (and (string/= lisp "sbcl") lisp))
          (uiop:quit 1))
        ;; the other image reads the dialect from here, not the flag
        (setenv "YALE_HASKELL_DIALECT" dialect)
        (exec exe argv)))
    (set-dialect-environment root dialect)
    (when (and (interactive-args-p argv)
               (isatty 0) (isatty 1)
               (string/= (or (uiop:getenv "YALE_HASKELL_RLWRAP") "") "no"))
      (let ((rlwrap (find-on-path "rlwrap")))
        (when rlwrap
          ;; and not again, in the process rlwrap starts
          (setenv "YALE_HASKELL_RLWRAP" "no")
          (exec rlwrap
                (list* "-H" (namestring (merge-pathnames ".yale_haskell_history"
                                                         (user-homedir-pathname)))
                       "-s" "1000" "-b" "(){}[],;\"'"
                       (executable-path) argv)))))
    argv))

(defun nonempty (s) (and s (plusp (length s)) s))

(defun dialect-flag (arg)
  (cond ((equal arg "--haskell98") "haskell98")
        ((equal arg "--haskell1.2") "haskell-1.2")))

(defun executable-path ()
  (namestring (truename sb-ext:*runtime-pathname*)))

;;; <root>/build/<lisp>/<dialect>/yale-haskell, if the root has this
;;; dialect's library (the tree may have moved since the build).

(defun root-from-executable ()
  (ignore-errors
   (let* ((dir (pathname-directory (truename sb-ext:*runtime-pathname*)))
          (root (make-pathname :directory (butlast dir 3) :name nil :type nil
                               :defaults (truename sb-ext:*runtime-pathname*))))
     (and (string= (nth (- (length dir) 3) dir) "build")
          (probe-file (merge-pathnames
                       (format nil "lib/~a/prelude/" *image-dialect*) root))
          (namestring root)))))

;;; As the Makefile's dialect_env.
(defun set-dialect-environment (root dialect)
  (let* ((root (string-right-trim "/" root))
         (build (format nil "~a/build/sbcl/~a" root dialect)))
    (setenv "HASKELL" root)
    (setenv "Y2" root)
    (setenv "PRELUDE" (format nil "~a/lib/~a/prelude" root dialect))
    (setenv "PRELUDEBIN" (format nil "~a/prelude" build))
    (setenv "HASKELL_LIBRARY" (format nil "~a/lib/~a" root dialect))
    (setenv "LIBRARYBIN" (format nil "~a/lib" build))))

;;; The interactive system: no program file, or the repl command (not
;;; -e, --help, --version or run).
(defun interactive-args-p (argv)
  (loop with skip = nil
        for a in argv
        do (cond (skip (setf skip nil))
                 ((string= a "repl") (return t))
                 ((member a '("-e" "--eval" "--help" "--version" "run" "compile")
                          :test #'string=)
                  (return nil))
                 ((member a *value-options* :test #'string=) (setf skip t))
                 ((and (plusp (length a)) (char= (char a 0) #\-)))
                 (t (return nil)))
        finally (return t)))

(defun find-on-path (name)
  (dolist (dir (uiop:split-string (or (uiop:getenv "PATH") "") :separator ":"))
    (let ((file (format nil "~a/~a" (if (string= dir "") "." dir) name)))
      (when (and (probe-file file) (not (uiop:directory-pathname-p (probe-file file))))
        (return file)))))

(defun setenv (name value)
  (cffi:foreign-funcall "setenv" :string name :string value :int 1 :int))

(defun isatty (fd)
  (= 1 (cffi:foreign-funcall "isatty" :int fd :int)))

;;; execv: replaces this process (it returns only on failure).

(defun exec (program args)
  (finish-output *standard-output*)
  (finish-output *error-output*)
  (let* ((all (cons program args))
         (argv (cffi:foreign-alloc :pointer :count (1+ (length all)))))
    (loop for a in all
          for i from 0
          do (setf (cffi:mem-aref argv :pointer i) (cffi:foreign-string-alloc a)))
    (setf (cffi:mem-aref argv :pointer (length all)) (cffi:null-pointer))
    (cffi:foreign-funcall "execv" :string program :pointer argv :int)
    (format *error-output* "yale-haskell: cannot run ~a~%" program)
    (uiop:quit 1)))
