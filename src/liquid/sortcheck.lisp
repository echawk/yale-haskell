;;;; sortcheck.lisp -- sort inference and elaboration.
;;;;
;;;; After liquid-fixpoint's src/Language/Fixpoint/SortCheck.hs (commit
;;;; 0b924442ce26a8f270bffac18ba6295bc7411646): expressions are checked
;;;; against an environment of sorted symbols by unification, polymorphic
;;;; symbols (func(n, ..)) are instantiated at each use, and the result is
;;;; an ELABORATED tree in which every node carries its sort, which is what
;;;; the SMT encoding (smt.lisp) needs to pick monomorphic instances,
;;;; datatype casts and integer versus real arithmetic.
;;;;
;;;; Sort meta-variables are (:uv n); their bindings and kinds (:any, :num
;;;; for the numeric class, :frac for the fractional class) live in the
;;;; dynamic tables below for the duration of one ELABORATE call.  A sort
;;;; error signals SORT-ERROR; callers treat an ill-sorted hypothesis as
;;;; absent and an ill-sorted goal as not valid.

(in-package :yale-liquid)

(define-condition sort-error (error)
  ((message :initarg :message :reader sort-error-message))
  (:report (lambda (c s) (format s "sort error: ~a" (sort-error-message c)))))

(defun sort-fail (fmt &rest args)
  (error 'sort-error :message (apply #'format nil fmt args)))

