;;;; check.lisp -- checking a program against its refined signatures with
;;;; Z3 (doc/plans/LIQUID-HASKELL.md, milestone 2: first-order Int and Bool
;;;; code, every checked function annotated, no inference).
;;;;
;;;; The program comes from the compiler (src/compiler/liquid/core.mumble),
;;;; one entry per top-level binding:
;;;;
;;;;   PROGRAM ::= (FUN ...)
;;;;   FUN     ::= (NAME (PARAM ...) BODY LINE [(SORT ...) SORT])
;;;;               the optional sorts are the parameters' and the result's
;;;;   BODY    ::= (:var X) | (:int N) | (:bool T-or-NIL)
;;;;             | (:prim OP E ...)        OP :+ :- :* :neg :< :<= :> :>= :=
;;;;                                       :/= :and :or :not :div :mod
;;;;             | (:call F SORT E ...)    a top-level function
;;;;             | (:if SORT E E E)
;;;;             | (:let X SORT E E)
;;;;             | (:letrec (FUN ...) E)   local functions, FUN as above
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
;;;; obligation is one Z3 validity check.  Termination is assumed, as
;;;; LiquidHaskell does with --no-termination.
;;;;
;;;; Inference (milestone 3): a function without a signature gets a
;;;; template, a refined type whose refinements are unknowns (kvars).  A
;;;; local function's parameters and result each get one, over the
;;;; binders in scope and its earlier parameters; a top-level function's
;;;; parameters are unrefined (any caller) and its result gets one.  The
;;;; obligations of all the functions are solved together by fixpoint.lisp
;;;; (predicate abstraction over the default qualifiers, comparisons of v
;;;; with 0 and with the binders in scope, and the atoms of the written
;;;; refinements).  A local function used as a value, not called, has its
;;;; parameters' kvars weakened to true.

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
(defvar *obligations*) ; (GOAL HYPS VARS LINE WHAT FNAME), latest first
(defvar *fresh* 0)
(defvar *templates*)        ; top-level NAME -> template
(defvar *local-templates*)  ; ((NAME . template) ..), innermost first
(defvar *kvars*)            ; ((KVAR ENV-VARS SORT) ..): each kvar's scope
(defparameter *kvv* "lq_v") ; a kvar's value variable

(defun fresh-var (sort)
  (let ((v (format nil "lq_t~d" (incf *fresh*))))
    (when sort (push (cons v sort) *vars*))
    v))

(defun oblige (goal what)
  (unless (eq goal :true)
    (push (list goal (append *guards* *hyps*) *vars* *line* what *fname*) *obligations*)))

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
                  (ta (eval-branch tc a))
                  (tb (eval-branch (and tc (pred-not tc)) b)))
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
              (eval-body body))))
    (:letrec (eval-letrec (second e) (third e)))))

(defun eval-branch (guard e)
  "E's term under GUARD (or none); the facts it adds hold under GUARD only."
  (let ((old *hyps*)
        (term (let ((*guards* (if guard (cons guard *guards*) *guards*)))
                (eval-body e))))
    (when guard
      (setf *hyps* (append (mapcar (lambda (h) (pred-imp guard h)) (ldiff *hyps* old))
                           old)))
    term))

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
        (sig (gethash f *sigs*))
        (tm (lookup-template f)))
    (cond
      (tm (call-template f tm sort terms))
      ((null sig) (and sort (fresh-var sort)))
      (t
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
              r)))))))

;;; ------------------------------------------------------------------
;;; The program

