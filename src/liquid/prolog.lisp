;;;; prolog.lisp -- a bounded cross-check of Z3 with SWI-Prolog's clpfd.
;;;;
;;;; Not a solver: Z3 is the decision procedure.  This backend searches for
;;;; a COUNTEREXAMPLE to HYPS => GOAL with every integer variable in
;;;; [-BOUND, BOUND], using SWI-Prolog's library(clpfd) (reified linear and
;;;; non-linear integer constraints, then labeling).  It covers the
;;;; integer/boolean fragment: integer and boolean variables and constants,
;;;; + - * div mod, comparisons, = and /=, the connectives, if-then-else.
;;;; Anything else (uninterpreted functions, reals, sets, data) is
;;;; :UNSUPPORTED.
;;;;
;;;; Its use is differential testing of the SMT encoding (tests.lisp): when
;;;; Z3 says VALID, no counterexample may exist; a counterexample found
;;;; here must be one Z3 also reports as INVALID.  div and mod follow
;;;; SMT-LIB's Euclidean definition (0 <= r < |d|), not Prolog's.
;;;;
;;;; The executable is *SWIPL-PATH* (default: $YALE_LIQUID_SWIPL, else swipl
;;;; on PATH, /opt/homebrew/bin/swipl, /usr/local/bin/swipl, /usr/bin/swipl).

(in-package :yale-liquid)

(defvar *swipl-path* nil "Path of the SWI-Prolog executable, or NIL to search.")

