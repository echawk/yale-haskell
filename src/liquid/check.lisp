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
;;;;             | (:nil) | (:cons E E)    list constructors
;;;;             | (:is CTOR E)            CTOR "[]" or ":": is E's constructor CTOR?
;;;;             | (:tail E)               the tail field of a (:) value
;;;;             | (:unknown SORT)         anything else: some value
;;;;             | (:at LINE E)            E's source line
;;;;   SORT    ::= :int | :bool | :list | NIL   (NIL: another type)
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
;;;;
;;;; Lists (milestone 4): every list has the measure len (>= 0) and the
;;;; user's measures over lists (measure m :: [a] -> Int, with equations
;;;; for [] and (:) that do not use the head); constructors and pattern
;;;; matches give their equations.  Calls of the Prelude's list functions
;;;; use *library-specs*.
;;;;
;;;; Polymorphism (milestone 5): at a call of a function with a refined
;;;; type, each type variable instantiated at a sort gets a new kvar
;;;; (refined instantiation), when the call gives it a lower bound and it
;;;; is not a list's element type; arguments of a function type (lambdas,
;;;; function names) are checked against the expected refined function
;;;; type.  Arrays at Int indexes have the measures alo and ahi, their
;;;; bounds (Array's listArray and (!)).

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
            ((member name '("[]" "String") :test #'string=) :list)
            ((string= name "Array") :array)
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
    (cond ((or (null r) (null term)) :true)
          ;; an instantiated type variable: its kvar is over the binders in
          ;; scope at the call, not the signature's
          ((kvar-p (cdr r)) (list :kvar (second (cdr r)) (list (cons (car r) term))))
          (t (subst (cdr r) (cons (cons (car r) term) su))))))

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
(defvar *fun-params* '()) ; ((NAME . TYPE) ..): parameters of a refined function type
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
  (let ((*vars* '()) (*hyps* '()) (*guards* '()) (*line* line) (*fname* name)
        (*fun-params* '()))
    (multiple-value-bind (args res) (fun-parts type (length params))
      (let ((su '()))
        (loop for p in params
              for (binder . atype) in args
              do (let ((sort (base-sort atype)))
                   (when (fun-type-p atype) (push (cons p atype) *fun-params*))
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
    (:letrec (eval-letrec (second e) (third e)))
    (:nil (let ((r (fresh-var :list)))
            (dolist (h (list-equations r "[]" nil)) (push h *hyps*))
            r))
    (:cons (eval-body (second e))
           (let ((tl (eval-body (third e)))
                 (r (fresh-var :list)))
             (dolist (h (list-equations r ":" tl)) (push h *hyps*))
             (push (list := (app "lq_tl" r) tl) *hyps*)
             r))
    (:is (let ((x (eval-body (third e))))
           (when x
             (let ((tl (app "lq_tl" x)))
               (dolist (h (list-equations x ":" tl))
                 (push (pred-imp (list :> (app "len" x) 0) h) *hyps*))
               (dolist (h (list-equations x "[]" nil))
                 (push (pred-imp (list := (app "len" x) 0) h) *hyps*))
               (if (string= (second e) ":")
                   (list :> (app "len" x) 0)
                   (list := (app "len" x) 0))))))
    (:tail (let ((x (eval-body (second e)))) (and x (app "lq_tl" x))))
    ;; a lambda not passed where a refined function is expected: its body
    ;; is checked with its parameters unrefined
    (:lam (destructuring-bind (params psorts rsort body) (rest e)
            (declare (ignore rsort))
            (let ((*vars* *vars*) (*hyps* *hyps*) (*guards* *guards*))
              (loop for p in params for s in psorts when s do (push (cons p s) *vars*))
              (eval-body body))
            nil))))

;;; ------------------------------------------------------------------
;;; Lists and measures

(defparameter *list-sort* '(:tc "[]" :int))
(defvar *measures* '())   ; ((NAME NIL-BODY TAIL-BINDER CONS-BODY) ..)

(defparameter *array-sort* '(:tc "Array_t"))

(defun fq-sort (s)
  (case s (:list *list-sort*) (:array *array-sort*) (t s)))

(defun list-equations (x ctor tl)
  "The measures' equations for X built by CTOR (with tail TL)."
  (if (string= ctor "[]")
      (cons (list := (app "len" x) 0)
            (loop for (m nil-body) in *measures*
                  when nil-body collect (list := (app m x) nil-body)))
      (list* (list := (app "len" x) (list :+ 1 (app "len" tl)))
             (list :>= (app "len" tl) 0)
             (loop for (m nil cons-tl cons-body) in *measures*
                   when cons-body
                     collect (list := (app m x) (subst cons-body (list (cons cons-tl tl))))))))

(defun spec-measures (specs)
  "The measures of SPECS over lists whose equations do not use the head:
((NAME NIL-BODY TAIL CONS-BODY) ..); a missing equation is NIL."
  (loop for s in specs
        when (and (eq (first s) :measure) (string/= (second s) "len"))
          collect (let ((nil-body nil) (tl nil) (cons-body nil))
                    (dolist (eqn (fourth s))
                      (destructuring-bind (m ctor args body) eqn
                        (declare (ignore m))
                        (let ((b (if (and (consp body) (eq (first body) :expr)) (second body) body)))
                          (cond ((string= ctor "[]") (setf nil-body b))
                                ((and (string= ctor ":") (= (length args) 2)
                                      (not (member (first args) (free-vars b) :test #'string=)))
                                 (setf tl (second args) cons-body b))))))
                    (list (second s) nil-body tl cons-body))))

(defun measure-consts (specs)
  (append (list (cons "len" (parse-sort-string "func(1, [[@(0)]; int])"))
                (cons "lq_tl" (parse-sort-string "func(1, [[@(0)]; [@(0)]])")))
          (list (cons "alo" (parse-sort-string "func(0, [Array_t; int])"))
                (cons "ahi" (parse-sort-string "func(0, [Array_t; int])")))
          (loop for s in specs
                when (and (eq (first s) :measure) (string/= (second s) "len"))
                  collect (cons (second s)
                                (parse-sort-string
                                 (if (eq (base-sort (nth-value 1 (fun-parts (third s) 1))) :bool)
                                     "func(1, [[@(0)]; bool])"
                                     "func(1, [[@(0)]; int])"))))))

;;; The Prelude's list functions, as Prelude.NAME (the compiler's
;;; *liquid-library-functions*); as LiquidHaskell's include/GHC/List.spec.
(defparameter *library-spec-text* "
{-@ assume head :: {v:[a] | len v > 0} -> a @-}
{-@ assume tail :: xs:{v:[a] | len v > 0} -> {v:[a] | len v = len xs - 1} @-}
{-@ assume (!!) :: xs:[a] -> {v:Int | 0 <= v && v < len xs} -> a @-}
{-@ assume length :: xs:[a] -> {v:Int | v = len xs} @-}
{-@ assume null :: xs:[a] -> {v:Bool | v <=> len xs = 0} @-}
{-@ assume (++) :: xs:[a] -> ys:[a] -> {v:[a] | len v = len xs + len ys} @-}
{-@ assume take :: n:Int -> xs:[a] -> {v:[a] | len v = (if n <= 0 then 0 else (if n <= len xs then n else len xs))} @-}
{-@ assume drop :: n:Int -> xs:[a] -> {v:[a] | len v = (if n <= 0 then len xs else (if n <= len xs then len xs - n else 0))} @-}
{-@ assume replicate :: n:Int -> x:a -> {v:[a] | len v = (if n <= 0 then 0 else n)} @-}
{-@ assume map :: (a -> b) -> xs:[a] -> {v:[b] | len v = len xs} @-}
{-@ assume reverse :: xs:[a] -> {v:[a] | len v = len xs} @-}
{-@ assume filter :: (a -> Bool) -> xs:[a] -> {v:[a] | len v <= len xs} @-}
{-@ assume foldr :: (a -> b -> b) -> b -> [a] -> b @-}
{-@ assume Array.listArray :: lo:Int -> hi:Int -> [e] -> {v:Array Int e | alo v = lo && ahi v = hi} @-}
{-@ assume Array.! :: a:Array Int e -> {v:Int | alo a <= v && v <= ahi a} -> e @-}
{-@ assume foldl :: (b -> a -> b) -> b -> [a] -> b @-}
{-@ assume zipWith :: (a -> b -> c) -> xs:[a] -> ys:[b] -> {v:[c] | len v = (if len xs <= len ys then len xs else len ys)} @-}
{-@ assume zip :: xs:[a] -> ys:[b] -> {v:[(a, b)] | len v = (if len xs <= len ys then len xs else len ys)} @-}
")

(defun library-specs ()
  (mapcar (lambda (s)
            (if (and (eq (first s) :assume) (not (search "Array." (second s))))
                (list :assume (concatenate 'string "Prelude." (second s)) (third s))
                s))
          (values (parse-spec-text *library-spec-text*))))

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
  (let ((fp (assoc f *fun-params* :test #'string=))
        (tm (lookup-template f))
        (sig (gethash f *sigs*)))
    (cond
      (fp (call-sig f (cdr fp) sort args))
      (tm (call-template f tm sort (mapcar #'eval-body args)))
      ((null sig) (mapc #'eval-body args) (and sort (fresh-var sort)))
      (t (call-sig f (car sig) sort args)))))

(defun call-sig (f type sort args)
  "A call of F, of refined type TYPE: its type variables are instantiated
with kvars, arguments of a function type are checked against it, the
others must satisfy their refinements."
  (let ((type (instantiate-call type sort args)))
        (multiple-value-bind (params res) (fun-parts type (length args))
          (let ((su '()))
            (loop for (binder . atype) in params
                  for a in args
                  for i from 1
                  do (if (fun-type-p atype)
                         (check-fun-arg a atype su (format nil "argument ~d of ~a" i f))
                         (let ((term (or (eval-body a)
                                         (and (type-reft atype) (fresh-var (base-sort atype))))))
                           (oblige (reft-at atype term su)
                                   (format nil "argument ~d of ~a" i f))
                           (when term (push (cons binder term) su)))))
            (let ((r (and (or sort (base-sort res)) (fresh-var (or sort (base-sort res))))))
              (when r
                (let ((h (reft-at res r su)))
                  (unless (eq h :true) (push h *hyps*))))
              r)))))

;;; ------------------------------------------------------------------
;;; Polymorphism and higher-order functions (milestone 5)

(defun fun-type-p (type)
  (and (consp type) (eq (first (strip-forall type)) :fun)))

(defun strip-at (e)
  (if (eq (first e) :at) (strip-at (third e)) e))

(defun exp-sort (e)
  "The sort of expression E, from its syntax."
  (case (first e)
    (:var (cdr (assoc (second e) *vars* :test #'string=)))
    (:int :int)
    (:bool :bool)
    ((:nil :cons :tail) :list)
    (:is :bool)
    (:at (exp-sort (third e)))
    ((:unknown :if :sorted) (second e))
    (:call (third e))
    (:let (exp-sort (fifth e)))
    (:prim (if (member (second e) '(:+ :- :* :neg :div :mod)) :int :bool))
    (t nil)))

(defun match-tyvars (type e table)
  "Record in TABLE the sorts at which expression E instantiates TYPE's
type variables."
  (case (and (consp type) (first type))
    (:var (let ((s (exp-sort e)))
            (when (and s (not (gethash (second type) table)))
              (setf (gethash (second type) table) s))))
    (:fun (let ((e (strip-at e)))
            (when (eq (first e) :lam)
              (let ((ty type))
                (dolist (s (third e))
                  (when (and (consp ty) (eq (first ty) :fun))
                    (match-tyvars (third ty) (list :sorted s) table)
                    (setf ty (fourth ty))))
                (match-tyvars ty (list :sorted (fourth e)) table)))))))

(defun instantiable-tyvars (type)
  "The type variables of function type TYPE that get a lower bound at a
call (an argument of that type, or a function argument's result) and do
not occur inside a type constructor (list elements are not tracked)."
  (let ((lower '()) (in-con '()))
    (labels ((vars-in (ty)
               (when (consp ty)
                 (case (first ty)
                   (:var (pushnew (second ty) in-con :test #'string=))
                   (:con (mapc #'vars-in (third ty)))
                   (:fun (vars-in (third ty)) (vars-in (fourth ty)))
                   (:forall (vars-in (fourth ty))))))
             (walk (ty)
               (when (consp ty)
                 (case (first ty)
                   (:con (mapc #'vars-in (third ty)))
                   (:fun (walk (third ty)) (walk (fourth ty)))
                   (:forall (walk (fourth ty)))))))
      (walk type)
      (let ((ty (strip-forall type)))
        (loop while (and (consp ty) (eq (first ty) :fun))
              do (let ((a (strip-forall (third ty))))
                   (when (eq (first a) :var) (pushnew (second a) lower :test #'string=))
                   (when (eq (first a) :fun)
                     (let ((r (nth-value 1 (fun-parts a most-positive-fixnum))))
                       (when (eq (first r) :var) (pushnew (second r) lower :test #'string=)))))
                 (setf ty (fourth ty)))))
    (set-difference lower in-con :test #'string=)))

(defun instantiate-call (type sort args)
  "TYPE with each of its type variables that a call (with result SORT and
arguments ARGS) instantiates at a sort replaced by a base type refined by
a new kvar over the binders in scope."
  (let ((table (make-hash-table :test #'equal))
        (ok (instantiable-tyvars type)))
    (multiple-value-bind (params res) (fun-parts type (length args))
      (loop for (nil . atype) in params
            for a in args
            do (match-tyvars atype a table))
      (match-tyvars res (list :sorted sort) table))
    (let ((scope (scope-vars)) (ks (make-hash-table :test #'equal)))
      (labels ((walk (ty)
                 (if (atom ty)
                     ty
                     (case (first ty)
                       (:var (let ((s (gethash (second ty) table)))
                               (if (and s (member (second ty) ok :test #'string=))
                                   (list :con (ecase s (:int "Int") (:bool "Bool") (:list "[]"))
                                         '() '()
                                         (cons *kvv*
                                               (list :kvar
                                                     (or (gethash (second ty) ks)
                                                         (setf (gethash (second ty) ks)
                                                               (new-kvar scope s)))
                                                     '()))
                                         '())
                                   ty)))
                       (:fun (list :fun (second ty) (walk (third ty)) (walk (fourth ty))))
                       (:forall (walk (fourth ty)))
                       (t ty)))))
        (walk type)))))

(defun check-fun-arg (arg ftype su what)
  "ARG is passed where a function of refined type FTYPE (binders of the
callee's earlier parameters substituted by SU) is expected: applied to
arguments satisfying FTYPE's parameters, its result must satisfy FTYPE's
result.  ARG is a lambda or a function's name; anything else is opaque."
  (let ((*vars* *vars*) (*hyps* *hyps*) (*guards* *guards*) (*fun-params* *fun-params*)
        (e (strip-at arg)))
    (multiple-value-bind (fparams fres) (fun-parts ftype most-positive-fixnum)
      (let* ((n (length fparams))
             (lam (and (eq (first e) :lam) (= (length (second e)) n)))
             (named (and (eq (first e) :call) (null (cdddr e))))
             (names (if lam
                        (second e)
                        (loop repeat n collect (format nil "lq_a~d" (incf *fresh*))))))
        (when (and (eq (first e) :lam) (not lam))
          (eval-body e))
        (loop for x in names
              for (binder . ptype) in fparams
              for i from 0
              do (let ((s (or (base-sort ptype) (and lam (nth i (third e))))))
                   (when s
                     (push (cons x s) *vars*)
                     (let ((h (reft-at ptype x su)))
                       (unless (eq h :true) (push h *hyps*))))
                   (when (fun-type-p ptype) (push (cons x ptype) *fun-params*))
                   (push (cons binder x) su)))
        (let ((term (cond (lam (eval-body (fifth e)))
                          (named (eval-call (second e) (base-sort fres)
                                            (mapcar (lambda (x) (list :var x)) names)))
                          (t nil))))
          (when (and (null term) (base-sort fres) (type-reft fres))
            (setf term (fresh-var (base-sort fres))))
          (oblige (reft-at fres term su) (format nil "the result of ~a" what)))))))

;;; ------------------------------------------------------------------
;;; The program

(defun check-program (program specs)
  "Check PROGRAM's functions.  Returns the list of failures (unproved
obligations), in program order."
  (let* ((specs (append (library-specs) specs))
         (*sigs* (spec-signatures specs))
         (*measures* (spec-measures specs))
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

(defun list-qualifiers ()
  (let ((l *list-sort*) (i 0))
    (flet ((q (params body)
             (make-fq-qual :name (format nil "List~d" (incf i)) :params params :body body)))
      (append
       (loop for op in '(:< :<= := :>=)
             collect (q `(("v" :int nil) ("x" ,l nil)) (list op "v" (app "len" "x"))))
       (list (q `(("v" ,l nil) ("x" ,l nil)) (list := (app "len" "v") (app "len" "x")))
             (q `(("v" ,l nil) ("x" ,l nil)) (list :<= (app "len" "v") (app "len" "x")))
             (q `(("v" ,l nil) ("x" :int nil)) (list := (app "len" "v") "x"))
             (q `(("v" ,l nil)) (list :> (app "len" "v") 0)))))))

(defun spec-qualifiers (specs)
  "One qualifier per atom of the specifications' refinements, its free
variables (all taken to be Int) its parameters, the value variable first."
  (let ((qs '()) (i 0) (fns (mapcar #'car (measure-consts specs))))
    (labels ((reft (vv p)
               (dolist (a (conjuncts p))
                 (when (and (consp a) (member (car a) *default-qualifier-ops*))
                   (let ((fv (set-difference (free-vars a) fns :test #'string=)))
                     (when (member vv fv :test #'string=)
                       (push (make-fq-qual
                              :name (format nil "Spec~d" (incf i))
                              :params (mapcar (lambda (x)
                                                (list x (measure-arg-sort x a) nil))
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

(defun measure-arg-sort (x e)
  "X's sort in atom E: an array or a list when it is a measure's argument,
else Int."
  (labels ((find-app (e)
             (and (consp e)
                  (if (and (eq (first e) :app) (member x (cddr e) :test #'equal))
                      (second e)
                      (some #'find-app (rest e))))))
    (let ((m (find-app e)))
      (cond ((null m) :int)
            ((member m '("alo" "ahi") :test #'equal) *array-sort*)
            (t *list-sort*)))))

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
                     (setf (gethash id (fq-info-binds info))
                           (list x (fq-sort sort) "lq_bv" :true))
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
                   :lhs (list :int "lq_lv"
                              (pred-and-list
                               (append (loop for (x . sort) in vars
                                             when (eq sort :list)
                                               collect (list :>= (app "len" x) 0))
                                       hyps)))
                   :rhs (list :int "lq_rv" goal)
                   :tag '() :line line)
                  (fq-info-constraints info)))))
      (setf (fq-info-constraints info) (nreverse (fq-info-constraints info)))
      (dolist (kv *kvars*)
        (destructuring-bind (k scope sort) kv
          (push (make-fq-wf :kvar k :env (mapcar (lambda (p) (bind (car p) (cdr p))) scope)
                            :sort (fq-sort sort) :vv *kvv*)
                (fq-info-wfs info))))
      (setf (fq-info-consts info) (measure-consts specs))
      (setf (fq-info-quals info) (append (default-qualifiers) (list-qualifiers)
                                         (spec-qualifiers specs))))
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
