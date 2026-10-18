;;;; logic.lisp -- sorts, expressions and predicates of the refinement logic.
;;;;
;;;; The logic mirrors liquid-fixpoint's Language.Fixpoint.Types.Sorts and
;;;; Language.Fixpoint.Types.Refinements (https://github.com/ucsd-progsys/
;;;; liquid-fixpoint, commit 0b924442ce26a8f270bffac18ba6295bc7411646),
;;;; written as s-expressions so that they print, compare (EQUAL) and
;;;; pattern-match easily.  Symbols of the logic are Lisp strings (case
;;;; matters, as in Haskell).
;;;;
;;;; SORTS (liquid-fixpoint's Sort)
;;;;
;;;;   :int :real :bool :str          FInt, FReal, bool, Str
;;;;   :num :frac                     the numeric sort classes FNum, FFrac
;;;;   (:var i)                       FVar i, written @(i)
;;;;   (:obj "a")                     FObj a: an uninterpreted sort / rigid
;;;;                                  type variable, written a
;;;;   (:func n (s1 .. sk) r)         FAbs^n (s1 -> .. -> sk -> r), written
;;;;                                  func(n, [s1; ..; sk; r]); (:var 0) ..
;;;;                                  (:var n-1) are bound
;;;;   (:tc "C" s1 .. sk)             a type constructor applied to sorts
;;;;                                  (FTC applied with FApp); lists are
;;;;                                  (:tc "[]" s), sets (:tc "Set_Set" s)
;;;;   (:sapp s s1 .. sk)             a sort variable applied to sorts (m a)
;;;;   (:nat n)                       FNatNum (type-level naturals)
;;;;
;;;; EXPRESSIONS AND PREDICATES (liquid-fixpoint's Expr; predicates are
;;;; expressions of sort bool)
;;;;
;;;;   123                            integer constant (ECon (I n))
;;;;   (:real 3/2)                    real constant (ECon (R d)), exact
;;;;   "x"                            variable (EVar)
;;;;   (:str "abc")                   string literal (ESym)
;;;;   (:lit "text" sort)             lit "text" sort (ECon (L t s))
;;;;   (:app f e1 .. en)              application (EApp, uncurried; f is an
;;;;                                  expression, usually a variable)
;;;;   (:neg e)                       unary minus
;;;;   (:+ a b) (:- a b) (:* a b) (:/ a b) (:mod a b)   EBin
;;;;   (:ite p a b)                   if p then a else b
;;;;   (:cast e sort)                 (e : sort)
;;;;   :true :false                   PTrue, PFalse
;;;;   (:and p ..) (:or p ..)         PAnd, POr
;;;;   (:not p) (:=> p q) (:<=> p q)  PNot, PImp, PIff
;;;;   (:= a b) (:/= a b) (:< a b) (:<= a b) (:> a b) (:>= a b)
;;;;   (:~~ a b) (:!~ a b)            PAtom (~~ and !~ are the unsorted
;;;;                                  (dis)equalities Ueq, Une)
;;;;   (:kvar "k" ((x . e) ..))       a refinement variable $k[x:=e]..
;;;;   (:exists ((x . s) ..) p)       PExist
;;;;   (:forall ((x . s) ..) p)       PAll
;;;;   (:lam ("x" . s) e)             \x:s -> e
;;;;   (:coerce s1 s2 e)              coerce (s1 ~ s2) e
;;;;   :hole                          _ (a hole, LiquidHaskell only)
;;;;
;;;; A REFINEMENT (liquid-fixpoint's Reft) is a cons (VV . PRED); a SORTED
;;;; REFINEMENT (SortedReft) is a list (SORT VV PRED), e.g.
;;;; (:int "v" (:> "v" 0)) for {v:int | v > 0}.

(in-package :yale-liquid)

;;; ------------------------------------------------------------------
;;; Sorts

(defparameter *base-sorts* '(:int :real :bool :str :num :frac))

(defun sort-p (x)
  (or (member x *base-sorts*)
      (and (consp x) (member (car x) '(:var :obj :func :tc :sapp :nat :uv)))))

(defun func-sort (n args result)
  "A function sort; nested function results are flattened, as
liquid-fixpoint's mkFFunc does."
  (if (and (consp result) (eq (car result) :func) (zerop (second result)))
      (list :func n (append args (third result)) (fourth result))
      (list :func n args result)))

(defun func-sort-p (s) (and (consp s) (eq (car s) :func)))

(defun tc-sort (name &rest args) (list* :tc name args))

(defun list-sort (elt) (tc-sort "[]" elt))

(defun map-sort (f sort)
  "Rebuild SORT bottom-up, applying F to every node (after its parts)."
  (funcall f
           (if (consp sort)
               (case (car sort)
                 (:func (list :func (second sort)
                              (mapcar (lambda (s) (map-sort f s)) (third sort))
                              (map-sort f (fourth sort))))
                 (:tc (list* :tc (second sort)
                             (mapcar (lambda (s) (map-sort f s)) (cddr sort))))
                 (:sapp (cons :sapp (mapcar (lambda (s) (map-sort f s)) (cdr sort))))
                 (t sort))
               sort)))

(defun sort-objs (sort)
  "The names of the (:obj ..) sorts in SORT, in order of appearance."
  (let ((acc '()))
    (map-sort (lambda (s)
                (when (and (consp s) (eq (car s) :obj))
                  (pushnew (second s) acc :test #'string=))
                s)
              sort)
    (nreverse acc)))

(defun generalize-sorts (sorts)
  "liquid-fixpoint's gSorts (Types/Constraints.hs): replace the (:obj a)
sorts of SORTS by sort variables (:var i), numbering them in order."
  (let* ((objs (remove-duplicates (mapcan #'sort-objs sorts)
                                  :test #'string= :from-end t))
         (su (loop for o in objs for i from 0 collect (cons o i))))
    (values (mapcar (lambda (s)
                      (map-sort (lambda (x)
                                  (if (and (consp x) (eq (car x) :obj))
                                      (let ((p (assoc (second x) su :test #'string=)))
                                        (if p (list :var (cdr p)) x))
                                      x))
                                s))
                    sorts)
            (length objs))))

;;; ------------------------------------------------------------------
;;; Expressions

(defparameter *arith-ops* '(:+ :- :* :/ :mod))
(defparameter *rel-ops* '(:= :/= :< :<= :> :>= :~~ :!~))

(defun var-p (e) (stringp e))

(defun expr-equal (a b) (equal a b))

(defun pred-and (&rest ps)
  "Smart conjunction (liquid-fixpoint's pAnd): flattens, drops true,
collapses to false, removes duplicates."
  (let ((acc '()))
    (dolist (p ps)
      (dolist (q (conjuncts p))
        (cond ((eq q :true))
              ((eq q :false) (return-from pred-and :false))
              (t (pushnew q acc :test #'equal)))))
    (setf acc (nreverse acc))
    (cond ((null acc) :true)
          ((null (cdr acc)) (car acc))
          (t (cons :and acc)))))

(defun pred-and-list (ps) (apply #'pred-and ps))

(defun pred-or (&rest ps)
  (let ((acc '()))
    (dolist (p ps)
      (cond ((eq p :false))
            ((eq p :true) (return-from pred-or :true))
            ((and (consp p) (eq (car p) :or))
             (dolist (q (cdr p)) (pushnew q acc :test #'equal)))
            (t (pushnew p acc :test #'equal))))
    (setf acc (nreverse acc))
    (cond ((null acc) :false)
          ((null (cdr acc)) (car acc))
          (t (cons :or acc)))))

(defun pred-not (p)
  (case p
    (:true :false)
    (:false :true)
    (t (if (and (consp p) (eq (car p) :not)) (second p) (list :not p)))))

(defun pred-imp (p q)
  (cond ((eq p :true) q)
        ((eq p :false) :true)
        ((eq q :true) :true)
        (t (list :=> p q))))

(defun conjuncts (p)
  "The conjuncts of P, flattening nested conjunctions and dropping true."
  (cond ((eq p :true) '())
        ((and (consp p) (eq (car p) :and)) (mapcan #'conjuncts (copy-list (cdr p))))
        (t (list p))))

(defun kvar-p (e) (and (consp e) (eq (car e) :kvar)))

(defun app (f &rest args)
  "Application, flattening (:app (:app f a) b) into (:app f a b)."
  (if (and (consp f) (eq (car f) :app))
      (append f args)
      (list* :app f args)))

;;; ------------------------------------------------------------------
;;; Traversals

(defun map-expr (f e)
  "Rebuild expression E bottom-up, applying F to each node after its
children (binders are left alone)."
  (funcall
   f
   (if (atom e)
       e
       (case (car e)
         ((:real :str :lit) e)
         ((:app :neg :+ :- :* :/ :mod :ite :and :or :not :=> :<=>
           := :/= :< :<= :> :>= :~~ :!~)
          (cons (car e) (mapcar (lambda (x) (map-expr f x)) (cdr e))))
         (:cast (list :cast (map-expr f (second e)) (third e)))
         (:kvar (list :kvar (second e)
                      (mapcar (lambda (p) (cons (car p) (map-expr f (cdr p))))
                              (third e))))
         ((:exists :forall) (list (car e) (second e) (map-expr f (third e))))
         (:lam (list :lam (second e) (map-expr f (third e))))
         (:coerce (list :coerce (second e) (third e) (map-expr f (fourth e))))
         (t e)))))

(defun free-vars (e &optional bound)
  "The free variables of E, as a list of strings without duplicates.
The variables in a kvar's substitution ranges count, its domain does not."
  (let ((acc '()))
    (labels ((walk (e bound)
               (cond ((stringp e)
                      (unless (member e bound :test #'string=)
                        (pushnew e acc :test #'string=)))
                     ((atom e))
                     (t (case (car e)
                          ((:real :str :lit))
                          (:cast (walk (second e) bound))
                          (:kvar (dolist (p (third e)) (walk (cdr p) bound)))
                          ((:exists :forall)
                           (walk (third e) (append (mapcar #'car (second e)) bound)))
                          (:lam (walk (third e) (cons (car (second e)) bound)))
                          (:coerce (walk (fourth e) bound))
                          (t (dolist (x (cdr e)) (walk x bound))))))))
      (walk e bound))
    (nreverse acc)))

(defun kvars-of (e)
  "The (:kvar ..) occurrences in E."
  (let ((acc '()))
    (labels ((walk (e)
               (when (consp e)
                 (case (car e)
                   (:kvar (push e acc))
                   ((:real :str :lit))
                   (:cast (walk (second e)))
                   ((:exists :forall :lam) (walk (third e)))
                   (:coerce (walk (fourth e)))
                   (t (mapc #'walk (cdr e)))))))
      (walk e))
    (nreverse acc)))

;;; ------------------------------------------------------------------
;;; Substitution (Language.Fixpoint.Types.Substitutions)
;;;
;;; A substitution is an alist ((x . e) ..).  Applying it to a kvar
;;; composes it with the kvar's own pending substitution, as
;;; liquid-fixpoint does: $k[y:=a] θ = $k[y:=aθ, x:=θ(x) for x not y].

(defun subst-lookup (x su)
  (cdr (assoc x su :test #'string=)))

(defun compose-kvar-subst (ksu su)
  (append (mapcar (lambda (p) (cons (car p) (subst (cdr p) su))) ksu)
          (remove-if (lambda (p) (assoc (car p) ksu :test #'string=)) su)))

(defun subst (e su)
  "Apply substitution SU to expression E.  Bound variables shadow."
  (if (null su)
      e
      (cond ((stringp e)
             (let ((p (assoc e su :test #'string=)))
               (if p (cdr p) e)))
            ((atom e) e)
            (t (case (car e)
                 ((:real :str :lit) e)
                 (:cast (list :cast (subst (second e) su) (third e)))
                 (:kvar (list :kvar (second e) (compose-kvar-subst (third e) su)))
                 ((:exists :forall)
                  (let ((bound (mapcar #'car (second e))))
                    (list (car e) (second e)
                          (subst (third e)
                                 (remove-if (lambda (p) (member (car p) bound :test #'string=))
                                            su)))))
                 (:lam (list :lam (second e)
                             (subst (third e)
                                    (remove (car (second e)) su
                                            :key #'car :test #'string=))))
                 (:coerce (list :coerce (second e) (third e) (subst (fourth e) su)))
                 (t (cons (car e) (mapcar (lambda (x) (subst x su)) (cdr e)))))))))

(defun subst1 (e x y)
  "E with X replaced by Y (an expression)."
  (subst e (list (cons x y))))

(defun reft-pred-at (vv pred x)
  "The predicate of refinement {VV | PRED} for the binder X: PRED[VV:=X]."
  (if (equal vv x) pred (subst1 pred vv x)))

(defun lit-symbol-p (x)
  "Upstream's isLitSymbol: lit$abc names the string literal \"abc\"."
  (and (stringp x) (> (length x) 4) (string= "lit$" x :end2 4)))