(defun swipl-executable ()
  (or *swipl-path*
      (let ((env (uiop:getenv "YALE_LIQUID_SWIPL")))
        (and env (plusp (length env)) env))
      (find-executable "swipl" '("/opt/homebrew/bin/swipl" "/usr/local/bin/swipl" "/usr/bin/swipl"))))

(defun swipl-available-p ()
  (let ((p (swipl-executable))) (and p (probe-file p) t)))

(define-condition prolog-unsupported (error)
  ((what :initarg :what :reader prolog-unsupported-what))
  (:report (lambda (c s) (format s "not in the clpfd fragment: ~a" (prolog-unsupported-what c)))))

(defvar *pl-vars* nil "Alist: local name -> (prolog-var . sort).")
(defvar *pl-aux* nil "Auxiliary constraints and variables for div/mod.")
(defvar *pl-counter* 0)
(defvar *pl-divs* nil "Memo: ((dividend . divisor) quotient remainder) ..")

(defun pl-fresh ()
  (let ((v (format nil "Aux_~d" (incf *pl-counter*))))
    (push (list :int v) *pl-aux*)
    v))

(defun pl-int (te)
  "A clpfd arithmetic expression for integer node TE."
  (unless (member (te-sort te) '(:int :num))
    (error 'prolog-unsupported :what (sort->string (te-sort te))))
  (let ((kids (te-kids te)))
    (case (te-kind te)
      (:int (format nil "(~d)" (te-data te)))
      (:var (let ((p (assoc (car (te-data te)) *pl-vars* :test #'string=)))
              (unless (and p (eq (cdr (te-data te)) :local))
                (error 'prolog-unsupported :what (car (te-data te))))
              (cadr p)))
      (:neg (format nil "(-~a)" (pl-int (first kids))))
      (:arith
       (let ((a (pl-int (first kids))) (b (pl-int (second kids))))
         (ecase (te-data te)
           (:+ (format nil "(~a+~a)" a b))
           (:- (format nil "(~a-~a)" a b))
           (:* (format nil "(~a*~a)" a b))
           ((:/ :mod)
            ;; Euclidean division: a = b*q + r, 0 <= r < |b| (when b /= 0).
            ;; Division by zero is an unspecified but fixed function in
            ;; SMT-LIB, so the same arguments share their q and r.
            (let ((memo (assoc (cons a b) *pl-divs* :test #'equal)))
              (unless memo
                (let ((q (pl-fresh)) (r (pl-fresh)))
                  (push (list :constraint
                              (format nil "((~a #\\= 0) #==> (~a #= ~a*~a + ~a #/\\ ~a #>= 0 #/\\ ~a #< abs(~a)))"
                                      b a b q r r r b))
                        *pl-aux*)
                  (setf memo (list (cons a b) q r))
                  (push memo *pl-divs*)))
              (if (eq (te-data te) :/) (second memo) (third memo)))))))
      (:ite (let ((c (pl-bool (first kids)))
                  (x (pl-int (second kids))) (y (pl-int (third kids)))
                  (z (pl-fresh)))
              (push (list :constraint (format nil "((~a) #==> (~a #= ~a))" c z x)) *pl-aux*)
              (push (list :constraint (format nil "((#\\ (~a)) #==> (~a #= ~a))" c z y)) *pl-aux*)
              z))
      (t (error 'prolog-unsupported :what (te-kind te))))))

(defun pl-bool (te)
  "A reifiable clpfd constraint for boolean node TE."
  (let ((kids (te-kids te)))
    (case (te-kind te)
      (:true "(1 #= 1)")
      (:false "(1 #= 0)")
      (:var (let ((p (assoc (car (te-data te)) *pl-vars* :test #'string=)))
              (unless (and p (eq (cdr (te-data te)) :local) (eq (cddr p) :bool))
                (error 'prolog-unsupported :what (car (te-data te))))
              (format nil "(~a #= 1)" (cadr p))))
      (:and (if kids (format nil "(~{~a~^ #/\\ ~})" (mapcar #'pl-bool kids)) "(1 #= 1)"))
      (:or (if kids (format nil "(~{~a~^ #\\/ ~})" (mapcar #'pl-bool kids)) "(1 #= 0)"))
      (:not (format nil "(#\\ ~a)" (pl-bool (first kids))))
      (:imp (format nil "(~a #==> ~a)" (pl-bool (first kids)) (pl-bool (second kids))))
      (:iff (format nil "(~a #<==> ~a)" (pl-bool (first kids)) (pl-bool (second kids))))
      (:ite (let ((c (pl-bool (first kids))))
              (format nil "((~a #/\\ ~a) #\\/ ((#\\ ~a) #/\\ ~a))"
                      c (pl-bool (second kids)) c (pl-bool (third kids)))))
      (:rel
       (let ((a (first kids)) (b (second kids)))
         (if (eq (te-sort a) :bool)
             (ecase (te-data te)
               ((:= :~~) (format nil "(~a #<==> ~a)" (pl-bool a) (pl-bool b)))
               ((:/= :!~) (format nil "(#\\ (~a #<==> ~a))" (pl-bool a) (pl-bool b))))
             (let ((x (pl-int a)) (y (pl-int b)))
               (format nil "(~a ~a ~a)" x
                       (ecase (te-data te)
                         ((:= :~~) "#=") ((:/= :!~) "#\\=") (:< "#<") (:<= "#=<")
                         (:> "#>") (:>= "#>="))
                       y)))))
      (t (error 'prolog-unsupported :what (te-kind te))))))

(defun prolog-check-valid (goal &key hyps vars (bound 20) (timeout 10))
  "Search for a counterexample to HYPS => GOAL with integer variables in
[-BOUND, BOUND].  VARS is ((name . sort) ..), sorts int or bool.  Returns
:COUNTEREXAMPLE (and the model as an alist), :NONE-IN-BOUNDS, :TIMEOUT or
:UNSUPPORTED (and the reason)."
  (handler-case
      (let* ((*pl-counter* 0)
             (*pl-aux* '())
             (*pl-divs* '())
             (*pl-vars* (loop for (x . s) in vars for i from 0
                              collect (progn
                                        (unless (member s '(:int :bool))
                                          (error 'prolog-unsupported :what (sort->string s)))
                                        (cons x (cons (format nil "V_~d" i) s)))))
             (genv (make-global-env))
             (hs (mapcar (lambda (h) (pl-bool (elaborate (ensure-expr h) vars genv))) hyps))
             (g (pl-bool (elaborate (ensure-expr goal) vars genv)))
             (ints (append (loop for p in *pl-vars* when (eq (cddr p) :int) collect (cadr p))
                           (loop for a in *pl-aux* when (eq (car a) :int) collect (second a))))
             (bools (loop for p in *pl-vars* when (eq (cddr p) :bool) collect (cadr p)))
             (aux (loop for a in *pl-aux* when (eq (car a) :constraint) collect (second a)))
             (program
               (with-output-to-string (o)
                 (format o ":- use_module(library(clpfd)).~%:- use_module(library(time)).~%")
                 (format o "query([~{~a~^, ~}], [~{~a~^, ~}]) :-~%" ints bools)
                 (format o "  [~{~a~^, ~}] ins ~d..~d,~%" ints (- bound) bound)
                 (format o "  [~{~a~^, ~}] ins 0..1,~%" bools)
                 (dolist (c aux) (format o "  ~a,~%" c))
                 (dolist (h hs) (format o "  ~a,~%" h))
                 (format o "  #\\ ~a,~%" g)
                 (format o "  append([~{~a~^, ~}], [~{~a~^, ~}], All), labeling([ff], All).~%" ints bools)
                 (format o "main :- catch(call_with_time_limit(~d, (query(Is, Bs) -> (write(cex(Is, Bs)), nl) ; (write(none), nl))), time_limit_exceeded, (write(timeout), nl)).~%"
                         timeout))))
        (unless (swipl-available-p)
          (return-from prolog-check-valid (values :unsupported "swipl not found")))
        (uiop:with-temporary-file (:stream s :pathname path :type "pl" :keep nil)
          (write-string program s)
          (finish-output s)
          (close s)
          (let* ((out (uiop:run-program (list (namestring (swipl-executable)) "-q" "-g" "main" "-t" "halt"
                                              (namestring path))
                                        :output :string :error-output :string :ignore-error-status t))
                 (line (string-trim '(#\Space #\Newline) out)))
            (cond ((uiop:string-prefix-p "cex(" line)
                   (let* ((nums (read-from-string
                                 (substitute #\Space #\, (substitute #\) #\] (substitute #\( #\[ (subseq line 3))))))
                          (ivals (first nums)) (bvals (second nums))
                          (model (append
                                  (loop for p in *pl-vars* when (eq (cddr p) :int)
                                        collect (cons (car p) (pop ivals)))
                                  (loop for p in *pl-vars* when (eq (cddr p) :bool)
                                        collect (cons (car p) (= 1 (pop bvals)))))))
                     (values :counterexample model)))
                  ((string= line "none") :none-in-bounds)
                  ((string= line "timeout") :timeout)
                  (t (values :unsupported (format nil "swipl said: ~a" out)))))))
    (prolog-unsupported (e) (values :unsupported (princ-to-string e)))
    (sort-error (e) (values :unsupported (princ-to-string e)))))
