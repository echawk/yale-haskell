;;;; expr-parser.lisp -- expressions, predicates and sorts.
;;;;
;;;; A port of the expression and sort grammar of liquid-fixpoint's
;;;; src/Language/Fixpoint/Parse.hs (commit
;;;; 0b924442ce26a8f270bffac18ba6295bc7411646): expr0P, exprP with the
;;;; operator table bops, funAppP, appliableExprP, sortP, kvarPredP, refaP.
;;;; LiquidHaskell's specification parser reuses the same grammar (with
;;;; list syntax [] and [e] enabled), as upstream does.

(in-package :yale-liquid)

;;; ------------------------------------------------------------------
;;; Operator table (Parse.hs bops).  Entries are
;;; (PREC NAME KIND FN ASSOC): KIND is :infix, :prefix or :postfix; FN
;;; builds the expression (NIL: apply the operator as a variable); ASSOC
;;; is :left, :right or :none.

(defun neg-expr (e)
  (cond ((integerp e) (- e))
        ((and (consp e) (eq (car e) :real)) (list :real (- (second e))))
        (t (list :neg e))))

(defun builtin-fixities ()
  (flet ((bin (op) (lambda (a b) (list op a b))))
    (list (list 9 "-" :prefix #'neg-expr nil)
          (list 7 "*" :infix (bin :*) :left)
          (list 7 "/" :infix (bin :/) :left)
          (list 6 "-" :infix (bin :-) :left)
          (list 6 "+" :infix (bin :+) :left)
          (list 5 "mod" :infix (bin :mod) :left)
          (list 9 "." :infix nil :right)
          (list 4 "==" :infix (bin :=) :none)
          (list 4 "=" :infix (bin :=) :none)
          (list 4 "~~" :infix (bin :~~) :none)
          (list 4 "!=" :infix (bin :/=) :none)
          (list 4 "/=" :infix (bin :/=) :none)
          (list 4 "!~" :infix (bin :!~) :none)
          (list 4 "<" :infix (bin :<) :none)
          (list 4 "<=" :infix (bin :<=) :none)
          (list 4 ">" :infix (bin :>) :none)
          (list 4 ">=" :infix (bin :>=) :none)
          (list 3 "&&" :infix (lambda (a b) (flat-connective :and a b)) :right)
          (list 2 "||" :infix (lambda (a b) (flat-connective :or a b)) :right)
          (list 1 "=>" :infix (bin :=>) :right)
          (list 1 "==>" :infix (bin :=>) :right)
          (list 1 "<=>" :infix (bin :<=>) :right)
          (list 9 "~" :prefix #'pred-not-raw nil))))

(defun flat-connective (op a b)
  (flet ((parts (x) (if (and (consp x) (eq (car x) op)) (cdr x) (list x))))
    (cons op (append (parts a) (parts b)))))

(defun pred-not-raw (p) (list :not p))

(defun add-fixity (prec name kind fn assoc)
  "Parse.hs addOperatorP: later entries are tried first within a level."
  (push (list (or prec 9) name kind fn assoc) *fixities*))

(defun level-ops (level kind &optional assoc)
  (remove-if-not (lambda (f) (and (= (first f) level) (eq (third f) kind)
                                  (or (null assoc) (eq (fifth f) assoc))))
                 *fixities*))

(defun apply-op (entry &rest args)
  (if (fourth entry)
      (apply (fourth entry) args)
      (apply #'app (second entry) args)))

(defun op-of (entries)
  "Match one of the operators ENTRIES; return its entry."
  (dolist (e entries (pfail "operator"))
    (when (succeeds (reserved-op (second e)))
      (return e))))

(defun term-at (level)
  "makeExprParser's pTerm: an optional prefix operator, the next level's
term, an optional postfix operator."
  (let* ((pre (opt (op-of (level-ops level :prefix))))
         (x (expr-at (1+ level)))
         (x (if pre (apply-op pre x) x))
         (post (opt (op-of (level-ops level :postfix)))))
    (if post (apply-op post x) x)))

(defun infix-r (level x)
  (let* ((op (op-of (level-ops level :infix :right)))
         (y (term-at level))
         (y (opt (infix-r level y) y)))
    (apply-op op x y)))

(defun infix-l (level x)
  (let* ((op (op-of (level-ops level :infix :left)))
         (y (term-at level))
         (r (apply-op op x y)))
    (opt (infix-l level r) r)))

(defun infix-n (level x)
  (let* ((op (op-of (level-ops level :infix :none)))
         (y (term-at level)))
    (apply-op op x y)))

(defun expr-at (level)
  (if (> level 9)
      (expr0)
      (if (notany (lambda (f) (= (first f) level)) *fixities*)
          (expr-at (1+ level))
          (let ((x (term-at level)))
            (alt (infix-r level x)
                 (infix-l level x)
                 (infix-n level x)
                 x)))))

(defun expr-p ()
  "Parse.hs exprP."
  (expr-at 0))

(defun normalize-connectives (e)
  ;; x && y && z parses as (and x (and y z)); flatten it.
  (if (and (consp e) (member (car e) '(:and :or)))
      (let ((op (car e)))
        (cons op (loop for x in (cdr e)
                       append (if (and (consp x) (eq (car x) op)) (cdr x) (list x)))))
      e))

;;; ------------------------------------------------------------------
;;; Atoms (Parse.hs expr0P, appliableExprP, funAppP)

(defun expr0 ()
  (alt (progn (reserved-op "_|_") :false)
       (progn (reserved "not") (list :not (appliable-expr)))
       (fun-app)
       (exist-p)
       (if-p)
       (coerce-p)
       (lit-p)
       (lam-p)
       (progn (reserved-op "&&") (cons :and (preds-p)))
       (progn (reserved-op "||") (cons :or (preds-p)))))

(defun fun-app ()
  (let* ((f (appliable-expr))
         (args (alt (parens (brackets (sep-by (expr-p) (semi))))
                    (many (appliable-expr)))))
    (if args (apply #'app f args) f)))

(defun constant-p ()
  (lexeme (alt (list :real (float-raw)) (natural-raw))))

(defun appliable-expr ()
  (alt (progn (reserved "true") :true)
       (progn (reserved "false") :false)
       (list :str (string-literal-p))
       (constant-p)
       (progn (reserved-op "_|_") :false)
       (tuple-p)
       (parens (expr-p))
       (parens (expr-cast))
       (symbol-p)
       (if *list-syntax* (progn (brackets nil) "[]") (pfail))
       (if *list-syntax* (app ":" (brackets (expr-p)) "[]") (pfail))
       (kvar-pred)))

(defun expr-cast ()
  (let ((e (expr-p)))
    (alt (dcolon) (colon))
    (list :cast e (p-sort))))

(defun tuple-p ()
  (let ((items (parens (let ((x (expr-p)))
                         (comma)
                         (cons x (sep-by1 (expr-p) (comma)))))))
    (apply #'app (format nil "(~a)" (make-string (1- (length items)) :initial-element #\,))
           items)))

(defun if-p ()
  (reserved "if")
  (let ((c (expr-p)))
    (reserved "then")
    (let ((a (expr-p)))
      (reserved "else")
      (list :ite c a (expr-p)))))

(defun coerce-p ()
  (reserved "coerce")
  (destructuring-bind (s . tt) (parens (let ((s (p-sort))) (reserved-op "~") (cons s (p-sort))))
    (list :coerce s tt (expr-p))))

(defun lit-p ()
  (reserved "lit")
  (let ((s (string-literal-p)))
    (list :lit s (p-sort))))

(defun lam-p ()
  (reserved-op "\\")
  (let ((x (symbol-p)))
    (colon)
    (let ((s (p-sort)))
      (reserved-op "->")
      (list :lam (cons x s) (expr-p)))))

(defun exist-p ()
  (unless *allow-exists* (pfail))
  (reserved "exists")
  (let ((bs (brackets (sep-by (let ((x (bind-p))) (cons x (p-sort))) (comma)))))
    (dot)
    (list :exists bs (expr-p))))

(defun preds-p () (brackets (sep-by (expr-p) (semi))))

(defun bind-p () (prog1 (symbol-p) (colon)))

(defun kvar-name () (lexeme (raw-string "$") (symbol-raw)))

(defun kvar-pred ()
  "Parse.hs kvarPredP: $k, an optional [@a:=sort;..] type substitution
(parsed and dropped), then [x:=e] substitutions."
  (let ((k (kvar-name)))
    (opt (brackets (progn (raw-string "@")
                          (sep-by1 (progn (symbol-p) (reserved-op ":=") (p-sort)) (sym ";")))))
    (let ((su (many (brackets (let ((x (symbol-p)))
                                (reserved-op ":=")
                                (cons x (expr-p)))))))
      (list :kvar k su))))

(defun refa-p ()
  "Parse.hs refaP: [p; q; ..] or an expression."
  (alt (pred-and-raw (brackets (sep-by (expr-p) (semi))))
       (expr-p)))

(defun pred-and-raw (ps)
  (cond ((null ps) :true)
        ((null (cdr ps)) (car ps))
        (t (cons :and ps))))

;;; ------------------------------------------------------------------
;;; Sorts (Parse.hs sortP, fTyConP, tvarP, funcSortP)

(defun p-sort () (p-sort* t))
(defun p-sort-arg () (p-sort* nil))

(defun p-sort* (with-args)
  (flet ((args () (if with-args (many (p-sort-arg)) '())))
    (alt (parens (p-sort))
         (progn (reserved "func") (p-func-sort))
         (list-sort (brackets (p-sort)))
         (let ((tc (ftycon-p)))
           (let ((as (args)))
             (if (and (keywordp tc) (null as)) tc
                 (list* :tc (if (keywordp tc) (sort->string tc) tc) as))))
         (let ((tv (tvar-p)))
           (let ((as (args)))
             (if as (list* :sapp tv as) tv)))
         (list :nat (natural)))))

(defun tvar-p ()
  (alt (progn (raw-string "@") (list :var (parens (integer-p))))
       (list :obj (lower-id))))

(defun ftycon-p ()
  (alt (progn (reserved "int") :int)
       (progn (reserved "Integer") :int)
       (progn (reserved "Int") :int)
       (progn (reserved "real") :real)
       (progn (reserved "bool") :bool)
       (progn (reserved "num") :num)
       (progn (reserved "frac") :frac)
       (progn (reserved "Str") :str)
       (upper-id)))

(defun p-func-sort ()
  (parens (let ((n (int-p)))
            (comma)
            (let ((ss (alt (brackets (sep-by (p-sort) (semi)))
                           (brackets (sep-by (p-sort) (comma))))))
              (when (null ss) (pfail "function sort"))
              (func-sort n (butlast ss) (car (last ss)))))))

;;; ------------------------------------------------------------------
;;; Entry points

(defmacro with-expr-parser ((text &rest keys) &body body)
  `(with-parse-input (,text ,@keys)
     (let ((*fixities* (builtin-fixities)))
       (skip-spaces)
       (multiple-value-bind (v ok) (attempt (prog1 (progn ,@body) (expect-eof)))
         (if ok v (signal-parse-failure))))))

(defun parse-expr-string (text)
  "Parse TEXT as a liquid-fixpoint expression or predicate."
  (with-expr-parser (text) (expr-p)))

(defun parse-pred-string (text)
  (with-expr-parser (text) (refa-p)))

(defun parse-sort-string (text)
  (with-expr-parser (text) (p-sort)))
