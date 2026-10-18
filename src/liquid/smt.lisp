;;;; smt.lisp -- SMT-LIB2 encoding of the refinement logic.
;;;;
;;;; After liquid-fixpoint's src/Language/Fixpoint/Smt/Serialize.hs and
;;;; Smt/Theories.hs (commit 0b924442ce26a8f270bffac18ba6295bc7411646),
;;;; for Z3:
;;;;
;;;;  - sorts erase to SMT sorts as in sortSmtSort: int -> Int, real ->
;;;;    Real, bool -> Bool, Str -> String, sets -> (Array a Bool), maps ->
;;;;    (Array k v), bags -> (Array a Int), declared data types -> SMT
;;;;    datatypes, and everything else (type variables, uninterpreted
;;;;    sorts, function sorts) -> Int;
;;;;  - a polymorphic uninterpreted function gets one SMT declaration per
;;;;    erased signature it is used at (upstream's symbolAtName);
;;;;  - applications of variables, partial applications and functions used
;;;;    as values go through uninterpreted apply@A@R functions, as in
;;;;    upstream's defunctionalized encoding (lambdas become fresh
;;;;    uninterpreted constants: sound, not complete);
;;;;  - Set_* / Map_* / Bag_* use Z3's array theory (upstream's
;;;;    elabFSetBagZ3), strings use Z3's string theory.
;;;;
;;;; FORMULA->SMT2 turns a predicate into an SMT-LIB2 term and the list of
;;;; declarations it needs; an SMT-CTX remembers the names chosen for
;;;; global symbols so that repeated queries agree.

(in-package :yale-liquid)

