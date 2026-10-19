;;;; check.lisp -- checking a program against its refined signatures with
;;;; Z3 (doc/plans/LIQUID-HASKELL.md, milestone 2: first-order Int and Bool
;;;; code, every checked function annotated, no inference).
;;;;
;;;; The program comes from the compiler (src/compiler/liquid/core.mumble),
;;;; one entry per top-level binding:
;;;;
;;;;   PROGRAM ::= ((NAME (PARAM ...) BODY LINE) ...)
;;;;   BODY    ::= (:var X) | (:int N) | (:bool T-or-NIL)
;;;;             | (:prim OP E ...)        OP :+ :- :* :neg :< :<= :> :>= :=
;;;;                                       :/= :and :or :not :div :mod
;;;;             | (:call F SORT E ...)    a top-level function
;;;;             | (:if SORT E E E)
;;;;             | (:let X SORT E E)
;;;;             | (:unknown SORT)         anything else: some value
;;;;             | (:at LINE E)            E's source line
;;;;   SORT    ::= :int | :bool | NIL      (NIL: another type)
;;;;
;;;; The specifications are parse-spec-text's: (:sig ..) is checked and
;;;; trusted at calls, (:assume ..) only trusted, (:type-alias ..) expands.
;;;;
;;;; A function is checked by evaluating its body to a logic term, with
;;;; its parameters' refinements as hypotheses: a call of a function with a
;;;; signature must give arguments that satisfy it (an obligation each) and
;;;; its result is a new variable with the result's refinement; div and
;;;; mod need a nonzero divisor; if's branches are evaluated under its
;;;; condition; the body's term must satisfy the result's refinement.  Each
;;;; obligation is one Z3 validity check (check-valid).  Termination is
;;;; assumed, as LiquidHaskell does with --no-termination.

(in-package :yale-liquid)

(defstruct (failure (:constructor make-failure (name line what goal)))
  name line what goal)

(defun failure-message (f)
  (format nil "~a: ~a~%  needs ~a" (failure-name f) (failure-what f)
          (expr->string (failure-goal f))))

;;; ------------------------------------------------------------------
;;; Refined types