(defun check-program (program specs)
  "Check PROGRAM's functions.  Returns the list of failures (unproved
obligations), in program order."
  (let ((*sigs* (spec-signatures specs))
        (*templates* (make-hash-table :test #'equal))
        (*local-templates* '())
        (*kvars* '())
        (*fresh* 0)
        (obligations '()))
    ;; templates for the top-level functions without a signature
    (dolist (b program)
      (destructuring-bind (name params body line &optional psorts rsort) b
        (declare (ignore body line))
        (unless (or (gethash name *sigs*) (/= (length psorts) (length params)))
          (setf (gethash name *templates*)
                (make-template* '() (mapcar (lambda (s) (declare (ignore s)) nil) psorts)
                                psorts rsort)))))
    (dolist (b program)
      (destructuring-bind (name params body line &optional psorts rsort) b
        (declare (ignore psorts rsort))
        (let ((sig (gethash name *sigs*))
              (tm (gethash name *templates*))
              (*obligations* '()))
          (cond ((and sig (cdr sig)) (check-function name params body line (car sig)))
                (tm (check-template-function name params body line tm)))
          (setf obligations (append obligations (reverse *obligations*))))))
    (solve-obligations obligations specs)))

;;; ------------------------------------------------------------------
;;; Templates


(defstruct (template (:constructor make-template (params result)))
  params    ; ((FORMAL SORT KVAR) ..), KVAR NIL when unrefined
  result)   ; (SORT KVAR)

(defun formal-name (i) (format nil "lq_p~d" i))

(defun new-kvar (scope sort)
  (let ((k (format nil "k~d" (incf *fresh*))))
    (push (list k scope sort) *kvars*)
    k))

(defun make-template* (scope refine psorts rsort)
  "A template over SCOPE ((NAME . SORT) ..): the parameters of sort
PSORTS get a kvar each when REFINE says so, the result one."
  (let ((params '()) (formals '()) (i 0))
    (loop for s in psorts
          for r in refine
          do (let ((f (formal-name (incf i))))
               (push (list f s (and s r (new-kvar (append formals scope) s))) params)
               (when s (push (cons f s) formals))))
    (make-template (nreverse params)
                   (list rsort (and rsort (new-kvar (append formals scope) rsort))))))

(defun kapp (k su) (list :kvar k su))

(defun scope-vars ()
  "The binders in scope that a kvar may mention (not the fresh ones)."
  (remove-duplicates
   (remove-if (lambda (p) (and (>= (length (car p)) 3) (string= "lq_" (car p) :end2 3)))
              *vars*)
   :key #'car :test #'string= :from-end t))

(defun lookup-template (f)
  (let ((l (assoc f *local-templates* :test #'string=)))
    (cond (l (cdr l))
          ((gethash f *sigs*) nil)
          (t (gethash f *templates*)))))

(defun bind-template-params (params tm)
  "Assume the template's refinements of PARAMS; returns the substitution
of the formals."
  (let ((su '()))
    (loop for p in params
          for (formal sort k) in (template-params tm)
          do (when sort
               (push (cons p sort) *vars*)
               (when k (push (kapp k (cons (cons *kvv* p) su)) *hyps*))
               (push (cons formal p) su)))
    su))

(defun check-template-body (name params body tm)
  (let* ((su (bind-template-params params tm))
         (term (eval-body body)))
    (destructuring-bind (rsort k) (template-result tm)
      (when k
        (oblige (kapp k (cons (cons *kvv* (or term (fresh-var rsort))) su))
                (format nil "the result of ~a" name))))))

(defun check-template-function (name params body line tm)
  (let ((*vars* '()) (*hyps* '()) (*guards* '()) (*line* line) (*fname* name))
    (check-template-body name params body tm)))

(defun eval-letrec (funs body)
  (let ((*local-templates* *local-templates*)
        (scope (scope-vars)))
    (dolist (f funs)
      (destructuring-bind (name params fbody line psorts rsort) f
        (declare (ignore fbody line))
        (push (cons name (make-template* scope (mapcar (constantly t) params) psorts rsort))
              *local-templates*)))
    (dolist (f funs)
      (destructuring-bind (name params fbody line &rest sorts) f
        (declare (ignore sorts))
        (let ((*vars* *vars*) (*hyps* *hyps*) (*guards* *guards*) (*line* (or line *line*)))
          (check-template-body name params fbody (cdr (assoc name *local-templates*
                                                             :test #'string=))))))
    (eval-body body)))

(defun call-template (f tm sort terms)
  (let ((params (template-params tm)))
    (if (/= (length terms) (length params))
        (progn (escape-template tm) (and sort (fresh-var sort)))
        (let ((su '()) (i 0))
          (loop for (formal psort k) in params
                for term in terms
                do (incf i)
                   (when psort
                     (let ((term (or term (fresh-var psort))))
                       (when k
                         (oblige (kapp k (cons (cons *kvv* term) su))
                                 (format nil "argument ~d of ~a" i f)))
                       (push (cons formal term) su))))
          (destructuring-bind (rsort k) (template-result tm)
            (let ((r (and (or sort rsort) (fresh-var (or sort rsort)))))
              (when (and r k (or (null sort) (eq sort rsort)))
                (push (kapp k (cons (cons *kvv* r) su)) *hyps*))
              r))))))

(defun escape-template (tm)
  "TM's function is used as a value: its parameters may be anything."
  (let ((*hyps* '()) (*guards* '()) (su '()))
    (loop for (formal psort k) in (template-params tm)
          do (when psort
               (let ((x (fresh-var psort)))
                 (when k (oblige (kapp k (cons (cons *kvv* x) su)) "an escaping function"))
                 (push (cons formal x) su))))))

;;; ------------------------------------------------------------------
;;; Solving

(defparameter *default-qualifier-ops* '(:< :<= :> :>= := :/=))

(defun default-qualifiers ()
  (let ((qs '()) (i 0))
    (dolist (op *default-qualifier-ops*)
      (push (make-fq-qual :name (format nil "Cmp~d" (incf i))
                          :params '(("v" :int nil) ("x" :int nil))
                          :body (list op "v" "x"))
            qs)
      (push (make-fq-qual :name (format nil "Cmz~d" i)
                          :params '(("v" :int nil))
                          :body (list op "v" 0))
            qs))
    (nreverse qs)))

(defun spec-qualifiers (specs)
  "One qualifier per atom of the specifications' refinements, its free
variables (all taken to be Int) its parameters, the value variable first."
  (let ((qs '()) (i 0))
    (labels ((reft (vv p)
               (dolist (a (conjuncts p))
                 (when (and (consp a) (member (car a) *default-qualifier-ops*))
                   (let ((fv (free-vars a)))
                     (when (member vv fv :test #'string=)
                       (push (make-fq-qual
                              :name (format nil "Spec~d" (incf i))
                              :params (mapcar (lambda (x) (list x :int nil))
                                              (cons vv (remove vv fv :test #'string=)))
                              :body a)
                             qs))))))
             (walk (ty)
               (when (consp ty)
                 (case (first ty)
                   (:fun (walk (third ty)) (walk (fourth ty)))
                   (:forall (walk (fourth ty)))
                   (:con (let ((r (fifth ty))) (when r (reft (car r) (cdr r)))))))))
      (dolist (s specs)
        (case (first s)
          (:sig (walk (third s)))
          (:assume (walk (third s)))
          (:type-alias (walk (fifth s))))))
    (nreverse qs)))

(defun solve-obligations (obligations specs)
  "Solve OBLIGATIONS, (GOAL HYPS VARS LINE WHAT) each, with fixpoint.lisp;
the failures of the ones with concrete goals."
  (when (null obligations)
    (return-from solve-obligations '()))
  (let* ((info (make-fq-info))
         (ids (make-hash-table :test #'equal))
         (next 0))
    (flet ((bind (x sort)
             (let ((key (cons x sort)))
               (or (gethash key ids)
                   (let ((id (incf next)))
                     (setf (gethash id (fq-info-binds info)) (list x sort "lq_bv" :true))
                     (setf (gethash key ids) id))))))
      (let ((n 0))
        (dolist (o obligations)
          (destructuring-bind (goal hyps vars line what fname) o
            (declare (ignore what fname))
            (push (make-fq-constraint
                   :id (incf n)
                   :env (mapcar (lambda (p) (bind (car p) (cdr p)))
                                (remove-duplicates vars :key #'car :test #'string=
                                                        :from-end t))
                   :lhs (list :int "lq_lv" (pred-and-list hyps))
                   :rhs (list :int "lq_rv" goal)
                   :tag '() :line line)
                  (fq-info-constraints info)))))
      (setf (fq-info-constraints info) (nreverse (fq-info-constraints info)))
      (dolist (kv *kvars*)
        (destructuring-bind (k scope sort) kv
          (push (make-fq-wf :kvar k :env (mapcar (lambda (p) (bind (car p) (cdr p))) scope)
                            :sort sort :vv *kvv*)
                (fq-info-wfs info))))
      (setf (fq-info-quals info) (append (default-qualifiers) (spec-qualifiers specs))))
    (when (uiop:getenv "YALE_HASKELL_LIQUID_DEBUG")
      (print-fq info *error-output*))
    (let ((result (solve-fq info)))
      (when (eq (result-status result) :crash)
        (error "liquid: the fixpoint solver failed: ~a" (result-message result)))
      (loop for o in obligations
            for id from 1
            when (member id (result-unsafe-ids result))
              collect (destructuring-bind (goal hyps vars line what fname) o
                        (declare (ignore hyps vars))
                        (make-failure fname line what goal))))))
