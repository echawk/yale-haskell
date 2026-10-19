;;;; tests.lisp -- tests for yale-liquid (make liquid-test).
;;;;
;;;; RUN-ALL runs, in order:
;;;;   1. unit tests of the logic, the parsers, sort checking and the SMT
;;;;      encoding;
;;;;   2. the specification parser over LiquidHaskell's library
;;;;      specifications (all must parse) and over the extracted test
;;;;      annotations (every comment must parse except those listed in
;;;;      lh/expected-parse-failures.txt);
;;;;   3. with Z3: validity checks, and the fixpoint solver over the vendored
;;;;      liquid-fixpoint tests (pos SAFE, neg UNSAFE, except those listed
;;;;      in fq/expected-failures.txt).
;;;; It returns true when nothing failed.  Missing solvers skip their parts
;;;; with a note.

(defpackage :yale-liquid-tests
  (:use :common-lisp)
  (:shadowing-import-from :yale-liquid #:subst)
  (:import-from :yale-liquid
   #:parse-expr-string #:parse-pred-string #:parse-sort-string #:expr->string
   #:sort->string #:subst1 #:pred-and #:conjuncts #:free-vars
   #:read-fq-file #:read-fq-string #:print-fq #:fq-info-constraints
   #:parse-spec-string #:parse-spec-text #:extract-spec-comments
   #:check-valid #:solve-fq-file #:result-status #:result-solution
   #:result-unsafe-ids #:result-message
   #:z3-available-p
   #:liquid-parse-error)
  (:export #:run-all))

(in-package :yale-liquid-tests)

(defvar *failures* 0)
(defvar *checks* 0)
(defvar *root* (asdf:system-source-directory :yale-liquid))

(defun data-path (rel) (merge-pathnames rel (merge-pathnames "tests/liquid/" *root*)))

(defun fail (fmt &rest args)
  (incf *failures*)
  (format t "~&  FAIL: ~?~%" fmt args))

(defmacro check (form &optional (fmt "~s") &rest args)
  `(progn (incf *checks*)
          (handler-case (unless ,form (fail ,fmt ,@args))
            (error (e) (fail "~a: ~a" (format nil ,fmt ,@args) e)))))

(defmacro section (name &body body)
  `(progn (format t "~&~a~%" ,name)
          (handler-case (progn ,@body)
            (error (e) (fail "~a crashed: ~a" ,name e)))))

;;; ------------------------------------------------------------------
;;; 1. Unit tests

(defparameter *round-trip-exprs*
  '("x + 1 > 0 && v = len xs" "[len v >= 0; v = x]" "$k0[x:=y][z:=1]"
    "f (g x) y - 3 * 2" "if x then y else z" "not (x = 1) => y <=> z"
    "exists [x:int, y:bool]. x = 1" "-5 + x" "x mod 2 = 0" "1.5 < y"
    "lit \"#foo\" Str" "a && b && c || d" "x - (y - z) = (x - y) - z"
    "\\x:int -> x + 1" "coerce (int ~ real) x" "(x : int) = 1"
    "Set_mem x (Set_cup s1 s2)" "v ~~ w" "x / y * y <= x" "-(x + 1) < 0"))

(defun unit-tests ()
  (section "logic and expression parser"
    (dolist (s *round-trip-exprs*)
      (let* ((e (parse-pred-string s))
             (e2 (parse-pred-string (expr->string e))))
        (check (equal e e2) "round trip of ~s: ~s vs ~s" s e e2)))
    (check (equal (parse-expr-string "x + y * z") '(:+ "x" (:* "y" "z"))))
    (check (equal (parse-expr-string "x - y - z") '(:- (:- "x" "y") "z")))
    (check (equal (parse-expr-string "p => q => r") '(:=> "p" (:=> "q" "r"))))
    (check (equal (parse-expr-string "len([xs])") '(:app "len" "xs")))
    (check (equal (parse-expr-string "(a, b)") '(:app "(,)" "a" "b")))
    (check (handler-case (progn (parse-expr-string "x + ") nil) (liquid-parse-error () t))
           "an incomplete expression is a parse error")
    (dolist (s '("int" "func(2, [(@(0) @(1)); int])" "[(Tuple int a)]" "(Set_Set int)" "(Vec @(0))"))
      (check (equal (parse-sort-string s) (parse-sort-string (sort->string (parse-sort-string s))))
             "sort round trip ~s" s))
    (check (equal (parse-sort-string "func(1, [@(0); [@(0)]; int])")
                  '(:func 1 ((:var 0) (:tc "[]" (:var 0))) :int))))
  (section "substitution"
    (check (equal (subst1 (parse-expr-string "x + y") "x" 3) '(:+ 3 "y")))
    ;; upstream's catSubst: the pending substitution is applied to, then
    ;; extended with, the new one
    (check (equal (subst (parse-expr-string "$k[a:=x]") '(("x" . "z") ("b" . 1)))
                  '(:kvar "k" (("a" . "z") ("x" . "z") ("b" . 1))))
           "kvar substitutions compose")
    (check (equal (subst (parse-expr-string "exists [x:int]. x = y") '(("x" . 1) ("y" . 2)))
                  '(:exists (("x" . :int)) (:= "x" 2)))
           "bound variables shadow")
    (check (equal (pred-and :true '(:and "p" "q") "p" :true) '(:and "p" "q")))
    (check (eq (pred-and "p" :false) :false))
    (check (equal (free-vars (parse-expr-string "f x (y + z)")) '("f" "x" "y" "z"))))
  (section "sort checking"
    (let ((genv (yale-liquid::make-global-env
                 :consts (list (cons "len" (parse-sort-string "func(1, [[@(0)]; int])"))))))
      (flet ((ok (s vars) (yale-liquid::well-sorted-p (parse-pred-string s) vars genv)))
        (check (ok "len xs >= 0" '(("xs" . (:tc "[]" :int)))))
        (check (ok "len xs = len ys" '(("xs" . (:tc "[]" :int)) ("ys" . (:tc "[]" :bool)))))
        (check (not (ok "x + true = 1" '(("x" . :int)))) "int + bool is ill-sorted")
        (check (not (ok "len x = 0" '(("x" . :int)))) "len of an int is ill-sorted")
        (check (not (ok "y > 0" '(("x" . :int)))) "unbound variable")
        (check (ok "x / 2.5 > 1.0" '(("x" . :real)))))))
  (section "SMT encoding"
    (let* ((genv (yale-liquid::make-global-env))
           (ctx (yale-liquid::make-smt-ctx :genv genv)))
      (flet ((enc (s vars)
               (values (yale-liquid::formula->smt2
                        (yale-liquid::elaborate (parse-pred-string s) vars genv)
                        ctx (mapcar (lambda (p) (cons (car p) (car p))) vars)))))
        (check (equal (enc "x / 2 = 1" '(("x" . :int))) "(= (div x 2) 1)"))
        (check (equal (enc "x / 2.0 = 1.0" '(("x" . :real))) "(= (/ x 2.0) 1.0)"))
        (check (equal (enc "x + 1 > 0" '(("x" . :real))) "(> (+ x 1.0) 0.0)")
               "integer literals at sort real")
        (check (equal (enc "Set_mem x (Set_sng y)" '(("x" . :int) ("y" . :int)))
                      "(select (store ((as const (Array Int Bool)) false) y true) x)"))
        (check (equal (enc "x != y" '(("x" . :int) ("y" . :int))) "(not (= x y))")))))
  (section "specification parser"
    (flet ((spec (s) (parse-spec-string s)))
      (check (equal (spec "incr :: x:{v:Int | v > 0} -> {v:Int | v > x}")
                    '((:sig ("incr")
                       (:fun "x" (:con "Int" nil nil ("v" :> "v" 0) nil)
                        (:con "Int" nil nil ("v" :> "v" "x") nil))
                       nil))))
      (check (equal (spec "type Gt N = {v:Int | N < v}")
                    '((:type-alias "Gt" nil ("N") (:con "Int" nil nil ("v" :< "N" "v") nil)))))
      (check (equal (first (first (spec "measure len :: [a] -> Int
  len []     = 0
  len (y:ys) = 1 + len ys")))
                    :measure))
      (check (equal (fourth (first (spec "measure len :: [a] -> Int
  len []     = 0
  len (y:ys) = 1 + len ys")))
                    '(("len" "[]" nil (:expr 0))
                      ("len" ":" ("y" "ys") (:expr (:+ 1 (:app "len" "ys")))))))
      (check (equal (spec "fib :: n:Nat -> Nat / [n]")
                    '((:sig ("fib") (:fun "n" (:con "Nat" nil nil nil nil) (:con "Nat" nil nil nil nil))
                       ("n")))))
      (check (equal (spec "LIQUID \"--no-termination\"") '((:pragma "--no-termination"))))
      (check (equal (spec "predicate Btwn Lo V Hi = Lo <= V && V < Hi")
                    '((:pred-alias "Btwn" ("Lo" "V" "Hi") (:and (:<= "Lo" "V") (:< "V" "Hi"))))))
      (check (equal (mapcar #'car (spec "inline max'
reflect fib
measure llen
include <Data/Set.spec>
invariant {v:[a] | len v >= 0}"))
                    '(:inline :reflect :hmeasure :include :invariant)))
      (check (equal (second (first (spec "data Vec a = Nil | Cons { vhd :: a, vtl :: Vec a }")))
                    '(:decl "Vec" ("a") nil
                      (("Nil" nil nil)
                       ("Cons" (("vhd" :var "a" nil nil) ("vtl" :con "Vec" ((:var "a" nil nil)) nil nil nil)) nil))
                      nil nil)))
      (check (equal (spec "infixl 6 +++
f :: x:Int -> {v:Int | v = x +++ 1}")
                    '((:fixity :left 6 "+++")
                      (:sig ("f") (:fun "x" (:con "Int" nil nil nil nil)
                                   (:con "Int" nil nil ("v" := "v" (:app "+++" "x" 1)) nil))
                       nil)))
             "user fixities")))
  (section "spec comment extraction"
    (let ((text "f = \"{-@ not a spec @-}\" -- {-@ nor this @-}
{- {-@ nested, not a spec @-} -}
{-@ a :: Int @-}
{-@ LIQUID \"{-@ x @-}\" @-}"))
      (check (equal (mapcar (lambda (r) (subseq text (car r) (cdr r))) (extract-spec-comments text))
                    '(" a :: Int " " LIQUID \"{-@ x @-}\" "))))))

;;; ------------------------------------------------------------------
;;; 2. LiquidHaskell specification corpus

(defun files-under (dir type)
  (sort (remove-if-not (lambda (f) (equal (pathname-type f) type))
                       (directory (merge-pathnames (format nil "**/*.~a" type) dir)))
        #'string< :key #'namestring))

(defun read-lines (path)
  (with-open-file (in path :external-format :utf-8)
    (loop for l = (read-line in nil) while l collect l)))

(defun expected-list (path)
  "Non-comment, non-blank lines of PATH, first word of each."
  (when (probe-file path)
    (loop for l in (read-lines path)
          for s = (string-trim " " l)
          unless (or (zerop (length s)) (char= (char s 0) #\#))
            collect (subseq s 0 (or (position #\Space s) (length s))))))

(defun annotation-chunks (path)
  "The (LOCATION . TEXT) chunks of an extracted annotation file."
  (let ((chunks '()) (loc nil) (buf '()))
    (flet ((flush () (when loc (push (cons loc (format nil "~{~a~%~}" (reverse buf))) chunks))))
      (dolist (l (read-lines path))
        (if (uiop:string-prefix-p "-- FILE " l)
            (progn (flush) (setf loc (subseq l 8) buf '()))
            (when loc (push l buf))))
      (flush))
    (nreverse chunks)))

(defvar *record-parse-failures* nil
  "When true, SPEC-CORPUS-TESTS collects the failing annotation locations
here instead of reporting them (see RECORD-EXPECTED-PARSE-FAILURES).")

(defun record-expected-parse-failures ()
  "Rewrite lh/expected-parse-failures.txt from the current parser."
  (let ((*record-parse-failures* (list :start)) (*failures* 0) (*checks* 0))
    (spec-corpus-tests)
    (with-open-file (o (data-path "lh/expected-parse-failures.txt") :direction :output
                                                                    :if-exists :supersede)
      (format o "# {-@ @-} comments of lh/annotations that do not parse, by upstream location.~%~
                 # Old or unsupported syntax (Decrease, separate measure equations, ..) and~%~
                 # deliberate errors.  Regenerate with~%~
                 #   (yale-liquid-tests::record-expected-parse-failures)~%")
      (dolist (l (reverse (butlast *record-parse-failures*)))
        (format o "~a~%" l)))))

(defun spec-corpus-tests ()
  (section "LiquidHaskell library specifications (lh/assumptions)"
    (let ((n 0) (bad 0) (specs 0))
      (dolist (f (files-under (data-path "lh/assumptions/") "hs"))
        (multiple-value-bind (ss errs) (parse-spec-text (yale-liquid::read-file-string f) :name (namestring f))
          (incf n (length (extract-spec-comments (yale-liquid::read-file-string f))))
          (incf specs (length ss))
          (dolist (e errs) (incf bad) (fail "~a" e))))
      (format t "  ~d/~d spec comments parse (~d specifications)~%" (- n bad) n specs)))
  (section "LiquidHaskell test annotations (lh/annotations)"
    (let ((expected (expected-list (data-path "lh/expected-parse-failures.txt")))
          (total 0) (ok 0) (now-ok '()))
      (dolist (f (files-under (data-path "lh/annotations/") "txt"))
        (let ((dir-total 0) (dir-ok 0) (file nil) (yale-liquid::*spec-fixities* nil))
          (dolist (c (annotation-chunks f))
            (let* ((loc (car c))
                   (this-file (subseq loc 0 (position #\: loc)))
                   (text (cdr c)))
              (unless (equal this-file file)
                (setf file this-file yale-liquid::*spec-fixities* nil))
              (incf dir-total)
              (let ((r (first (extract-spec-comments text))))
                (handler-case
                    (progn (yale-liquid::parse-spec-region text (car r) (cdr r) :name loc)
                           (incf dir-ok)
                           (when (member loc expected :test #'string=) (push loc now-ok)))
                  (liquid-parse-error (e)
                    (cond (*record-parse-failures* (push loc *record-parse-failures*))
                          ((not (member loc expected :test #'string=))
                           (fail "~a: ~a" loc e))))))))
          (incf total dir-total) (incf ok dir-ok)
          (format t "  ~20a ~5d/~5d (~5,1f%)~%" (pathname-name f) dir-ok dir-total
                  (if (plusp dir-total) (* 100.0 (/ dir-ok dir-total)) 100.0))))
      (format t "  total                ~5d/~5d (~5,1f%)~%" ok total (* 100.0 (/ ok (max 1 total))))
      (when now-ok
        (format t "  note: ~d comments listed as expected failures now parse~%" (length now-ok))))))

;;; ------------------------------------------------------------------
;;; 3. Z3 and the fixpoint solver

(defun z3-tests ()
  (section "validity checks with Z3"
    (flet ((v (goal hyps vars) (check-valid goal :hyps hyps :vars vars)))
      (check (eq (v "x >= 0" '("x > 0") '(("x" . :int))) :valid))
      (check (eq (v "x > 0" '("x >= 0") '(("x" . :int))) :invalid))
      (check (eq (v "v = x + y" '("x > 0" "y > 0" "v > x") '(("x" . :int) ("y" . :int) ("v" . :int))) :invalid))
      (check (eq (v "Set_mem x (Set_cup s (Set_sng x))" '() '(("x" . :int) ("s" . (:tc "Set_Set" :int))))
                 :valid))
      (check (eq (check-valid "len xs >= 0" :hyps '("len xs > 0") :vars '(("xs" . (:tc "[]" :int)))
                              :consts (list (cons "len" (parse-sort-string "func(1, [[@(0)]; int])"))))
                 :valid))))
  (section "fixpoint solver on liquid-fixpoint's tests (fq/pos, fq/neg)"
    (let ((expected (expected-list (data-path "fq/expected-failures.txt"))))
      (dolist (dir '(("pos" :safe) ("neg" :unsafe)))
        (let ((n 0) (ok 0) (xfail 0) (xpass '()))
          (dolist (f (files-under (data-path (format nil "fq/~a/" (first dir))) "fq"))
            (let* ((name (format nil "~a/~a.fq" (first dir) (pathname-name f)))
                   (r (handler-case (solve-fq-file f)
                        (error (e) (yale-liquid::make-fixpoint-result :status :crash
                                                                      :message (princ-to-string e)))))
                   (good (eq (result-status r) (second dir)))
                   (listed (member name expected :test #'string=)))
              (incf n)
              (cond ((and good listed) (incf ok) (push name xpass))
                    (good (incf ok))
                    (listed (incf xfail))
                    (t (fail "~a: ~a ~a ~a" name (result-status r) (result-unsafe-ids r)
                             (subseq (result-message r) 0 (min 300 (length (result-message r)))))))))
          (format t "  ~a: ~d/~d ~a (~d listed as expected failures)~%" (first dir) ok n
                  (if (eq (second dir) :safe) "SAFE" "UNSAFE") xfail)
          (when xpass (format t "  note: listed but now right: ~{~a~^ ~}~%" xpass)))))))

;;; ------------------------------------------------------------------

(defun run-all ()
  (let ((*failures* 0) (*checks* 0))
    (unit-tests)
    (spec-corpus-tests)
    (if (z3-available-p)
        (z3-tests)
        (format t "~&SKIPPED: Z3 not found; the solver tests did not run~%"))
    (format t "~&~:[OK~;FAILED~]: ~d failure~:p (~d unit checks)~%" (plusp *failures*) *failures* *checks*)
    (zerop *failures*)))
