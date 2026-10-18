;;;; pretty.lisp -- print sorts and expressions in liquid-fixpoint syntax.
;;;;
;;;; The output reads back with the parser in expr-parser.lisp (the
;;;; round trip is tested), and follows the concrete syntax of
;;;; liquid-fixpoint's Language.Fixpoint.Types.PrettyPrint / Parse
;;;; (liquid-fixpoint commit 0b924442ce26a8f270bffac18ba6295bc7411646).

(in-package :yale-liquid)

(defun sort->string (s)
  (cond ((eq s :int) "int")
        ((eq s :real) "real")
        ((eq s :bool) "bool")
        ((eq s :str) "Str")
        ((eq s :num) "num")
        ((eq s :frac) "frac")
        ((atom s) (princ-to-string s))
        (t (ecase (car s)
             (:var (format nil "@(~d)" (second s)))
             (:obj (second s))
             (:uv (format nil "?~d" (second s)))
             (:nat (princ-to-string (second s)))
             (:func (format nil "func(~d, [~{~a~^; ~}])" (second s)
                            (mapcar #'sort->string
                                    (append (third s) (list (fourth s))))))
             (:tc (cond ((and (equal (second s) "[]") (= (length s) 3))
                         (format nil "[~a]" (sort->string (third s))))
                        ((null (cddr s)) (second s))
                        (t (format nil "(~a~{ ~a~})" (second s)
                                   (mapcar #'sort-arg->string (cddr s))))))
             (:sapp (format nil "(~{~a~^ ~})" (mapcar #'sort-arg->string (cdr s))))))))

(defun sort-arg->string (s)
  ;; Sort arguments are atomic; func sorts get parentheses.
  (if (func-sort-p s)
      (format nil "(~a)" (sort->string s))
      (sort->string s)))

;;; Operator precedences, as in liquid-fixpoint's operator table (bops in
;;; Parse.hs): higher binds tighter.  Atoms and applications are 10.

(defun expr-prec (e)
  (cond ((integerp e) (if (minusp e) 9 11))
        ((atom e) 11)
        (t (case (car e)
             (:real (if (minusp (second e)) 9 11))
             ((:str :cast :kvar) 11)
             ((:app :lit) 10)
             (:neg 9)
             ((:* :/) 7)
             ((:+ :-) 6)
             (:mod 5)
             ((:= :/= :< :<= :> :>= :~~ :!~) 4)
             (:and 3)
             (:or 2)
             ((:=> :<=>) 1)
             (:not 10)
             ((:ite :exists :forall :lam :coerce) 0)
             (t 0)))))

(defun rel-op-string (op)
  (ecase op
    (:= "=") (:/= "!=") (:< "<") (:<= "<=") (:> ">") (:>= ">=")
    (:~~ "~~") (:!~ "!~")
    (:+ "+") (:- "-") (:* "*") (:/ "/") (:mod "mod")
    (:=> "=>") (:<=> "<=>") (:and "&&") (:or "||")))

(defun real-string (r)
  "A decimal literal for rational R: exact when R has a finite decimal
expansion (within 30 digits), else the nearest double."
  (let* ((neg (minusp r)) (a (abs r)) (int (floor a)) (frac (- a int)))
    (with-output-to-string (o)
      (when neg (write-char #\- o))
      (format o "~d." int)
      (if (zerop frac)
          (write-char #\0 o)
          (loop repeat 30
                until (zerop frac)
                do (setf frac (* frac 10))
                   (format o "~d" (floor frac))
                   (setf frac (- frac (floor frac))))))))

(defun string-literal (s)
  (with-output-to-string (o)
    (write-char #\" o)
    (loop for c across s
          do (case c
               (#\" (write-string "\\\"" o))
               (#\\ (write-string "\\\\" o))
               (#\Newline (write-string "\\n" o))
               (t (write-char c o))))
    (write-char #\" o)))

(defun expr->string (e)
  "E in liquid-fixpoint's concrete syntax."
  (with-output-to-string (o) (pp-expr e o 0)))

(defun pp-sub (e o prec)
  (if (< (expr-prec e) prec)
      (progn (write-char #\( o) (pp-expr e o 0) (write-char #\) o))
      (pp-expr e o prec)))

(defun pp-expr (e o prec)
  (declare (ignorable prec))
  (cond ((eq e :true) (write-string "true" o))
        ((eq e :false) (write-string "false" o))
        ((eq e :hole) (write-string "_" o))
        ((integerp e) (format o "~d" e))
        ((stringp e) (write-string e o))
        ((atom e) (princ e o))
        (t
         (case (car e)
           (:real (write-string (real-string (second e)) o))
           (:str (write-string (string-literal (second e)) o))
           (:lit (format o "lit ~a ~a" (string-literal (second e))
                         (sort-arg->string (third e))))
           (:app (pp-sub (second e) o 10)
                 (dolist (a (cddr e)) (write-char #\Space o) (pp-sub a o 11)))
           (:neg (write-string "-" o) (pp-sub (second e) o 10))
           ((:+ :- :* :/ :mod)
            ;; left associative: the right operand needs a tighter level
            (let ((p (expr-prec e)))
              (pp-sub (second e) o p)
              (format o " ~a " (rel-op-string (car e)))
              (pp-sub (third e) o (1+ p))))
           ((:= :/= :< :<= :> :>= :~~ :!~)
            (pp-sub (second e) o 5)
            (format o " ~a " (rel-op-string (car e)))
            (pp-sub (third e) o 5))
           ((:and :or)
            (cond ((null (cdr e)) (write-string (if (eq (car e) :and) "true" "false") o))
                  ((null (cddr e)) (pp-expr (second e) o prec))
                  (t (let ((p (expr-prec e)) (first t))
                       (dolist (x (cdr e))
                         (unless first (format o " ~a " (rel-op-string (car e))))
                         (setf first nil)
                         (pp-sub x o (1+ p)))))))
           ((:=> :<=>)
            (pp-sub (second e) o 2)
            (format o " ~a " (rel-op-string (car e)))
            (pp-sub (third e) o 1))
           (:not (write-string "not " o) (pp-sub (second e) o 11))
           (:ite (format o "if ") (pp-expr (second e) o 0)
                 (format o " then ") (pp-expr (third e) o 0)
                 (format o " else ") (pp-expr (fourth e) o 0))
           (:cast (write-char #\( o) (pp-expr (second e) o 0)
                  (format o " : ~a)" (sort->string (third e))))
           (:kvar (format o "$~a" (second e))
                  (dolist (p (third e))
                    (format o "[~a:=~a]" (car p) (expr->string (cdr p)))))
           ((:exists :forall)
            (format o "~a [~{~a~^, ~}]. " (if (eq (car e) :exists) "exists" "forall")
                    (mapcar (lambda (b) (format nil "~a:~a" (car b) (sort->string (cdr b))))
                            (second e)))
            (pp-expr (third e) o 0))
           (:lam (format o "\\~a:~a -> " (car (second e)) (sort-arg->string (cdr (second e))))
                 (pp-expr (third e) o 0))
           (:coerce (format o "coerce (~a ~~ ~a) " (sort->string (second e))
                            (sort->string (third e)))
                    (pp-sub (fourth e) o 11))
           (t (format o "~s" e))))))

(defun sorted-reft->string (sr)
  "SR = (SORT VV PRED) as {VV : SORT | PRED}."
  (destructuring-bind (sort vv pred) sr
    (format nil "{~a : ~a | ~a}" vv (sort->string sort)
            (if (eq pred :true) "true" (expr->string pred)))))
