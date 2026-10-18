;;;; spec.lisp -- LiquidHaskell's {-@ ... @-} specification language.
;;;;
;;;; A port of liquidhaskell-boot/src/Language/Haskell/Liquid/Parse.hs
;;;; (https://github.com/ucsd-progsys/liquidhaskell, commit
;;;; aae574e92629d33c88269fa733fc12fa85500086): specP and the "bare type"
;;;; grammar (btP, circleP, bbaseP, ..), measures, data declarations,
;;;; aliases, qualifiers and the rest, over the expression and sort grammar
;;;; of expr-parser.lisp, as upstream reuses liquid-fixpoint's.  Upstream
;;;; parses each comment as a layout block of specifications, threading the
;;;; operator fixities from one comment to the next; so does this file.
;;;;
;;;; REFINED TYPES (upstream's BareType = RType BTyCon BTyVar RReft)
;;;;
;;;;   (:var "a" REFT PREDS)              a type variable, refined
;;;;   (:con "T" (ARGS..) (PROPS..) REFT PREDS)
;;;;                                      a type constructor applied: lists
;;;;                                      are "[]", tuples "(,)", "(,,)"..;
;;;;                                      ARGS may contain (:expr E) (type-
;;;;                                      level expressions, e.g. Vec {n});
;;;;                                      PROPS are abstract refinement
;;;;                                      arguments (see below)
;;;;   (:class "C" (ARGS..))              a class constraint (left of =>)
;;;;   (:fun X ARG RESULT)                X:ARG -> RESULT (X is a generated
;;;;                                      "db##n" name when none is written)
;;;;   (:forall ("a" ..) ((P . T) ..) TYPE)
;;;;                                      forall a <p :: T>. TYPE
;;;;   (:app-ty T1 T2 REFT)               a type variable applied (m a)
;;;;   (:hole REFT)                       _ (a type to infer)
;;;;   (:constrained ((X . T) ..) T1 T2 TYPE)
;;;;                                      {x::T |- T1 <: T2} => TYPE
;;;;
;;;; REFT is NIL (true) or (VV . PRED); PREDS is a list of abstract
;;;; refinement applications (:pvar "p" ARGS..).  An abstract refinement
;;;; argument (PROPS) is (:prop ((X . T) ..) TYPE) for <\x -> {v:T | ..}>,
;;;; or (:prop-pred PRED) for <p>.
;;;;
;;;; SPECIFICATIONS (upstream's BPspec)
;;;;
;;;;   (:sig (NAMES..) TYPE METRIC)       f, g :: TYPE / [e1, e2]  (METRIC
;;;;                                      NIL or a list of expressions)
;;;;   (:assume NAME TYPE)  (:assert NAME TYPE)
;;;;   (:assume-reflect NAME AS)          assume reflect f as g
;;;;   (:measure NAME TYPE (EQN..))       EQN = (MEASURE CTOR (ARGS..) BODY)
;;;;                                      with BODY (:expr E), (:pred P) or
;;;;                                      (:reft V P)
;;;;   (:hmeasure NAME)                   measure f (lifted Haskell function)
;;;;   (:class-measure NAME TYPE)  (:instance-measure NAME TYPE (EQN..))
;;;;   (:reflect NAME) (:inline NAME) (:ignore NAME) (:autosize NAME)
;;;;   (:lazy NAME) (:lazyvar NAME) (:rewrite NAME) (:fail NAME) (:ple NAME)
;;;;   (:stratified NAME) (:private-reflect NAME) (:opaque-reflect NAME)
;;;;   (:rewrite-with NAME (NAMES..))
;;;;   (:define NAME (ARGS..) EXPR)
;;;;   (:data DECL) (:newtype DECL)       DECL = (:decl NAME (TYVARS..)
;;;;                                      (PVARS..) (CTOR..) SIZE PROP-TYPE),
;;;;                                      CTOR = (NAME ((FIELD . TYPE) ..)
;;;;                                      RESULT-TYPE-OR-NIL)
;;;;   (:data-variance NAME (VARIANCE..)) (:data-size (TYPES..) NAME)
;;;;   (:type-alias NAME (TYVARS..) (VALUE-ARGS..) TYPE)
;;;;   (:pred-alias NAME (ARGS..) EXPR)   predicate / expression aliases
;;;;   (:invariant TYPE)  (:using TYPE ALIAS-TYPE)
;;;;   (:embed NAME SORT WITH-ARGS-P)
;;;;   (:qualif FQ-QUAL)                  as in .fq files
;;;;   (:fixity ASSOC PREC OP)
;;;;   (:bound NAME (TYVARS..) ((X . T)..) ((X . T)..) PRED)
;;;;   (:class SUPERS NAME (TYVARS..) ((NAME . TYPE) ..))
;;;;   (:instance SUPERS NAME (ARGS..) ((NAME ASSUMED-P TYPE) ..))
;;;;   (:relational F G TF TG ASSUMPTION CONCLUSION)
;;;;   (:pragma "--option")               LIQUID "--option"
;;;;   (:include "path")                  include <path> (legacy .spec files)

(in-package :yale-liquid)

;;; ------------------------------------------------------------------
;;; Identifiers (Parse.hs, "Identifiers")

(defun haskell-op-char-p (c) (find c ":!#$%&*+./<=>?@\\^|~-"))
(defun haskell-op-start-char-p (c) (find c "!#$%&*+./<=>?@\\^|~-"))

(defun ty-var-id ()
  (lexeme (cond-id-raw #'lower-or-underscore-p #'alphanumericp #'not-reserved-p "type variable")))

(defun alias-id ()
  (lexeme (cond-id-raw #'letter-or-underscore-p #'alphanumericp (constantly t) "alias parameter")))

(defun binder-id ()
  (lexeme (cond-id-raw (lambda (c) (or (alpha-char-p c) (char= c #\_) (haskell-op-start-char-p c)))
                       (lambda (c) (or (alphanumericp c) (haskell-op-start-char-p c) (find c "_'")))
                       (constantly t) "binder")))

(defun infix-binder-id ()
  (lexeme (cond-id-raw (lambda (c) (or (alpha-char-p c) (char= c #\_) (haskell-op-char-p c)))
                       (lambda (c) (or (alphanumericp c) (haskell-op-char-p c) (find c "_'")))
                       (constantly t) "operator")))

(defun binder ()
  "Parse.hs binderP: (op) or a name (operators allowed unparenthesised)."
  (alt (format nil "~a" (parens (infix-binder-id)))
       (binder-id)))

(defun infix-id ()
  (lexeme (cond-id-raw #'haskell-op-char-p #'haskell-op-char-p
                       (lambda (s) (string/= s "::")) "operator")))

(defun infix-cond-id ()
  (lexeme (cond-id-raw (lambda (c) (char= c #\:)) #'haskell-op-char-p
                       (lambda (s) (string/= s "::")) "constructor operator")))

(defun upper-id* ()
  "Parse.hs upperIdR': an upper-case name with letters, digits and '."
  (lexeme (cond-id-raw #'upper-case-p (lambda (c) (or (alphanumericp c) (char= c #\')))
                       (constantly t) "upper-case identifier")))

(defun data-con-name ()
  "Parse.hs dataConNameP."
  (alt (upper-id)
       (parens (lexeme (let ((start *pos*))
                         (loop while (and (peek) (not (find (peek) "(,) ")) (graphic-char-p (peek)))
                               do (incf *pos*))
                         (when (= start *pos*) (pfail "constructor"))
                         (subseq *src* start *pos*))))))

(defun dummy-bind ()
  (format nil "db##~d" (fresh-int)))

(defun infix-symbol ()
  "One of the infix operators of the current fixity table, as a name."
  ;; upstream's locInfixSymbolP: only operators declared with infix/infixl/
  ;; infixr in the specifications, not the built-in ones
  (let ((ops (remove-duplicates (mapcar #'second (remove-if-not (lambda (f) (and (eq (third f) :infix)
                                                                                  (eq (sixth f) :user)))
                                                                *fixities*))
                                :test #'string= :from-end t)))
    (dolist (o ops (pfail "infix operator"))
      (when (succeeds (reserved o)) (return o)))))

;;; ------------------------------------------------------------------
;;; Refined types (Parse.hs btP .. bareAtomP)

(defun true-reft () nil)

(defun with-reft (ty reft)
  "Attach REFT (VV . PRED) to the head of TY (upstream's strengthen)."
  (if (null reft)
      ty
      (case (car ty)
        (:var (list :var (second ty) (meet-reft (third ty) reft) (fourth ty)))
        (:con (list :con (second ty) (third ty) (fourth ty) (meet-reft (fifth ty) reft) (sixth ty)))
        (:app-ty (list :app-ty (second ty) (third ty) (meet-reft (fourth ty) reft)))
        (:hole (list :hole (meet-reft (second ty) reft)))
        (t ty))))

(defun meet-reft (r1 r2)
  (cond ((null r1) r2)
        ((null r2) r1)
        ((equal (car r1) (car r2)) (cons (car r1) (pred-and (cdr r1) (cdr r2))))
        (t (cons (car r1) (pred-and (cdr r1) (subst1 (cdr r2) (car r2) (car r1)))))))

(defun with-preds (ty preds)
  (if (null preds) ty
      (case (car ty)
        (:var (list :var (second ty) (third ty) (append (fourth ty) preds)))
        (:con (list :con (second ty) (third ty) (fourth ty) (fifth ty) (append (sixth ty) preds)))
        (t ty))))

(defun bare-type ()
  "Parse.hs bareTypeP."
  (cdr (bt)))

;; A "parameter component" is (SCOPE . TYPE), SCOPE NIL (no symbol) or
;; (:implicit . x) / (:explicit . x).

(defun bt ()
  (let ((c (comp)))
    (if (null (car c))
        c
        (parse-fun c (cdr (car c))))))

(defun parse-fun (c sym)
  (alt (progn (reserved-op "->")
              (let ((t2 (cdr (bt))))
                (cons (car c) (list :fun sym (cdr c) t2))))
       (progn (reserved-op "=>")
              (let ((t2 (cdr (bt))))
                (cons (car c)
                      (reduce (lambda (cls acc) (list :fun "_" cls acc))
                              (get-classes (cdr c)) :from-end t :initial-value t2))))
       (let* ((op (infix-symbol))
              (t2 (cdr (bt))))
         (cons (car c) (list :con op (list (cdr c) t2) '() nil '())))
       c))

(defun get-classes (ty)
  (if (eq (car ty) :con)
      (if (tuple-name-p (second ty))
          (mapcan #'get-classes (copy-list (third ty)))
          (list (list :class (second ty) (third ty))))
      (list ty)))

(defun tuple-name-p (n)
  (and (> (length n) 1) (char= (char n 0) #\() (every (lambda (c) (find c "(,)")) n)
       (find #\, n)))

(defun comp ()
  (alt (circle) (parens (bt))))

(defun circle ()
  (alt (progn (reserved "forall") (cons nil (bare-all)))
       (hole-pc)
       (named-circle)
       (bare-type-braces)
       (unnamed-circle)
       (angles-circle)
       (cons nil (funcall (bbase) nil))))

(defun angles-circle ()
  (angles (let* ((c (parens (bt)))
                 (p (mono-predicate)))
            (cons (car c) (with-preds (cdr c) p)))))

(defun hole-p ()
  (reserved "_")
  (list :hole nil))

(defun hole-pc ()
  (let* ((h (hole-p)) (b (dummy-bind)))
    (cons (cons :implicit b) h)))

(defun named-circle ()
  (let ((lb (lower-id)))
    (alt (progn (reserved-op ":")
                (cons (cons :explicit lb) (bare-arg lb)))
         (let ((b (dummy-bind)))
           (cons (cons :implicit b) (funcall (lower-id-tail lb) nil))))))

(defun unnamed-circle ()
  (let ((b (dummy-bind)))
    (cons (cons :implicit b) (bare-arg b))))

(defun bare-type-braces ()
  (let ((r (alt (braces (alt (cons :right (constraint-p))
                             (let ((x (symbol-p)))
                               (reserved-op ":")
                               (let ((kind (bbase)))
                                 (reserved-op "|")
                                 (let ((ra (refas-hole)))
                                   (cons :left (cons (cons :explicit x)
                                                     (funcall kind (cons x ra)))))))))
                (braces (let ((p (alt (progn (reserved "_") :hole)
                                      (pred-and-raw (brackets (sep-by (expr-p) (semi)))))))
                          (cons :left (cons nil (list :hole (cons "VV" p))))))
                (braces (let ((p (expr-p)))
                          (cons :left (cons nil (list :hole (cons "VV" p)))))))))
    (if (eq (car r) :left)
        (cdr r)
        (let ((tt (cdr (bt))))
          (destructuring-bind (env t1 t2) (cdr r)
            (cons nil (list :constrained env t1 t2 tt)))))))

(defun bare-arg (vv)
  "Parse.hs bareArgP."
  (alt (ref-def vv)
       (hole-p)
       (funcall (bbase) nil)
       (parens (bare-type))))

(defun ref-def (vv)
  "Parse.hs refDefP: { [x:] [base |] refa }."
  (braces (let* ((x (opt (bind-p) vv))
                 (kind (alt (prog1 (bbase) (reserved-op "|"))
                            (lambda (r) (list :hole r))))
                 (ra (refas-hole)))
            (funcall kind (cons x ra)))))

(defun refas-hole ()
  (alt (progn (reserved "_") :hole) (refa-p)))

(defun ref-bind-bind (kindf)
  "Parse.hs refBindBindP with refaP: {x : base | refa} or {refa}."
  (braces (alt (let ((x (symbol-p)))
                 (reserved-op ":")
                 (let ((kind (funcall kindf)))
                   (reserved-op "|")
                   (funcall kind (cons x (refa-p)))))
               (list :hole (cons "VV" (refa-p))))))

(defun bbase ()
  "Parse.hs bbaseP: returns a function from a refinement to a type."
  (alt (progn (reserved "_") (lambda (r) (list :hole r)))
       (let* ((elt (brackets (opt (bare-type))))
              (ps (predicates)))
         (lambda (r) (list :con "[]" (if elt (list elt) '()) ps r '())))
       (let* ((items (parens (sep-by (maybe-bind) (comma))))
              (ps (predicates)))
         (lambda (r) (make-tuple-type items ps r)))
       (let ((l (lower-id)))
         (lower-id-tail l))
       (let* ((tc (btycon))
              (ps (predicates))
              (args (many (bare-ty-arg)))
              (mp (mmono-predicate)))
         (lambda (r) (list :con tc args ps r mp)))))

(defun maybe-bind ()
  (let ((b (opt (prog1 (lower-id) (reserved-op "::")))))
    (cons b (bare-type))))

(defun make-tuple-type (items props reft)
  (cond ((and (= (length items) 1) props)
         (let ((ty (cdr (first items))))
           (with-reft (if (eq (car ty) :con)
                          (list :con (second ty) (third ty) (append (fourth ty) props) (fifth ty) (sixth ty))
                          ty)
                      reft)))
        ((= (length items) 1) (with-reft (cdr (first items)) reft))
        (t (list :con (format nil "(~a)" (make-string (max 0 (1- (length items))) :initial-element #\,))
                 (mapcar #'cdr items) props reft '()))))

(defun lower-id-tail (l)
  (alt (let ((args (many1 (bare-ty-arg))))
         (lambda (r)
           (with-reft (reduce (lambda (acc a) (list :app-ty acc a nil)) args
                              :initial-value (list :var l nil '()))
                      r)))
       (let ((p (mono-predicate)))
         (lambda (r) (list :var l r p)))))

(defun btycon ()
  (alt (progn (reserved-op "'") (concatenate 'string "'" (upper-id)))
       (upper-id)
       (progn (reserved "*") "*")))

(defun bbase-no-app ()
  (alt (progn (reserved "_") (lambda (r) (list :hole r)))
       (let* ((elt (brackets (opt (bare-type))))
              (ps (predicates)))
         (lambda (r) (list :con "[]" (if elt (list elt) '()) ps r '())))
       (let* ((items (parens (sep-by (maybe-bind) (comma))))
              (ps (predicates)))
         (lambda (r) (make-tuple-type items ps r)))
       (let* ((tc (btycon)) (ps (predicates)))
         (lambda (r) (list :con tc '() ps r '())))
       (let* ((l (lower-id)) (p (mono-predicate)))
         (lambda (r) (list :var l r p)))))

(defun bare-ty-arg ()
  "Parse.hs bareTyArgP."
  (alt (list :expr (natural))
       (braces (list :expr (expr-p)))
       (bare-atom-no-app)
       (parens (bare-type))
       (parens (list :expr (expr-p)))))

(defun bare-atom-no-app ()
  (alt (ref-bind-bind #'bbase-no-app)
       (funcall (bbase-no-app) nil)))

(defun constraint-p ()
  "Parse.hs constraintP: [x::t, .. |-] t1 <: t2."
  (let ((env (alt (prog1 (sep-by (ty-bind-no-loc) (comma)) (reserved-op "|-"))
                  '())))
    (let ((t1 (bare-type)))
      (reserved-op "<:")
      (list env t1 (bare-type)))))

(defun ty-bind-no-loc ()
  (let ((x (binder)))
    (reserved-op "::")
    (cons x (bare-type))))

(defun bare-all ()
  "Parse.hs bareAllP: forall a b <p :: t>. type."
  (let* ((as (ty-var-defs))
         (ps (alt (angles (sep-by (pred-var-def) (comma))) '())))
    (dot)
    (list :forall as ps (bare-type))))

(defun ty-var-defs ()
  (alt (parens (many (let ((v (ty-var-id)))
                       (opt (progn (reserved-op "::") (kind-p)))
                       v)))
       (many (ty-var-id))))

(defun kind-p () (alt (ref-bind-bind #'bbase) (hole-p) (funcall (bbase) nil)))

(defun pred-var-def ()
  (let ((p (ty-var-id)))
    (reserved-op "::")
    (cons p (bare-type))))

(defun predicates ()
  "Parse.hs predicatesP: <prop, ..> abstract refinement arguments."
  (alt (angles (sep-by1 (predicate1) (comma)))
       '()))

(defun syms-p ()
  (alt (progn (reserved-op "\\")
              (let ((ss (many (symbol-p))))
                (reserved-op "->")
                ss))
       '()))

(defun predicate1 ()
  (alt (let* ((ss (syms-p)) (ty (ref-bind-bind #'bbase)))
         (list :prop ss ty))
       (list :prop-pred (mono-predicate1))
       (braces (let* ((ss (syms-p)) (p (refa-p)))
                 (list :prop ss (list :hole (cons "VV" p)))))))

(defun mmono-predicate ()
  (alt (angles (angles (mono-predicate1))) '()))

(defun mono-predicate ()
  (alt (angles (mono-predicate1)) '()))

(defun mono-predicate1 ()
  (alt (progn (reserved "True") '())
       (list (parens (pred-var-use)))
       (list (pred-var-use))))

(defun pred-var-use ()
  (alt (let ((e (fun-app)))
         (if (and (consp e) (eq (car e) :app) (stringp (second e)))
             (list* :pvar (second e) (cddr e))
             (pfail "abstract refinement application")))
       (list :pvar (ty-var-id))))

;;; ------------------------------------------------------------------
;;; Specifications (Parse.hs specP)

(defun term-bare-type ()
  "Parse.hs termBareTypeP: a type and an optional / [metric, ..]."
  (let ((ty (bare-type)))
    (alt (progn (reserved-op "/")
                (list ty (brackets (sep-by (expr-p) (comma)))))
         (list ty nil))))

(defun ty-binds ()
  (let ((names (sep-by1 (binder) (comma))))
    (reserved-op "::")
    (destructuring-bind (ty metric) (term-bare-type)
      (list :sig names ty metric))))

(defun ty-bind ()
  (let ((x (binder)))
    (reserved-op "::")
    (list x (bare-type))))

(defmacro fallback-spec (kw &body body)
  "Parse.hs fallbackSpecP: KW then BODY, or else a signature for a function
named KW."
  `(progn (reserved ,kw)
          (alt (progn ,@body)
               (progn (reserved-op "::")
                      (destructuring-bind (ty metric) (term-bare-type)
                        (list :sig (list ,kw) ty metric))))))

(defun measure-pat ()
  "Parse.hs measurePatP: (C x y), (x:xs), [], (x, y), or a nullary C."
  (alt (parens (alt (let ((c (data-con-name))) (cons c (many (lower-id))))
                    (let ((x (lower-id))) (reserved-op ":") (list ":" x (lower-id)))
                    (progn (brackets nil) (list "[]"))
                    (let ((xs (sep-by1 (lower-id) (comma))))
                      (cons (format nil "(~a)" (make-string (1- (length xs)) :initial-element #\,)) xs))))
       (progn (brackets nil) (list "[]"))
       (list (data-con-name))))

(defun result-bool-p (ty)
  (loop while (member (car ty) '(:forall)) do (setf ty (fourth ty)))
  (and (eq (car ty) :fun)
       (let ((r (fourth ty)))
         (loop while (eq (car r) :fun) do (setf r (fourth r)))
         (and (eq (car r) :con) (member (second r) '("Bool" "GHC.Types.Bool") :test #'string=)
              (null (third r))))))

(defun measure-def (body-fn)
  (let* ((m (symbol-p))
         (pat (measure-pat)))
    (reserved-op "=")
    (list m (car pat) (cdr pat) (funcall body-fn))))

(defun measure-body (ty)
  (alt (braces (let ((v (symbol-p)))
                 (reserved-op "|")
                 (list :reft v (expr-p))))
       (if (and ty (result-bool-p ty))
           (list :pred (expr-p))
           (list :expr (expr-p)))))

(defun hmeasure ()
  (set-layout)
  (alt (let ((b (prog1 (binder) (reserved-op "::"))))
         (let ((ty (bare-type)))
           (pop-layout) (pop-layout)
           (list :measure b ty (block-of (measure-def (lambda () (measure-body ty)))))))
       (let ((b (binder)))
         (pop-layout) (pop-layout)
         (list :hmeasure b))))

(defun instance-measure ()
  (destructuring-bind (x ty) (indented-line (ty-bind))
    (opt (semi))
    (list :instance-measure x ty (block-of (measure-def (lambda () (measure-body ty)))))))

(defun supers ()
  (alt (prog1 (alt (parens (sep-by1 (ref-bind-bind-or-atom) (comma)))
                   (list (ref-bind-bind-or-atom)))
         (reserved-op "=>"))
       '()))

(defun ref-bind-bind-or-atom ()
  (alt (ref-bind-bind #'bbase) (hole-p) (funcall (bbase) nil)))

(defun many-till-where (form-fn)
  (let ((acc '()))
    (loop (when (succeeds (reserved "where")) (return (nreverse acc)))
          (push (funcall form-fn) acc))))

(defun class-p ()
  (let* ((sups (supers))
         (c (upper-id))
         (tvs (many-till-where #'ty-var-id))
         (ms (block-of (let ((b (ty-bind))) (cons (first b) (second b))))))
    (list :class sups c tvs ms)))

(defun instance-p ()
  (let* ((sups (supers))
         (c (upper-id))
         (args (alt (let ((vs (many-till-where #'lower-id)))
                      (list (list :con c (mapcar (lambda (v) (list :var v nil '())) vs) '() nil '())))
                    ;; upstream accepts type variables and parenthesised
                    ;; types; a bare constructor (instance C Int) is
                    ;; accepted here too
                    (many-till-where (lambda () (alt (list :var (ty-var-id) nil '())
                                                     (parens (bare-type))
                                                     (list :con (btycon) '() '() nil '()))))))
         (ms (block-of (alt (progn (reserved "assume")
                                   (destructuring-bind (x ty) (ty-bind) (list x t ty)))
                            (destructuring-bind (x ty) (ty-bind) (list x nil ty))))))
    (list :instance sups c args ms)))

(defun data-con-fields ()
  (alt (explicit-block (sym "{") (sym "}") (comma)
                       (let ((x (lower-id))) (reserved-op "::") (cons x (bare-type))))
       (many (alt (parens (alt (let ((x (lower-id))) (reserved-op "::") (cons x (bare-type)))
                               (cons (dummy-bind) (bare-type))))
                  (cons (dummy-bind) (bare-ty-arg))))))

(defun fun-type-parts (ty)
  "The (binder . arg) pairs and the result of a function type."
  (let ((args '()))
    (loop while (eq (car ty) :forall) do (setf ty (fourth ty)))
    (loop while (eq (car ty) :fun)
          do (push (cons (second ty) (third ty)) args)
             (setf ty (fourth ty)))
    (values (nreverse args) ty)))

(defun data-decl ()
  "Parse.hs dataDeclP."
  (let* ((x (alt (upper-id*) (infix-cond-id)))
         (size (alt (brackets (lower-id)) nil)))
    (alt (progn
           (many (upper-id))
           (let* ((as (many (let ((s (ty-var-id))) (when (string= s "where") (pfail)) s)))
                  (ps (alt (angles (sep-by1 (pred-var-def) (comma))) '())))
             (destructuring-bind (ptype ctors)
                 (alt (progn (reserved-op "=")
                             (list nil (sep-by (let ((c (data-con-name)))
                                                 (list c (data-con-fields) nil))
                                               (reserved-op "|"))))
                      (progn (reserved "where")
                             (list nil (block-of (adt-data-con))))
                      (let ((pt (progn (reserved-op "::") (prog1 (bare-type) (reserved "where")))))
                        (list pt (block-of (adt-data-con)))))
               (list :decl x as ps ctors size ptype))))
         (if size
             (list :decl x '() '() nil size nil)
             (pfail "data declaration body")))))

(defun adt-data-con ()
  (let ((c (data-con-name)))
    (reserved-op "::")
    (multiple-value-bind (args res) (fun-type-parts (bare-type))
      (list c args res))))

(defun variance ()
  (alt (progn (reserved "bivariant") :bivariant)
       (progn (reserved "invariant") :invariant)
       (progn (reserved "covariant") :covariant)
       (progn (reserved "contravariant") :contravariant)))

(defun rt-alias (name-fn body-fn)
  (let* ((name (funcall name-fn))
         (args (many (alias-id))))
    (reserved-op "=")
    (let ((body (funcall body-fn)))
      (values name
              (remove-if-not (lambda (a) (lower-or-underscore-p (char a 0))) args)
              (remove-if (lambda (a) (lower-or-underscore-p (char a 0))) args)
              body))))

(defun bound-p ()
  (let ((name (upper-id)))
    (reserved-op "=")
    (let* ((vs (alt (progn (reserved "forall")
                           (prog1 (many (symbol-p)) (reserved-op ".")))
                    '()))
           (params (many (parens (let ((b (ty-bind))) (cons (first b) (second b))))))
           (args (alt (progn (reserved-op "\\")
                             (prog1 (many (parens (let ((b (ty-bind))) (cons (first b) (second b)))))
                               (reserved-op "->")))
                      '())))
      (list :bound name vs params args (expr-p)))))

(defun relational ()
  (let ((x (binder)))
    (reserved "~")
    (let ((y (binder)))
      (reserved "::")
      (braces (let ((tx (bare-type)))
                (reserved "~")
                (let ((ty (bare-type)))
                  (reserved "|")
                  (let* ((assm (alt (prog1 (rel-refa) (reserved "|-")) :true))
                         (ex (rel-refa)))
                    (list :relational x y tx ty assm ex))))))))

(defun rel-refa ()
  (alt (let ((a (refa-p))) (reserved ":=>") (list :unchecked a (rel-refa)))
       (let ((a (refa-p))) (reserved "!=>") (list :checked a (rel-refa)))
       (refa-p)))

(defun maybe-digit ()
  (opt (lexeme (digit-char-p (raw-char-if #'digit-char-p "digit")))))

(defun fixity-p (assoc)
  (let* ((p (maybe-digit))
         (op (infix-id)))
    (add-fixity p op :infix nil assoc :user)
    (list :fixity assoc p op)))

(defun include-p ()
  (reserved "include")
  (lexeme (raw-string "<")
          (let ((start *pos*))
            (loop while (and (peek) (char/= (peek) #\>)) do (incf *pos*))
            (prog1 (subseq *src* start *pos*) (raw-string ">")))))

(defun spec-p ()
  "Parse.hs specP: one specification."
  (alt
   (fallback-spec "assume"
     (alt (progn (reserved "reflect")
                 (let ((a (binder))) (reserved-op "as") (list :assume-reflect a (binder))))
          (progn (reserved "relational") (relational))
          (destructuring-bind (x ty) (ty-bind) (list :assume x ty))))
   (fallback-spec "assert" (destructuring-bind (x ty) (ty-bind) (list :assert x ty)))
   (fallback-spec "autosize" (list :autosize (upper-id)))
   (fallback-spec "axiomatize" (list :reflect (binder)))
   (fallback-spec "reflect" (list :reflect (binder)))
   (fallback-spec "stratified" (list :stratified (upper-id)))
   (progn (reserved "private-reflect") (list :private-reflect (binder)))
   (progn (reserved "opaque-reflect") (list :opaque-reflect (binder)))
   (fallback-spec "define"
     (let* ((s (binder)) (args (many (symbol-p))))
       (reserved-op "=")
       (list :define s args (expr-p))))
   (fallback-spec "measure" (hmeasure))
   (progn (reserved "infixl") (fixity-p :left))
   (progn (reserved "infixr") (fixity-p :right))
   (progn (reserved "infix") (fixity-p :left))
   (fallback-spec "inline" (list :inline (binder)))
   (fallback-spec "ignore" (list :ignore (binder)))
   (fallback-spec "bound" (bound-p))
   (progn (reserved "class")
          (alt (progn (reserved "measure")
                      (destructuring-bind (x ty) (ty-bind) (list :class-measure x ty)))
               (class-p)))
   (progn (reserved "instance")
          (alt (progn (reserved "measure") (instance-measure))
               (instance-p)))
   (progn (reserved "data")
          (alt (progn (reserved "variance") (list :data-variance (upper-id) (many (variance))))
               (progn (reserved "size")
                      (list :data-size (parens (sep-by (bare-type) (comma))) (binder)))
               (list :data (data-decl))))
   (progn (reserved "newtype") (list :newtype (data-decl)))
   (progn (reserved "relational") (relational))
   (fallback-spec "invariant" (list :invariant (bare-type)))
   (progn (reserved "using")
          (let ((ty (bare-type))) (reserved "as") (list :using ty (bare-type))))
   (progn (reserved "type")
          (multiple-value-bind (n tvs vs body) (rt-alias #'upper-id #'bare-type)
            (list :type-alias n tvs vs body)))
   (fallback-spec "predicate"
     (multiple-value-bind (n tvs vs body) (rt-alias #'binder #'expr-p)
       (list :pred-alias n (append tvs vs) body)))
   (fallback-spec "expression"
     (multiple-value-bind (n tvs vs body) (rt-alias #'binder #'expr-p)
       (list :pred-alias n (append tvs vs) body)))
   (fallback-spec "embed"
     (let* ((x (upper-id))
            (with-args (succeeds (reserved "*"))))
       (reserved "as")
       (list :embed x (p-sort) with-args)))
   (fallback-spec "qualif" (list :qualif (qualifier-p)))
   (progn (reserved "lazyvar") (list :lazyvar (binder)))
   (progn (reserved "lazy") (list :lazy (binder)))
   (progn (reserved "rewriteWith")
          (let ((x (binder))) (list :rewrite-with x (brackets (sep-by1 (binder) (comma))))))
   (progn (reserved "rewrite") (list :rewrite (binder)))
   (progn (reserved "fail") (list :fail (binder)))
   (progn (reserved "ple") (list :ple (binder)))
   (progn (reserved "automatic-instances") (list :ple (binder)))
   (progn (reserved "LIQUID") (list :pragma (string-literal-p)))
   (progn (reserved "liquid") (list :pragma (string-literal-p)))
   (list :include (include-p))
   (ty-binds)))

;;; ------------------------------------------------------------------
;;; Entry points

(defvar *spec-fixities* nil
  "Fixities carried from one spec comment to the next within a file.")

(defun parse-spec-region (text start end &key name)
  "Parse the specifications in TEXT between START and END (the inside of
one {-@ @-} comment).  Returns the list of specifications; signals
LIQUID-PARSE-ERROR."
  (with-parse-input (text :start start :end end :name name)
    (let ((*fixities* (or *spec-fixities* (builtin-fixities)))
          (*list-syntax* t))
      (skip-spaces)
      (multiple-value-bind (v ok) (attempt (prog1 (block-of (spec-p)) (expect-eof)))
        (if ok
            (progn (setf *spec-fixities* *fixities*) v)
            (signal-parse-failure))))))

(defun parse-spec-string (text)
  "Parse TEXT, the contents of a {-@ ... @-} comment (without the braces)."
  (let ((*spec-fixities* nil))
    (parse-spec-region text 0 (length text))))

(defun extract-spec-comments (text)
  "The {-@ ... @-} comments of Haskell source TEXT, as (START . END) index
pairs of their contents.  Skips string and character literals, line
comments and other (nested) block comments, as GHC's lexer would."
  (let ((i 0) (n (length text)) (acc '()))
    (flet ((at (s) (and (<= (+ i (length s)) n) (string= s text :start2 i :end2 (+ i (length s))))))
      (loop while (< i n)
            do (cond
                 ((at "{-@")
                  ;; GHC nests block comments, so the spec ends at the -}
                  ;; that closes this {-, normally preceded by @
                  (let ((start (+ i 3)) (depth 1))
                    (incf i 3)
                    (loop while (and (< i n) (plusp depth))
                          do (cond ((at "{-") (incf depth) (incf i 2))
                                   ((at "-}") (decf depth) (incf i 2))
                                   (t (incf i))))
                    (when (plusp depth) (return))
                    (let ((end (- i 2)))
                      (when (and (> end start) (char= (char text (1- end)) #\@))
                        (decf end))
                      (push (cons start end) acc))))
                 ((at "{-")
                  (let ((depth 1))
                    (incf i 2)
                    (loop while (and (< i n) (plusp depth))
                          do (cond ((at "{-") (incf depth) (incf i 2))
                                   ((at "-}") (decf depth) (incf i 2))
                                   (t (incf i))))))
                 ((and (at "--")
                       (let ((j i))
                         (loop while (and (< j n) (char= (char text j) #\-)) do (incf j))
                         (or (>= j n) (not (haskell-op-char-p (char text j))))))
                  (loop while (and (< i n) (char/= (char text i) #\Newline)) do (incf i)))
                 ((char= (char text i) #\")
                  (incf i)
                  (loop while (and (< i n) (char/= (char text i) #\") (char/= (char text i) #\Newline))
                        do (when (char= (char text i) #\\) (incf i))
                           (incf i))
                  (incf i))
                 ((and (char= (char text i) #\') (< (+ i 2) n)
                       (or (char= (char text (+ i 2)) #\')
                           (and (char= (char text (+ i 1)) #\\) (< (+ i 3) n))))
                  ;; a character literal 'x' or '\n'
                  (let ((close (position #\' text :start (+ i 2))))
                    (setf i (if close (1+ close) n))))
                 (t (incf i)))))
    (nreverse acc)))

(defun parse-spec-text (text &key name (errors :collect))
  "Parse every spec comment of Haskell source TEXT.  Returns the
specifications and the list of parse errors (with ERRORS :collect), or
signals the first error (ERRORS :signal)."
  (let ((*spec-fixities* nil) (specs '()) (errs '()))
    (dolist (r (extract-spec-comments text))
      (handler-case (setf specs (append specs (parse-spec-region text (car r) (cdr r) :name name)))
        (liquid-parse-error (e)
          (if (eq errors :signal) (error e) (push e errs)))))
    (values specs (nreverse errs))))

(defun parse-spec-file (path &rest keys)
  (apply #'parse-spec-text (read-file-string path) :name (namestring path) keys))
