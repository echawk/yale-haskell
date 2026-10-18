;;;; z3.lisp -- driving Z3 as a long-lived subprocess.
;;;;
;;;; One process per solving session, talking SMT-LIB2 over pipes (z3
;;;; -smt2 -in), as liquid-fixpoint's Smt/Interface.hs does.  Commands are
;;;; written without waiting; only (check-sat) is read back.  Z3 prints
;;;; errors as (error "...") lines and carries on, so errors are collected
;;;; while waiting for the next sat/unsat/unknown and reported then.
;;;;
;;;; The executable is *Z3-PATH* (default: $YALE_LIQUID_Z3, else "z3" on
;;;; PATH, else /opt/homebrew/bin/z3 or /usr/local/bin/z3, else /usr/bin/z3).
;;;; If none exists, starting a session signals SMT-SOLVER-MISSING.
;;;;
;;;; A session also keeps a stack of the SMT names declared in each
;;;; (push) scope, so that callers can declare symbols lazily and have
;;;; them re-declared after a (pop) removes them.

(in-package :yale-liquid)

(defvar *z3-path* nil
  "Path of the Z3 executable, or NIL to search for it.")

(define-condition smt-solver-missing (error)
  ((path :initarg :path :reader smt-solver-missing-path))
  (:report (lambda (c s)
             (format s "Z3 was not found (~a).  Install Z3 or set ~
                        LIQUID:*Z3-PATH* / $YALE_LIQUID_Z3."
                     (smt-solver-missing-path c)))))

(define-condition smt-error (error)
  ((messages :initarg :messages :reader smt-error-messages))
  (:report (lambda (c s) (format s "SMT solver error: ~{~a~^; ~}" (smt-error-messages c)))))

(defun find-executable (name candidates)
  (or (find-if #'probe-file candidates)
      (let ((path (uiop:getenv "PATH")))
        (when path
          (dolist (dir (uiop:split-string path :separator ":"))
            (let ((p (concatenate 'string (string-right-trim "/" dir) "/" name)))
              (when (and (plusp (length dir)) (probe-file p))
                (return p))))))))

(defun z3-executable ()
  (or *z3-path*
      (let ((env (uiop:getenv "YALE_LIQUID_Z3")))
        (and env (plusp (length env)) env))
      (find-executable "z3" '("/opt/homebrew/bin/z3" "/usr/local/bin/z3" "/usr/bin/z3"))))

(defun z3-available-p ()
  (let ((p (z3-executable)))
    (and p (probe-file p) t)))

(defstruct z3
  process input output
  (scopes (list (make-hash-table :test 'equal)))  ; declared names per scope
  (log nil)                                        ; stream to copy commands to
  (queries 0))

(defvar *z3* nil "The current Z3 session.")

(defun z3-start (&key log)
  (let ((exe (z3-executable)))
    (unless (and exe (probe-file exe))
      (error 'smt-solver-missing :path (or exe "z3")))
    (let ((p (uiop:launch-program (list (namestring exe) "-smt2" "-in")
                                  :input :stream :output :stream :error-output nil)))
      (let ((z (make-z3 :process p
                        :input (uiop:process-info-input p)
                        :output (uiop:process-info-output p)
                        :log log)))
        (z3-command z "(set-option :auto-config false)")
        (z3-command z "(set-option :model true)")
        z))))

(defun z3-stop (z)
  (ignore-errors (z3-command z "(exit)") (finish-output (z3-input z)))
  (ignore-errors (close (z3-input z)))
  (ignore-errors (uiop:wait-process (z3-process z)))
  (ignore-errors (close (z3-output z))))

(defmacro with-z3 ((&optional (var '*z3*) &rest keys) &body body)
  "Run BODY with VAR bound to a fresh Z3 session, stopped afterwards."
  `(let ((,var (z3-start ,@keys)))
     (unwind-protect (progn ,@body)
       (z3-stop ,var))))

(defun z3-command (z cmd)
  (write-line cmd (z3-input z))
  (when (z3-log z) (write-line cmd (z3-log z))))

(defun z3-check-sat (z)
  "Send (check-sat) and return :sat, :unsat or :unknown.  Errors reported
by Z3 since the last check signal SMT-ERROR."
  (z3-command z "(check-sat)")
  (finish-output (z3-input z))
  (incf (z3-queries z))
  (let ((errors '()))
    (loop
      (let ((line (read-line (z3-output z) nil nil)))
        (when (null line)
          (error 'smt-error :messages (reverse (cons "Z3 exited" errors))))
        (let ((l (string-trim '(#\Space #\Return #\Tab) line)))
          (cond ((string= l "sat") (return-from z3-check-sat (if errors (error 'smt-error :messages (reverse errors)) :sat)))
                ((string= l "unsat") (return-from z3-check-sat (if errors (error 'smt-error :messages (reverse errors)) :unsat)))
                ((string= l "unknown") (return-from z3-check-sat (if errors (error 'smt-error :messages (reverse errors)) :unknown)))
                ((string= l ""))
                (t (push l errors))))))))

(defun z3-push (z)
  (z3-command z "(push 1)")
  (push (make-hash-table :test 'equal) (z3-scopes z)))

(defun z3-pop (z)
  (z3-command z "(pop 1)")
  (pop (z3-scopes z)))

(defun z3-declared-p (z name)
  (some (lambda (h) (gethash name h)) (z3-scopes z)))

(defun z3-declare (z decl)
  "Send DECL = (NAME ARGS RESULT) unless NAME is declared in scope."
  (unless (z3-declared-p z (first decl))
    (setf (gethash (first decl) (first (z3-scopes z))) t)
    (z3-command z (decl->smt2 decl))))

(defmacro with-z3-scope ((z) &body body)
  (let ((v (gensym)))
    `(let ((,v ,z))
       (z3-push ,v)
       (unwind-protect (progn ,@body) (z3-pop ,v)))))
