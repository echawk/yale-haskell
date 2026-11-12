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
;;;; Every query has a timeout: *Z3-TIMEOUT-MS* (default 10 s, or
;;;; $YALE_LIQUID_Z3_TIMEOUT seconds) (YHS-0.2).  It is sent as
;;;; (set-option :timeout N), which makes Z3 answer "unknown", but Z3 does
;;;; not check that flag in every loop (tests/liquid/fq/pos/hex.ts.fq spins
;;;; in the string theory and ignores both the option and SIGINT).  So
;;;; Z3-CHECK-SAT also watches the clock: if no answer comes within the
;;;; timeout plus a grace period, it kills Z3, starts a new process, replays
;;;; the commands of the open scopes, and returns :unknown.  A timed-out
;;;; query is reported on *ERROR-OUTPUT*, named by *Z3-QUERY-LABEL* and its
;;;; number in the session.
;;;;
;;;; A session also keeps a stack of the SMT names declared in each
;;;; (push) scope, so that callers can declare symbols lazily and have
;;;; them re-declared after a (pop) removes them.

(in-package :yale-liquid)

(defvar *z3-path* nil
  "Path of the Z3 executable, or NIL to search for it.")

(defvar *z3-timeout-ms* nil
  "Per-query Z3 timeout in milliseconds, or NIL for the default
($YALE_LIQUID_Z3_TIMEOUT seconds, else 10 s).")

(defvar *z3-query-label* nil
  "A name for the queries being asked (a file, a goal), shown when one times out.")

(defun z3-timeout-ms ()
  (or *z3-timeout-ms*
      (let* ((env (uiop:getenv "YALE_LIQUID_Z3_TIMEOUT"))
             (n (and env (plusp (length env))
                     (ignore-errors (let ((*read-eval* nil)) (read-from-string env))))))
        (if (and (realp n) (plusp n)) (round (* 1000 n)) 10000))))

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
  (history (list '()))                             ; commands sent per open scope, newest first
  (log nil)                                        ; stream to copy commands to
  (queries 0)
  (timeouts 0))                                    ; queries that timed out

(defvar *z3* nil "The current Z3 session.")

(defun z3-launch (z)
  "Start the Z3 process of session Z and send the options."
  (let* ((exe (z3-executable)))
    (unless (and exe (probe-file exe))
      (error 'smt-solver-missing :path (or exe "z3")))
    (let ((p (uiop:launch-program (list (namestring exe) "-smt2" "-in")
                                  :input :stream :output :stream :error-output nil)))
      (setf (z3-process z) p
            (z3-input z) (uiop:process-info-input p)
            (z3-output z) (uiop:process-info-output p)))
    (z3-command z "(set-option :auto-config false)")
    (z3-command z "(set-option :model true)")
    (z3-command z (format nil "(set-option :timeout ~d)" (z3-timeout-ms)))))

(defun z3-start (&key log)
  (let ((z (make-z3 :log log)))
    (z3-launch z)
    z))

(defun z3-restart (z)
  "Kill the Z3 process of Z, start another and replay the commands of the open scopes."
  (ignore-errors (uiop:terminate-process (z3-process z) :urgent t))
  (ignore-errors (close (z3-input z) :abort t))
  (ignore-errors (close (z3-output z) :abort t))
  (ignore-errors (uiop:wait-process (z3-process z)))
  (let ((old (reverse (z3-history z))))
    (setf (z3-history z) (list '()))
    ;; Z3-LAUNCH records the options in the new history, so that a later
    ;; restart can again skip them with NTHCDR 3
    (z3-launch z)
    ;; replay: the options were re-sent by Z3-LAUNCH; the rest comes from OLD
    (let ((cmds (apply #'append (mapcar #'reverse old))))
      (dolist (c (nthcdr 3 cmds))
        (if (string= c "(push 1)")
            (progn (push '() (z3-history z)) (z3-command z c))
            (z3-command z c))))
    (finish-output (z3-input z))))

(defun z3-stop (z)
  (ignore-errors (z3-send z "(exit)") (finish-output (z3-input z)))
  (ignore-errors (close (z3-input z)))
  ;; a Z3 still busy with a query it ignores the timeout of never reads
  ;; the (exit): after a second it is killed, so neither this process
  ;; waits on it nor it outlives this process
  (let ((deadline (+ (get-internal-real-time) internal-time-units-per-second)))
    (loop while (and (ignore-errors (uiop:process-alive-p (z3-process z)))
                     (< (get-internal-real-time) deadline))
          do (sleep 0.01)))
  (when (ignore-errors (uiop:process-alive-p (z3-process z)))
    (ignore-errors (uiop:terminate-process (z3-process z) :urgent t)))
  (ignore-errors (uiop:wait-process (z3-process z)))
  (ignore-errors (close (z3-output z))))

(defmacro with-z3 ((&optional (var '*z3*) &rest keys) &body body)
  "Run BODY with VAR bound to a fresh Z3 session, stopped afterwards."
  `(let ((,var (z3-start ,@keys)))
     (unwind-protect (progn ,@body)
       (z3-stop ,var))))

(defun z3-send (z cmd)
  "Send CMD without recording it for replay."
  (write-line cmd (z3-input z))
  (when (z3-log z) (write-line cmd (z3-log z))))

(defun z3-command (z cmd)
  (push cmd (first (z3-history z)))
  (z3-send z cmd))

(defun z3-read-line (z)
  "The next output line of Z3, or :TIMEOUT if none arrives within the
query timeout plus a grace period, or NIL at end of file."
  (let ((deadline (+ (get-internal-real-time)
                     (* (+ (z3-timeout-ms) 2000) (/ internal-time-units-per-second 1000))))
        (out (z3-output z)))
    (loop
      (cond ((listen out) (return (read-line out nil nil)))
            ((not (uiop:process-alive-p (z3-process z))) (return (read-line out nil nil)))
            ((> (get-internal-real-time) deadline) (return :timeout))
            (t (sleep 0.005))))))

(defun z3-check-sat (z)
  "Send (check-sat) and return :sat, :unsat or :unknown (also when the
query timed out).  Errors reported by Z3 since the last check signal
SMT-ERROR."
  (z3-send z "(check-sat)")
  (finish-output (z3-input z))
  (incf (z3-queries z))
  (let ((errors '()))
    (loop
      (let ((line (z3-read-line z)))
        (when (eq line :timeout)
          (z3-report-timeout z)
          (z3-restart z)
          (return-from z3-check-sat :unknown))
        (when (null line)
          (error 'smt-error :messages (reverse (cons "Z3 exited" errors))))
        (let ((l (string-trim '(#\Space #\Return #\Tab) line)))
          (flet ((answer (r)
                   (when errors (error 'smt-error :messages (reverse errors)))
                   (when (eq r :unknown) (z3-note-timeout z))
                   (return-from z3-check-sat r)))
            (cond ((string= l "sat") (answer :sat))
                  ((string= l "unsat") (answer :unsat))
                  ((string= l "unknown") (answer :unknown))
                  ((string= l ""))
                  (t (push l errors)))))))))

(defun z3-report-timeout (z)
  (incf (z3-timeouts z))
  (format *error-output* "~&yale-liquid: Z3 query timed out after ~d ms: ~a (query ~d); result unknown~%"
          (z3-timeout-ms) (or *z3-query-label* "<unnamed>") (z3-queries z))
  (finish-output *error-output*))

(defun z3-note-timeout (z)
  "After an \"unknown\" answer, ask Z3 why; report a timeout by name."
  (z3-send z "(get-info :reason-unknown)")
  (finish-output (z3-input z))
  (let ((line (z3-read-line z)))
    (when (and (stringp line) (or (search "timeout" line) (search "canceled" line)))
      (z3-report-timeout z))))

(defun z3-push (z)
  (push '() (z3-history z))
  (z3-command z "(push 1)")
  (push (make-hash-table :test 'equal) (z3-scopes z)))

(defun z3-pop (z)
  (z3-send z "(pop 1)")
  (pop (z3-history z))
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