;;; ------------------------------------------------------------------
;;; The global symbol environment (liquid-fixpoint's SymEnv)

(defstruct sym-env
  (sorts (make-hash-table :test 'equal))      ; symbol -> sort
  (kinds (make-hash-table :test 'equal))      ; symbol -> :uninterp :ctor :selector :tester :theory
  (data (make-hash-table :test 'equal))       ; tycon -> fq-data
  (ctor-of (make-hash-table :test 'equal))    ; ctor/selector/tester -> (fq-data . ctor)
  (allow-ho nil))

(defparameter *theory-symbols*
  ;; The interpreted symbols of Smt/Theories.hs (interpSymbols) that have a
  ;; Z3 encoding here, with their sorts in liquid-fixpoint syntax.
  '(("Set_empty" "func(1, [int; (Set_Set @(0))])")
    ("Set_emp" "func(1, [(Set_Set @(0)); bool])")
    ("Set_sng" "func(1, [@(0); (Set_Set @(0))])")
    ("Set_add" "func(1, [@(0); (Set_Set @(0)); (Set_Set @(0))])")
    ("Set_mem" "func(1, [@(0); (Set_Set @(0)); bool])")
    ("Set_cup" "func(1, [(Set_Set @(0)); (Set_Set @(0)); (Set_Set @(0))])")
    ("Set_cap" "func(1, [(Set_Set @(0)); (Set_Set @(0)); (Set_Set @(0))])")
    ("Set_dif" "func(1, [(Set_Set @(0)); (Set_Set @(0)); (Set_Set @(0))])")
    ("Set_sub" "func(1, [(Set_Set @(0)); (Set_Set @(0)); bool])")
    ("Set_com" "func(1, [(Set_Set @(0)); (Set_Set @(0))])")
    ("Set_card" "func(1, [(Set_Set @(0)); int])")
    ("Map_default" "func(2, [@(1); (Map_t @(0) @(1))])")
    ("Map_select" "func(2, [(Map_t @(0) @(1)); @(0); @(1)])")
    ("Map_store" "func(2, [(Map_t @(0) @(1)); @(0); @(1); (Map_t @(0) @(1))])")
    ("Bag_empty" "func(1, [int; (Bag_t @(0))])")
    ("Bag_sng" "func(1, [@(0); int; (Bag_t @(0))])")
    ("Bag_count" "func(1, [@(0); (Bag_t @(0)); int])")
    ("Bag_union" "func(1, [(Bag_t @(0)); (Bag_t @(0)); (Bag_t @(0))])")
    ("Bag_union_max" "func(1, [(Bag_t @(0)); (Bag_t @(0)); (Bag_t @(0))])")
    ("Bag_inter_min" "func(1, [(Bag_t @(0)); (Bag_t @(0)); (Bag_t @(0))])")
    ("Bag_sub" "func(1, [(Bag_t @(0)); (Bag_t @(0)); bool])")
    ("strLen" "func(0, [Str; int])")
    ("subString" "func(0, [Str; int; int; Str])")
    ("concatString" "func(0, [Str; Str; Str])")
    ("strPrefixOf" "func(0, [Str; Str; bool])")
    ("strSuffixOf" "func(0, [Str; Str; bool])")
    ("strContains" "func(0, [Str; Str; bool])")
    ("bool_to_int" "func(0, [bool; int])")))

(defvar *theory-sorts* nil)

(defun theory-sorts ()
  (or *theory-sorts*
      (setf *theory-sorts*
            (mapcar (lambda (p) (cons (first p) (parse-sort-string (second p))))
                    *theory-symbols*))))

(defun data-type-sort (d)
  (apply #'tc-sort (data-name d) (loop for i below (data-arity d) collect (list :var i))))

(defun add-data-decl (env d)
  (let ((n (data-arity d)) (ty (data-type-sort d)))
    (setf (gethash (data-name d) (sym-env-data env)) d)
    (dolist (c (data-ctors d))
      (let ((cname (first c)) (fields (second c)))
        (setf (gethash cname (sym-env-sorts env))
              (if (or fields (plusp n))
                  (list :func n (mapcar #'cdr fields) ty)
                  ty)
              (gethash cname (sym-env-kinds env)) :ctor
              (gethash cname (sym-env-ctor-of env)) (cons d c))
        (let ((tester (concatenate 'string "is$" cname)))
          (setf (gethash tester (sym-env-sorts env)) (list :func n (list ty) :bool)
                (gethash tester (sym-env-kinds env)) :tester
                (gethash tester (sym-env-ctor-of env)) (cons d c)))
        (dolist (f fields)
          (setf (gethash (car f) (sym-env-sorts env)) (list :func n (list ty) (cdr f))
                (gethash (car f) (sym-env-kinds env)) :selector
                (gethash (car f) (sym-env-ctor-of env)) (cons d c)))))))

(defun make-global-env (&key consts data allow-ho)
  "A SYM-ENV with the theory symbols, CONSTS ((name . sort) ..) and the
constructors, selectors and testers of the DATA declarations."
  (let ((env (make-sym-env :allow-ho allow-ho)))
    (dolist (p (theory-sorts))
      (setf (gethash (car p) (sym-env-sorts env)) (cdr p)
            (gethash (car p) (sym-env-kinds env)) :theory))
    (setf (gethash "Set_card" (sym-env-kinds env)) :uninterp)
    (dolist (c consts)
      ;; theory symbols win over constants of the same name (as upstream's
      ;; sanitizer drops such constants)
      (unless (eq (gethash (car c) (sym-env-kinds env)) :theory)
        (setf (gethash (car c) (sym-env-sorts env)) (cdr c)
              (gethash (car c) (sym-env-kinds env)) :uninterp)))
    (dolist (d data) (add-data-decl env d))
    env))

(defun resolve-sort-binders (locals genv)
  "Upstream's symbolSorts: a sort (:obj a) where a is itself a bound
symbol stands for that symbol's sort (fq files declare `bind 0 alpha : {v
: num | true}' and then use alpha as a sort)."
  (flet ((lookup (a)
           (let ((p (assoc a locals :test #'string=)))
             (cond (p (cdr p))
                   ((and genv (global-sort genv a)))
                   (t nil)))))
    (mapcar (lambda (p)
              (cons (car p)
                    (map-sort (lambda (x)
                                (if (and (consp x) (eq (car x) :obj))
                                    (let ((r (lookup (second x))))
                                      (if (and r (not (and (consp r) (eq (car r) :obj)))
                                               (not (func-sort-p r)))
                                          r x))
                                    x))
                              (cdr p))))
            locals)))

(defun global-sort (env x) (gethash x (sym-env-sorts env)))
(defun global-kind (env x) (gethash x (sym-env-kinds env)))

;;; ------------------------------------------------------------------
;;; Meta-variables and unification

(defvar *uv-binding* nil)
(defvar *uv-kind* nil)
(defvar *uv-counter* 0)

(defun fresh-uv (&optional (kind :any))
  (let ((n (incf *uv-counter*)))
    (setf (gethash n *uv-kind*) kind)
    (list :uv n)))

(defun uv-p (s) (and (consp s) (eq (car s) :uv)))

(defun walk-sort (s)
  (loop while (and (uv-p s) (gethash (second s) *uv-binding*))
        do (setf s (gethash (second s) *uv-binding*)))
  s)

(defun resolve-sort (s)
  "S with all bound meta-variables replaced."
  (let ((s (walk-sort s)))
    (if (consp s)
        (case (car s)
          (:func (list :func (second s) (mapcar #'resolve-sort (third s)) (resolve-sort (fourth s))))
          (:tc (list* :tc (second s) (mapcar #'resolve-sort (cddr s))))
          (:sapp (let ((parts (mapcar #'resolve-sort (cdr s))))
                   ;; a constructor head applied further is a constructor sort
                   (if (and (consp (car parts)) (eq (car (car parts)) :tc))
                       (append (car parts) (cdr parts))
                       (cons :sapp parts))))
          (t s))
        s)))

(defun occurs-p (n s)
  (let ((s (walk-sort s)))
    (cond ((uv-p s) (= n (second s)))
          ((consp s) (case (car s)
                       (:func (or (some (lambda (x) (occurs-p n x)) (third s)) (occurs-p n (fourth s))))
                       (:tc (some (lambda (x) (occurs-p n x)) (cddr s)))
                       (:sapp (some (lambda (x) (occurs-p n x)) (cdr s)))
                       (t nil)))
          (t nil))))

(defun numeric-sort-p (s) (member s '(:int :real :num :frac)))

(defun bind-uv (u s)
  (let* ((n (second u)) (kind (gethash n *uv-kind*)) (s (walk-sort s)))
    (cond ((equal u s))
          ((uv-p s)
           (let ((k2 (gethash (second s) *uv-kind*)))
             ;; keep the stronger kind on the variable that survives
             (setf (gethash (second s) *uv-kind*)
                   (cond ((or (eq kind :frac) (eq k2 :frac)) :frac)
                         ((or (eq kind :num) (eq k2 :num)) :num)
                         (t :any)))
             (setf (gethash n *uv-binding*) s)))
          ((occurs-p n s) (sort-fail "occurs check"))
          (t (case kind
               (:num (unless (numeric-sort-p s) (sort-fail "~a is not numeric" (sort->string s))))
               (:frac (unless (member s '(:real :frac)) (sort-fail "~a is not fractional" (sort->string s)))))
             (setf (gethash n *uv-binding*) s)))))

(defun string-sort-p (s)
  (or (eq s :str)
      (equal s '(:tc "[]" (:tc "Char")))
      (equal s '(:tc "Str"))))

(defun unify (a b)
  (let ((a (walk-sort a)) (b (walk-sort b)))
    ;; Str is [Char]: compare as strings, or as lists against list shapes
    (flet ((listy (s) (and (consp s) (or (eq (car s) :sapp)
                                         (and (eq (car s) :tc) (equal (second s) "[]"))))))
      (cond ((and (string-sort-p a) (listy b)) (setf a '(:tc "[]" (:tc "Char"))))
            ((and (string-sort-p b) (listy a)) (setf b '(:tc "[]" (:tc "Char"))))
            (t (when (string-sort-p a) (setf a :str))
               (when (string-sort-p b) (setf b :str)))))
    (cond ((equal a b) t)
          ((uv-p a) (bind-uv a b))
          ((uv-p b) (bind-uv b a))
          ((and (eq a :num) (numeric-sort-p b)) t)
          ((and (eq b :num) (numeric-sort-p a)) t)
          ((and (eq a :frac) (member b '(:real :frac))) t)
          ((and (eq b :frac) (member a '(:real :frac))) t)
          ((and (func-sort-p a) (func-sort-p b))
           (let ((as (third a)) (bs (third b)))
             (unify (car as) (car bs))
             (unify (if (cdr as) (list :func 0 (cdr as) (fourth a)) (fourth a))
                    (if (cdr bs) (list :func 0 (cdr bs) (fourth b)) (fourth b)))))
          ((and (consp a) (consp b) (eq (car a) :tc) (eq (car b) :tc)
                (equal (second a) (second b)) (= (length a) (length b)))
           (mapc #'unify (cddr a) (cddr b)) t)
          ((and (consp a) (eq (car a) :sapp) (consp b) (member (car b) '(:tc :sapp)))
           (unify-app a b))
          ((and (consp b) (eq (car b) :sapp) (consp a) (member (car a) '(:tc :sapp)))
           (unify-app b a))
          (t (sort-fail "cannot unify ~a with ~a" (sort->string a) (sort->string b))))))

(defun unify-app (a b)
  "A = (:sapp h a1 .. ak) against B, a constructor or variable applied to
arguments: match the last k arguments and the head with the rest."
  (let* ((aargs (cddr a))
         (bhead (if (eq (car b) :tc) (list :tc (second b)) (second b)))
         (bargs (if (eq (car b) :tc) (cddr b) (cddr b)))
         (k (length aargs)) (m (length bargs)))
    (when (> k m) (sort-fail "cannot unify ~a with ~a" (sort->string a) (sort->string b)))
    (let ((prefix (subseq bargs 0 (- m k))) (suffix (subseq bargs (- m k))))
      (unify (second a)
             (if (eq (car b) :tc)
                 (append bhead prefix)
                 (if prefix (list* :sapp bhead prefix) bhead)))
      (mapc #'unify aargs suffix)
      t)))

(defun instantiate (s)
  "Replace the bound sort variables of a func(n, ..) sort by fresh
meta-variables; other sorts are returned as they are."
  (if (and (func-sort-p s) (plusp (second s)))
      (let ((fresh (loop for i below (second s) collect (fresh-uv))))
        (labels ((inst (x)
                   (map-sort (lambda (y)
                               (if (and (consp y) (eq (car y) :var) (< (second y) (length fresh)))
                                   (nth (second y) fresh)
                                   y))
                             x)))
          (if (null (third s))
              (inst (fourth s))
              (list :func 0 (mapcar #'inst (third s)) (inst (fourth s))))))
      (if (and (func-sort-p s) (null (third s))) (fourth s) s)))

;;; ------------------------------------------------------------------
;;; Elaborated trees
;;;
;;; An elaborated node is a TE struct: KIND is one of :int :real :str :lit
;;; :var :app :neg :arith :ite :and :or :not :imp :iff :rel :true :false
;;; :quant :lam :coerce; SORT its sort; DATA kind-specific (the constant,
;;; the variable name and scope, the operator ..); KIDS the sub-nodes.

(defstruct (te (:constructor make-te (kind sort &optional data kids)))
  kind sort data kids)

(defvar *elab-genv* nil)

(defun lookup-sort (x locals)
  "The sort of variable X and its scope (:local or :global)."
  (let ((p (assoc x locals :test #'string=)))
    (cond (p (values (cdr p) :local))
          ((global-sort *elab-genv* x) (values (global-sort *elab-genv* x) :global))
          (t (sort-fail "unbound symbol ~a" x)))))

(defun infer (e locals)
  "Infer the sort of expression E; return its elaborated node."
  (cond
    ((integerp e) (make-te :int (fresh-uv :num) e))
    ((stringp e)
     (multiple-value-bind (s scope) (lookup-sort e locals)
       (make-te :var (instantiate s) (cons e scope))))
    ((eq e :true) (make-te :true :bool))
    ((eq e :false) (make-te :false :bool))
    ((eq e :hole) (sort-fail "hole in a refinement"))
    ((atom e) (sort-fail "unexpected ~s" e))
    (t
     (case (car e)
       (:real (make-te :real (fresh-uv :frac) (second e)))
       (:str (make-te :str :str (second e)))
       (:lit (make-te :lit (third e) (second e)))
       (:app (let* ((head (infer (second e) locals))
                    (args (mapcar (lambda (a) (infer a locals)) (cddr e)))
                    (s (te-sort head)))
               (dolist (a args)
                 (setf s (apply-sort s (te-sort a))))
               (make-te :app s nil (cons head args))))
       (:neg (let ((a (infer (second e) locals)))
               (unify (te-sort a) (fresh-uv :num))
               (make-te :neg (te-sort a) nil (list a))))
       ((:+ :- :* :/ :mod)
        (let ((a (infer (second e) locals)) (b (infer (third e) locals)))
          (unify (te-sort a) (te-sort b))
          (unify (te-sort a) (fresh-uv (if (eq (car e) :mod) :any :num)))
          (when (eq (car e) :mod) (unify (te-sort a) :int))
          (make-te :arith (te-sort a) (car e) (list a b))))
       (:ite (let ((c (check-bool (second e) locals))
                   (a (infer (third e) locals)) (b (infer (fourth e) locals)))
               (unify (te-sort a) (te-sort b))
               (make-te :ite (te-sort a) nil (list c a b))))
       (:cast (let ((a (infer (second e) locals)))
                (unify (te-sort a) (third e))
                a))
       ((:and :or) (make-te (car e) :bool nil
                            (mapcar (lambda (p) (check-bool p locals)) (cdr e))))
       (:not (make-te :not :bool nil (list (check-bool (second e) locals))))
       (:=> (make-te :imp :bool nil (list (check-bool (second e) locals)
                                           (check-bool (third e) locals))))
       (:<=> (make-te :iff :bool nil (list (check-bool (second e) locals)
                                            (check-bool (third e) locals))))
       ((:= :/= :< :<= :> :>= :~~ :!~)
        (let ((a (infer (second e) locals)) (b (infer (third e) locals)))
          (unless (member (car e) '(:~~ :!~))
            (unify (te-sort a) (te-sort b)))
          (make-te :rel :bool (car e) (list a b))))
       (:kvar (sort-fail "unsolved kvar $~a" (second e)))
       ((:exists :forall)
        (let ((locals2 (append (second e) locals)))
          (make-te :quant :bool (list (car e) (second e))
                   (list (check-bool (third e) locals2)))))
       (:lam (let* ((b (second e))
                    (body (infer (third e) (cons b locals))))
               (make-te :lam (list :func 0 (list (cdr b)) (te-sort body)) b (list body))))
       (:coerce (let ((a (infer (fourth e) locals)))
                  (unify (te-sort a) (second e))
                  (make-te :coerce (third e) (list (second e) (third e)) (list a))))
       (t (sort-fail "unknown expression ~s" e))))))

(defun check-bool (e locals)
  (let ((te (infer e locals)))
    (unify (te-sort te) :bool)
    te))

(defun apply-sort (fs arg)
  "The sort of applying a function of sort FS to an argument of sort ARG."
  (let ((fs (walk-sort fs)))
    (cond ((func-sort-p fs)
           (let ((as (third fs)))
             (unify (car as) arg)
             (if (cdr as) (list :func 0 (cdr as) (fourth fs)) (fourth fs))))
          ((uv-p fs)
           (let ((r (fresh-uv)))
             (unify fs (list :func 0 (list arg) r))
             r))
          (t (sort-fail "applying a non-function of sort ~a" (sort->string fs))))))

(defun finalize-sort (s)
  "Resolve S; meta-variables left over default by kind (num: int,
frac: real, others: an anonymous uninterpreted sort)."
  (map-sort (lambda (x)
              (if (uv-p x)
                  (let ((w (walk-sort x)))
                    (if (uv-p w)
                        (case (gethash (second w) *uv-kind*)
                          (:num :int) (:frac :real) (t (list :obj "?")))
                        (finalize-sort w)))
                  x))
            (resolve-sort s)))

(defun finalize-te (te)
  (setf (te-sort te) (finalize-sort (te-sort te)))
  (mapc #'finalize-te (te-kids te))
  te)

(defmacro with-elaboration ((genv) &body body)
  `(let ((*elab-genv* ,genv)
         (*uv-binding* (make-hash-table))
         (*uv-kind* (make-hash-table))
         (*uv-counter* 0))
     ,@body))

(defun elaborate (e locals genv &key (expect :bool))
  "Sort-check E in LOCALS ((name . sort) ..) and GENV; return its
elaborated tree (sorts resolved).  EXPECT is the required sort, or NIL."
  (with-elaboration (genv)
    (let ((te (infer e locals)))
      (when expect (unify (te-sort te) expect))
      (finalize-te te))))

(defun well-sorted-p (e locals genv)
  (handler-case (progn (elaborate e locals genv) t)
    (sort-error () nil)))