(defstruct smt-ctx
  genv                                      ; the SYM-ENV
  (names (make-hash-table :test 'equal))   ; (symbol . signature) -> SMT name
  (used (make-hash-table :test 'equal))    ; SMT names in use
  (counter 0))

;;; ------------------------------------------------------------------
;;; Names

(defparameter *smt-reserved*
  '("and" "or" "not" "=>" "ite" "=" "distinct" "true" "false" "let" "forall"
    "exists" "as" "par" "_" "!" "select" "store" "const" "div" "mod" "abs"
    "Int" "Real" "Bool" "Array" "String" "assert" "declare-fun" "declare-const"
    "define-fun" "push" "pop" "check-sat" "map" "to_real" "to_int" "is_int"
    "union" "intersection" "setminus" "subset" "complement" "bv" "rem"
    "NUMERAL" "DECIMAL" "STRING" "is" "match")
  "SMT-LIB and Z3 names that user symbols must not clash with.")

(defun simple-smt-symbol-p (s)
  (and (plusp (length s))
       (not (digit-char-p (char s 0)))
       (every (lambda (c) (or (and (alphanumericp c) (< (char-code c) 128))
                              (find c "_.~!@$%^&*+-<>?/")))
              s)))

(defun smt-symbol (name)
  "NAME as an SMT-LIB symbol: kept when it is a simple symbol and not
reserved, otherwise quoted |..| (and suffixed when reserved)."
  (cond ((member name *smt-reserved* :test #'string=)
         (format nil "|~a$|" name))
        ((simple-smt-symbol-p name) name)
        (t (format nil "|~a|" (substitute #\_ #\| (substitute #\_ #\\ name))))))

(defun ctx-name (ctx key base)
  "The SMT name for KEY, choosing a fresh one derived from BASE once."
  (or (gethash key (smt-ctx-names ctx))
      (let* ((cand (smt-symbol base))
             (name (if (gethash cand (smt-ctx-used ctx))
                       (smt-symbol (format nil "~a@~d" base (incf (smt-ctx-counter ctx))))
                       cand)))
        (setf (gethash cand (smt-ctx-used ctx)) t
              (gethash name (smt-ctx-used ctx)) t
              (gethash key (smt-ctx-names ctx)) name))))

;;; ------------------------------------------------------------------
;;; Sorts

(defun data-decl-of (ctx name)
  (and ctx (gethash name (sym-env-data (smt-ctx-genv ctx)))))

(defun smt-sort (s ctx &optional tyvars)
  "The SMT-LIB sort of sort S.  TYVARS maps (:var i) to Ti inside datatype
declarations."
  (cond ((eq s :int) "Int")
        ((string-sort-p s) "String")
        ((eq s :num) "Int")
        ((eq s :real) "Real")
        ((eq s :frac) "Real")
        ((eq s :bool) "Bool")
        ((eq s :str) "String")
        ((and (consp s) (eq (car s) :var) tyvars (< (second s) tyvars))
         (format nil "T~d" (second s)))
        ((and (consp s) (eq (car s) :tc))
         (let ((name (second s)) (args (cddr s)))
           (cond ((and (string= name "Set_Set") (= (length args) 1))
                  (format nil "(Array ~a Bool)" (smt-sort (first args) ctx tyvars)))
                 ((and (string= name "Bag_t") (= (length args) 1))
                  (format nil "(Array ~a Int)" (smt-sort (first args) ctx tyvars)))
                 ((and (member name '("Map_t" "Array_t") :test #'string=) (= (length args) 2))
                  (format nil "(Array ~a ~a)" (smt-sort (first args) ctx tyvars)
                          (smt-sort (second args) ctx tyvars)))
                 ((string= name "Bool") "Bool")
                 ((data-decl-of ctx name)
                  (let* ((d (data-decl-of ctx name)) (n (data-arity d))
                         (as (append (subseq args 0 (min n (length args)))
                                     (make-list (max 0 (- n (length args))) :initial-element :int))))
                    (if (zerop n)
                        (smt-symbol name)
                        (format nil "(~a~{ ~a~})" (smt-symbol name)
                                (mapcar (lambda (a) (smt-sort a ctx tyvars)) as)))))
                 (t "Int"))))
        (t "Int")))

;;; ------------------------------------------------------------------
;;; Declarations needed by a formula

(defvar *needed-decls* nil
  "Declarations collected while encoding: (NAME ARG-SORTS RESULT-SORT).")
(defvar *encode-ctx* nil)

(defun need-decl (name args result)
  (pushnew (list name args result) *needed-decls* :test #'equal))

(defun decl->smt2 (d)
  (destructuring-bind (name args result) d
    (if args
        (format nil "(declare-fun ~a (~{~a~^ ~}) ~a)" name args result)
        (format nil "(declare-const ~a ~a)" name result))))

(defun global-instance (name inst-sort nargs)
  "The SMT name of global uninterpreted NAME applied to NARGS arguments at
instance sort INST-SORT (a resolved func sort, or a constant's sort)."
  (let* ((ctx *encode-ctx*)
         (args (if (func-sort-p inst-sort) (subseq (third inst-sort) 0 nargs) '()))
         (res (if (func-sort-p inst-sort)
                  (let ((rest (nthcdr nargs (third inst-sort))))
                    (if rest (list :func 0 rest (fourth inst-sort)) (fourth inst-sort)))
                  inst-sort))
         (sargs (mapcar (lambda (a) (smt-sort a ctx)) args))
         (sres (smt-sort res ctx))
         (smt (ctx-name ctx (list name sargs sres) name)))
    (need-decl smt sargs sres)
    smt))

(defun apply-name (arg-smt res-smt)
  (let ((n (ctx-name *encode-ctx* (list :apply arg-smt res-smt)
                     (format nil "apply@~a@~a" (remove #\Space arg-smt) (remove #\Space res-smt)))))
    (need-decl n (list "Int" arg-smt) res-smt)
    n))

;;; ------------------------------------------------------------------
;;; Terms

(defvar *smt-locals* nil "Alist: local variable name -> SMT name.")

(defun smt-local-name (x)
  (or (cdr (assoc x *smt-locals* :test #'string=))
      (error "no SMT name for local ~a" x)))

(defun smt-int (n) (if (minusp n) (format nil "(- ~d)" (- n)) (format nil "~d" n)))

(defun smt-real (r)
  (let ((a (abs r)))
    (let ((s (if (= (denominator a) 1)
                 (format nil "~d.0" a)
                 (let ((dec (real-string a)))
                   (if (= (rational (read-from-string-safe dec)) a)
                       dec
                       (format nil "(/ ~d.0 ~d.0)" (numerator a) (denominator a)))))))
      (if (minusp r) (format nil "(- ~a)" s) s))))

(defun read-from-string-safe (s)
  ;; parse "123.456" exactly
  (let* ((dot (position #\. s))
         (int (parse-integer s :end dot))
         (frac (subseq s (1+ dot))))
    (+ int (/ (parse-integer frac) (expt 10 (length frac))))))

(defun smt-string-literal (s)
  (format nil "\"~a\"" (with-output-to-string (o)
                         (loop for c across s
                               do (if (char= c #\") (write-string "\"\"" o) (write-char c o))))))

(defun real-sort-p (s) (member s '(:real :frac)))

(defun enc (te)
  (let ((s (te-sort te)) (kids (te-kids te)) (data (te-data te)))
    (ecase (te-kind te)
      (:int (if (real-sort-p s) (smt-real data) (smt-int data)))
      (:real (smt-real data))
      (:str (smt-string-literal data))
      (:lit (if (eq s :str) (smt-string-literal data) data))
      (:true "true")
      (:false "false")
      (:var (enc-var te))
      (:app (enc-app te))
      (:neg (format nil "(- ~a)" (enc (first kids))))
      (:arith (let ((a (enc (first kids))) (b (enc (second kids))))
                (format nil "(~a ~a ~a)"
                        (ecase data
                          (:+ "+") (:- "-") (:* "*") (:mod "mod")
                          (:/ (if (real-sort-p s) "/" "div")))
                        a b)))
      (:ite (format nil "(ite ~a ~a ~a)" (enc (first kids)) (enc (second kids)) (enc (third kids))))
      (:and (if kids (format nil "(and~{ ~a~})" (mapcar #'enc kids)) "true"))
      (:or (if kids (format nil "(or~{ ~a~})" (mapcar #'enc kids)) "false"))
      (:not (format nil "(not ~a)" (enc (first kids))))
      (:imp (format nil "(=> ~a ~a)" (enc (first kids)) (enc (second kids))))
      (:iff (format nil "(= ~a ~a)" (enc (first kids)) (enc (second kids))))
      (:rel (enc-rel data (first kids) (second kids)))
      (:quant (let* ((binds (second data))
                     (names (mapcar (lambda (b) (cons (car b) (smt-symbol (format nil "~a@q~d" (car b) (incf (smt-ctx-counter *encode-ctx*))))))
                                    binds))
                     (*smt-locals* (append names *smt-locals*)))
                (format nil "(~a (~{~a~^ ~}) ~a)" (if (eq (first data) :exists) "exists" "forall")
                        (mapcar (lambda (b n) (format nil "(~a ~a)" (cdr n) (smt-sort (cdr b) *encode-ctx*)))
                                binds names)
                        (enc (first kids)))))
      (:lam (let ((n (smt-symbol (format nil "lam@~d" (incf (smt-ctx-counter *encode-ctx*))))))
              (need-decl n '() "Int")
              n))
      (:coerce (let* ((from (smt-sort (first data) *encode-ctx*))
                      (to (smt-sort (second data) *encode-ctx*)))
                 (if (string= from to)
                     (enc (first kids))
                     (let ((n (ctx-name *encode-ctx* (list :coerce from to)
                                        (format nil "coerce@~a@~a" (remove #\Space from) (remove #\Space to)))))
                       (need-decl n (list from) to)
                       (format nil "(~a ~a)" n (enc (first kids))))))))))

(defun enc-rel (op a b)
  (let ((x (enc a)) (y (enc b)))
    (ecase op
      ((:= :~~) (if (string= (smt-sort (te-sort a) *encode-ctx*) (smt-sort (te-sort b) *encode-ctx*))
                    (format nil "(= ~a ~a)" x y)
                    "false"))
      ((:/= :!~) (if (string= (smt-sort (te-sort a) *encode-ctx*) (smt-sort (te-sort b) *encode-ctx*))
                     (format nil "(not (= ~a ~a))" x y)
                     "true"))
      (:< (format nil "(< ~a ~a)" x y))
      (:<= (format nil "(<= ~a ~a)" x y))
      (:> (format nil "(> ~a ~a)" x y))
      (:>= (format nil "(>= ~a ~a)" x y)))))

(defun global-kind* (name) (global-kind (smt-ctx-genv *encode-ctx*) name))
(defun global-sort* (name) (global-sort (smt-ctx-genv *encode-ctx*) name))

(defun declared-arity (name)
  (let ((s (global-sort* name)))
    (if (func-sort-p s) (length (third s)) 0)))

(defun enc-var (te)
  "A variable not in head position."
  (destructuring-bind (name . scope) (te-data te)
    (if (eq scope :local)
        (smt-local-name name)
        (let ((kind (global-kind* name)))
          (cond ((and (lit-symbol-p name) (eq (te-sort te) :str))
                 ;; upstream's literal symbols lit$abc stand for "abc"
                 (smt-string-literal (subseq name 4)))
                ((and (eq kind :ctor) (zerop (declared-arity name)))
                 (enc-ctor-head name (te-sort te)))
                ((zerop (declared-arity name))
                 (global-instance name (te-sort te) 0))
                (t
                 ;; a function used as a value: an uninterpreted constant
                 (let ((n (ctx-name *encode-ctx* (list :fn name) (format nil "~a@fn" name))))
                   (need-decl n '() "Int")
                   n)))))))

(defun enc-ctor-head (name result-sort)
  (let ((d (car (gethash name (sym-env-ctor-of (smt-ctx-genv *encode-ctx*))))))
    (if (zerop (data-arity d))
        (smt-symbol name)
        (format nil "(as ~a ~a)" (smt-symbol name) (smt-sort result-sort *encode-ctx*)))))

(defun result-after (sort n)
  "The sort of a function of SORT applied to N arguments."
  (if (and (func-sort-p sort) (plusp n))
      (let ((rest (nthcdr n (third sort))))
        (if rest (list :func 0 rest (fourth sort)) (fourth sort)))
      sort))

(defun enc-apply-chain (fn-smt fn-sort args)
  "Apply an encoded function value FN-SMT of sort FN-SORT to the elaborated
ARGS one at a time through apply@A@R."
  (let ((acc fn-smt) (s fn-sort))
    (dolist (a args acc)
      (let* ((r (result-after s 1))
             (an (apply-name (smt-sort (te-sort a) *encode-ctx*) (smt-sort r *encode-ctx*))))
        (setf acc (format nil "(~a ~a ~a)" an acc (enc a))
              s r)))))

(defun theory-app (name args result-sort)
  "Z3 encodings of the set/map/bag/string theory symbols (elabFSetBagZ3)."
  (let ((e (mapcar #'enc args))
        (rs (smt-sort result-sort *encode-ctx*)))
    (flet ((elt-set-sort (te) (smt-sort (te-sort te) *encode-ctx*))
           (const (sort v) (format nil "((as const ~a) ~a)" sort v)))
      (destructuring-bind (&optional e1 e2 e3) e
        (cond
          ((string= name "Set_empty") (const rs "false"))
          ((string= name "Set_emp") (format nil "(= ~a ~a)" e1 (const (elt-set-sort (first args)) "false")))
          ((string= name "Set_sng") (format nil "(store ~a ~a true)" (const rs "false") e1))
          ((string= name "Set_add") (format nil "(store ~a ~a true)" e2 e1))
          ((string= name "Set_mem") (format nil "(select ~a ~a)" e2 e1))
          ((string= name "Set_cup") (format nil "((_ map or) ~a ~a)" e1 e2))
          ((string= name "Set_cap") (format nil "((_ map and) ~a ~a)" e1 e2))
          ((string= name "Set_dif") (format nil "((_ map and) ~a ((_ map not) ~a))" e1 e2))
          ((string= name "Set_com") (format nil "((_ map not) ~a)" e1))
          ((string= name "Set_sub")
           (format nil "(= ~a ((_ map =>) ~a ~a))" (const (elt-set-sort (first args)) "true") e1 e2))
          ((string= name "Map_default") (const rs e1))
          ((string= name "Map_select") (format nil "(select ~a ~a)" e1 e2))
          ((string= name "Map_store") (format nil "(store ~a ~a ~a)" e1 e2 e3))
          ((string= name "Bag_empty") (const rs "0"))
          ((string= name "Bag_sng") (format nil "(store ~a ~a ~a)" (const rs "0") e1 e2))
          ((string= name "Bag_count") (format nil "(select ~a ~a)" e2 e1))
          ((string= name "Bag_union") (format nil "((_ map (+ (Int Int) Int)) ~a ~a)" e1 e2))
          ((string= name "Bag_union_max")
           (format nil "((_ map (ite (Bool Int Int) Int)) ((_ map (> (Int Int) Bool)) ~a ~a) ~a ~a)" e1 e2 e1 e2))
          ((string= name "Bag_inter_min")
           (format nil "((_ map (ite (Bool Int Int) Int)) ((_ map (<= (Int Int) Bool)) ~a ~a) ~a ~a)" e1 e2 e1 e2))
          ((string= name "Bag_sub")
           (format nil "(= ~a ((_ map (<= (Int Int) Bool)) ~a ~a))"
                   (const (format nil "(Array ~a Bool)"
                                  (let ((s (te-sort (first args))))
                                    (if (and (consp s) (eq (car s) :tc)) (smt-sort (third s) *encode-ctx*) "Int")))
                          "true")
                   e1 e2))
          ((string= name "strLen") (format nil "(str.len ~a)" e1))
          ((string= name "subString") (format nil "(str.substr ~a ~a ~a)" e1 e2 e3))
          ((string= name "concatString") (format nil "(str.++ ~a ~a)" e1 e2))
          ((string= name "strPrefixOf") (format nil "(str.prefixof ~a ~a)" e1 e2))
          ((string= name "strSuffixOf") (format nil "(str.suffixof ~a ~a)" e1 e2))
          ((string= name "strContains") (format nil "(str.contains ~a ~a)" e1 e2))
          ((string= name "bool_to_int") (format nil "(ite ~a 1 0)" e1))
          (t (error "no encoding for theory symbol ~a" name)))))))

(defun recognizer-name (ctor)
  "Z3's recognizer is-C for constructor C (upstream's testSymbols use the
same raw name; (_ is C) is ambiguous for polymorphic datatypes in Z3)."
  (smt-symbol (concatenate 'string "is-" (string-trim "|" (smt-symbol ctor)))))

(defun enc-app (te)
  (let* ((head (first (te-kids te)))
         (args (rest (te-kids te))))
    (if (and (eq (te-kind head) :var) (eq (cdr (te-data head)) :global))
        (let* ((name (car (te-data head)))
               (kind (global-kind* name))
               (k (declared-arity name))
               (direct (subseq args 0 (min k (length args))))
               (extra (nthcdr (length direct) args))
               (hsort (te-sort head)))
          (if (or (zerop k) (< (length args) k))
              ;; constants applied, or partial application: apply chain
              (enc-apply-chain (enc head) hsort args)
              (let ((call
                      (case kind
                        (:theory (theory-app name direct (result-after hsort k)))
                        (:ctor (format nil "(~a~{ ~a~})" (enc-ctor-head name (result-after hsort k))
                                       (mapcar #'enc direct)))
                        (:tester (format nil "(~a ~a)"
                                         (recognizer-name
                                          (first (cdr (gethash name (sym-env-ctor-of (smt-ctx-genv *encode-ctx*))))))
                                         (enc (first direct))))
                        (:selector (format nil "(~a ~a)" (smt-symbol name) (enc (first direct))))
                        (t (format nil "(~a~{ ~a~})" (global-instance name hsort k)
                                   (mapcar #'enc direct))))))
                (if extra
                    (enc-apply-chain call (result-after hsort k) extra)
                    call))))
        (enc-apply-chain (enc head) (te-sort head) args))))

;;; ------------------------------------------------------------------
;;; Entry points

(defun formula->smt2 (te ctx locals)
  "Encode elaborated TE.  LOCALS maps local variable names to SMT names.
Returns the SMT-LIB2 term and the declarations it needs."
  (let ((*encode-ctx* ctx)
        (*smt-locals* locals)
        (*needed-decls* '()))
    (let ((s (enc te)))
      (values s (reverse *needed-decls*)))))

(defun datatype-decls (ctx)
  "The declare-datatypes command for the data declarations of CTX, or NIL."
  (let ((ds (loop for d being the hash-values of (sym-env-data (smt-ctx-genv ctx)) collect d)))
    (when ds
      (setf ds (sort ds #'string< :key #'data-name))
      (format nil "(declare-datatypes (~{~a~^ ~}) (~{~a~^ ~}))"
              (mapcar (lambda (d) (format nil "(~a ~d)" (smt-symbol (data-name d)) (data-arity d))) ds)
              (mapcar (lambda (d)
                        (let ((ctors (format nil "(~{~a~^ ~})"
                                             (mapcar (lambda (c)
                                                       (format nil "(~a~{ ~a~})" (smt-symbol (first c))
                                                               (mapcar (lambda (f)
                                                                         (format nil "(~a ~a)" (smt-symbol (car f))
                                                                                 (smt-sort (cdr f) ctx (data-arity d))))
                                                                       (second c))))
                                                     (data-ctors d)))))
                          (if (plusp (data-arity d))
                              (format nil "(par (~{T~d~^ ~}) ~a)"
                                      (loop for i below (data-arity d) collect i) ctors)
                              ctors)))
                      ds)))))