(defun spec-signatures (specs)
  "NAME -> (TYPE . CHECKED-P), aliases expanded."
  (let ((aliases (loop for s in specs when (eq (first s) :type-alias) collect s))
        (table (make-hash-table :test #'equal)))
    (dolist (s specs)
      (case (first s)
        (:sig (dolist (n (second s))
                (setf (gethash n table) (cons (expand-aliases (third s) aliases) t))))
        (:assume (setf (gethash (second s) table)
                       (cons (expand-aliases (third s) aliases) nil)))))
    table))

(defun expand-aliases (type aliases &optional (depth 20))
  (if (<= depth 0)
      type
      (case (and (consp type) (first type))
        (:fun (list :fun (second type)
                    (expand-aliases (third type) aliases depth)
                    (expand-aliases (fourth type) aliases depth)))
        (:forall (list :forall (second type) (third type)
                       (expand-aliases (fourth type) aliases depth)))
        (:con
         (destructuring-bind (name args props reft preds) (rest type)
           (let ((alias (find name aliases :key #'second :test #'equal)))
             (if (null alias)
                 type
                 ;; (:type-alias NAME TYVARS VALUE-ARGS BODY): value
                 ;; arguments are the trailing (:expr E) arguments
                 (destructuring-bind (tyvars valargs body) (cddr alias)
                   (declare (ignore tyvars))
                   (let* ((vals (loop for a in args
                                      when (and (consp a) (eq (first a) :expr))
                                        collect (second a)))
                          (su (mapcar #'cons valargs vals))
                          (b (expand-aliases body aliases (1- depth))))
                     (declare (ignore props preds))
                     (if (and (consp b) (eq (first b) :con))
                         (let ((breft (fifth b)))
                           (list :con (second b) (third b) (fourth b)
                                 (conjoin-refts (and breft (cons (car breft) (subst (cdr breft) su)))
                                                reft)
                                 (sixth b)))
                         b)))))))
        (t type))))

(defun conjoin-refts (r1 r2)
  (cond ((null r1) r2)
        ((null r2) r1)
        (t (cons (car r1)
                 (pred-and (cdr r1) (subst (cdr r2) (list (cons (car r2) (car r1)))))))))

(defun base-sort (type)
  (when (and (consp type) (eq (first type) :con))
    (let ((name (second type)))
      (cond ((member name '("Int" "Integer" "Char") :test #'string=) :int)
            ((string= name "Bool") :bool)
            (t nil)))))

(defun type-reft (type)
  "A base type's refinement (VV . PRED), or NIL."
  (and (consp type) (eq (first type) :con) (fifth type)))

(defun strip-forall (type)
  (if (and (consp type) (eq (first type) :forall)) (strip-forall (fourth type)) type))

(defun fun-parts (type n)
  "The first N arguments of TYPE as ((BINDER . TYPE) ...), and the rest."
  (let ((args '()) (type (strip-forall type)))
    (loop repeat n
          while (and (consp type) (eq (first type) :fun))
          do (push (cons (second type) (third type)) args)
             (setf type (fourth type)))
    (values (nreverse args) type)))

(defun reft-at (type term su)
  "TYPE's refinement of TERM, binders substituted by SU; :true if none."
  (let ((r (type-reft type)))
    (if (or (null r) (null term))
        :true
        (subst (cdr r) (cons (cons (car r) term) su)))))

;;; ------------------------------------------------------------------
;;; Checking one function

(defvar *sigs*)
(defvar *vars*)        ; ((NAME . SORT) ...)
(defvar *hyps*)        ; facts: parameters' refinements, new variables'
(defvar *guards*)      ; path conditions
(defvar *line*)
(defvar *fname*)
(defvar *obligations*) ; (GOAL HYPS VARS LINE WHAT), latest first
(defvar *fresh* 0)

(defun fresh-var (sort)
  (let ((v (format nil "lq_t~d" (incf *fresh*))))
    (when sort (push (cons v sort) *vars*))
    v))

(defun oblige (goal what)
  (unless (eq goal :true)
    (push (list goal (append *guards* *hyps*) *vars* *line* what) *obligations*)))

(defun check-function (name params body line type)
  (let ((*vars* '()) (*hyps* '()) (*guards* '()) (*line* line) (*fname* name))
    (multiple-value-bind (args res) (fun-parts type (length params))
      (let ((su '()))
        (loop for p in params
              for (binder . atype) in args
              do (let ((sort (base-sort atype)))
                   (when sort (push (cons p sort) *vars*))
                   (let ((h (reft-at atype p su)))
                     (unless (eq h :true) (push h *hyps*)))
                   (push (cons binder p) su)))
        (let ((term (eval-body body)))
          (when (and (null term) (type-reft res))
            (setf term (fresh-var (base-sort res))))
          (oblige (reft-at res term su)
                  (format nil "the result of ~a" name)))))))

(defun eval-body (e)
  "E's value as a logic term, or NIL when it is not one (another type)."
  (ecase (first e)
    (:var (let ((x (second e))) (and (assoc x *vars* :test #'string=) x)))
    (:int (second e))
    (:bool (if (second e) :true :false))
    (:at (let ((*line* (second e))) (eval-body (third e))))
    (:unknown (and (second e) (fresh-var (second e))))
    (:prim (eval-prim (second e) (mapcar #'eval-body (cddr e))))
    (:call (eval-call (second e) (third e) (cdddr e)))
    (:if (destructuring-bind (sort c a b) (rest e)
           (let* ((tc (eval-body c))
                  (ta (let ((*guards* (if tc (cons tc *guards*) *guards*)))
                        (eval-body a)))
                  (tb (let ((*guards* (if tc (cons (pred-not tc) *guards*) *guards*)))
                        (eval-body b))))
             (cond ((and tc ta tb) (list :ite tc ta tb))
                   (sort (let ((r (fresh-var sort)))
                           (when (and tc ta) (push (pred-imp tc (list := r ta)) *hyps*))
                           (when (and tc tb) (push (pred-imp (pred-not tc) (list := r tb)) *hyps*))
                           r))
                   (t nil)))))
    (:let (destructuring-bind (x sort val body) (rest e)
            (let ((tv (eval-body val)))
              (when sort
                (push (cons x sort) *vars*)
                (when tv (push (list := x tv) *hyps*)))
              (eval-body body))))))

(defun eval-prim (op terms)
  (cond ((member nil terms) nil)
        ((member op '(:div :mod))
         (oblige (list :/= (second terms) 0) "a nonzero divisor")
         (list (if (eq op :div) :/ :mod) (first terms) (second terms)))
        ((eq op :neg) (list :neg (first terms)))
        ((eq op :not) (pred-not (first terms)))
        ((eq op :and) (pred-and (first terms) (second terms)))
        ((eq op :or) (pred-or (first terms) (second terms)))
        (t (cons op terms))))

(defun eval-call (f sort args)
  (let ((terms (mapcar #'eval-body args))
        (sig (gethash f *sigs*)))
    (if (null sig)
        (and sort (fresh-var sort))
        (multiple-value-bind (params res) (fun-parts (car sig) (length args))
          (let ((su '()))
            (loop for (binder . atype) in params
                  for term in terms
                  for i from 1
                  do (let ((term (or term (and (type-reft atype) (fresh-var (base-sort atype))))))
                       (oblige (reft-at atype term su)
                               (format nil "argument ~d of ~a" i f))
                       (when term (push (cons binder term) su))))
            (let ((r (and (or sort (base-sort res)) (fresh-var (or sort (base-sort res))))))
              (when r
                (let ((h (reft-at res r su)))
                  (unless (eq h :true) (push h *hyps*))))
              r))))))

;;; ------------------------------------------------------------------
;;; The program

(defun check-program (program specs)
  "Check PROGRAM's functions that have a signature.  Returns the list of
failures (unproved obligations), in program order."
  (let ((*sigs* (spec-signatures specs))
        (*fresh* 0)
        (failures '()))
    (with-z3 (z)
      (dolist (b program)
        (destructuring-bind (name params body line) b
          (let ((sig (gethash name *sigs*))
                (*obligations* '()))
            (when (and sig (cdr sig))
              (check-function name params body line (car sig))
              (dolist (o (reverse *obligations*))
                (destructuring-bind (goal hyps vars oline what) o
                  (unless (eq (check-valid goal :hyps hyps :vars vars :z3 z) :valid)
                    (push (make-failure name oline what goal) failures)))))))))
    (nreverse failures)))
