;;;; fq.lisp -- liquid-fixpoint's .fq constraint format.
;;;;
;;;; The representation follows Language.Fixpoint.Types.Constraints
;;;; (FInfo: binders, subtyping constraints SubC, well-formedness
;;;; constraints WfC, qualifiers, constants, data declarations), and the
;;;; reader is a port of defP / fInfoP in src/Language/Fixpoint/Parse.hs of
;;;; liquid-fixpoint (https://github.com/ucsd-progsys/liquid-fixpoint,
;;;; commit 0b924442ce26a8f270bffac18ba6295bc7411646).
;;;;
;;;; A .fq file is a sequence of declarations:
;;;;
;;;;   qualif Name(v:sort, x:sort ..) { pred }      candidate refinements
;;;;   constant f : sort      distinct c : sort      global symbols
;;;;   bind 3 x : {v : sort | pred}                  numbered binders
;;;;   constraint:                                   env ⊢ lhs <: rhs
;;;;     env [0; 1; 3]
;;;;     lhs {v : sort | pred}
;;;;     rhs {v : sort | pred}
;;;;     id 7 tag [..]
;;;;   wf:                                           $k's scope and sort
;;;;     env [0; 1]
;;;;     reft {v : sort | $k}
;;;;   data Name n = [ | C {f : sort, ..} | .. ]     algebraic data types
;;;;   fixpoint "--option"   cut $k   pack $k : n    define, match, expand,
;;;;   rewrite, autorewrite, defineLocal, ebind, sort (read, mostly unused)

(in-package :yale-liquid)

(defstruct (fq-constraint (:conc-name fqc-))
  id          ; integer
  env         ; list of bind ids
  lhs         ; sorted refinement (SORT VV PRED)
  rhs         ; sorted refinement
  tag         ; list of integers
  line)       ; source line

(defstruct (fq-wf (:conc-name wf-))
  kvar        ; name of the kvar (string)
  env         ; list of bind ids
  sort        ; sort of the value variable
  vv)         ; name of the value variable

(defstruct (fq-qual (:conc-name qual-))
  name
  params      ; list of (NAME SORT PATTERN); PATTERN is NIL, (:exact s),
              ; (:prefix s i) or (:suffix i s)
  body
  line)

(defstruct (fq-data (:conc-name data-))
  name        ; type constructor name
  arity       ; number of sort parameters, referred to as (:var i)
  ctors)      ; list of (CTOR-NAME ((FIELD . SORT) ..))

(defstruct fq-info
  (binds (make-hash-table))   ; id -> (NAME SORT VV PRED)
  (ebinds (make-hash-table))  ; id -> (NAME SORT)
  (constraints '())
  (wfs '())
  (quals '())
  (consts '())                ; ((NAME . SORT) ..)
  (distincts '())
  (data '())
  (options '())
  (defines '())               ; (NAME ((X . SORT) ..) SORT BODY)
  (matches '())
  (kuts '())
  (packs '())
  (expands '())
  (rewrites '())
  (sorts '()))

;;; ------------------------------------------------------------------
;;; Grammar (Parse.hs defP and friends)

(defun sorted-reft-p ()
  "Parse.hs sortedReftP: {v : sort | refa}."
  (braces (let* ((x (bind-p))
                 (s (p-sort)))
            (reserved-op "|")
            (list s x (refa-p)))))

(defun env-p ()
  (brackets (sep-by (int-p) (semi))))

(defun tag-p ()
  (reserved "tag")
  (brackets (sep-by (int-p) (semi))))

(defun qual-pattern-p ()
  (opt (progn (reserved "as")
              (alt (list :exact (symbol-p))
                   (parens (alt (let ((s (symbol-p))) (dot) (raw-string "$")
                                  (list :prefix s (int-p)))
                                (progn (raw-string "$")
                                       (let ((i (int-p))) (dot) (list :suffix i (symbol-p))))))))
       nil))

(defun qualifier-p ()
  "Parse.hs qualifierP; parameter sorts are generalized (mkQual/gSorts)."
  (let* ((line (pos-line *pos*))
         (name (upper-id))
         (params (parens (sep-by1 (let* ((x (symbol-p))
                                         (pat (qual-pattern-p)))
                                    (colon)
                                    (list x (p-sort) pat))
                                  (comma))))
         (body (braces (expr-p))))
    (let ((sorts (generalize-sorts (mapcar #'second params))))
      (make-fq-qual :name name
                    :params (mapcar (lambda (p s) (list (first p) s (third p))) params sorts)
                    :body body :line line))))

(defun data-decl-p ()
  (let* ((name (let ((tc (ftycon-p))) (if (keywordp tc) (sort->string tc) tc)))
         (n (int-p)))
    (reserved-op "=")
    (make-fq-data
     :name name :arity n
     :ctors (brackets (many (progn (reserved-op "|")
                                   (let ((c (symbol-p)))
                                     (list c (braces (sep-by (let ((f (symbol-p)))
                                                               (colon)
                                                               (cons f (p-sort)))
                                                             (comma)))))))))))

(defun bool-p () (alt (progn (reserved "True") t) (progn (reserved "False") nil)))

(defun pairs-p (a b)
  (brackets (sep-by (let ((x (funcall a))) (reserved ":") (cons x (funcall b))) (semi))))

(defun def-p (info)
  "One declaration; records it in INFO."
  (alt
   (progn (reserved "sort") (colon) (push (p-sort) (fq-info-sorts info)))
   (progn (reserved "constraint") (colon)
          (let ((line (pos-line *pos*)))
            (reserved "env")
            (let ((env (env-p)))
              (reserved "lhs")
              (let ((lhs (sorted-reft-p)))
                (reserved "rhs")
                (let ((rhs (sorted-reft-p)))
                  (reserved "id")
                  (let* ((id (natural)) (tag (tag-p)))
                    (push (make-fq-constraint :id id :env env :lhs lhs :rhs rhs :tag tag :line line)
                          (fq-info-constraints info))))))))
   (progn (reserved "wf") (colon) (reserved "env")
          (let ((env (env-p)))
            (reserved "reft")
            (destructuring-bind (s vv p) (sorted-reft-p)
              (unless (kvar-p p) (pfail "a kvar in a wf constraint"))
              (push (make-fq-wf :kvar (second p) :env env :sort s :vv vv)
                    (fq-info-wfs info)))))
   (progn (reserved "constant")
          (let ((x (symbol-p))) (colon) (push (cons x (p-sort)) (fq-info-consts info))))
   (progn (reserved "distinct")
          (let ((x (symbol-p))) (colon) (push (cons x (p-sort)) (fq-info-distincts info))))
   (progn (reserved "pack")
          (let ((k (kvar-name))) (colon) (push (cons k (int-p)) (fq-info-packs info))))
   (progn (reserved "qualif") (push (qualifier-p) (fq-info-quals info)))
   (progn (reserved "cut") (push (kvar-name) (fq-info-kuts info)))
   (progn (reserved "ebind")
          (let* ((i (int-p)) (x (symbol-p)))
            (colon)
            (setf (gethash i (fq-info-ebinds info)) (list x (braces (p-sort))))))
   (progn (reserved "bind")
          (let* ((i (int-p)) (x (symbol-p)))
            (colon)
            (destructuring-bind (s vv p) (sorted-reft-p)
              (setf (gethash i (fq-info-binds info)) (list x s vv p)))))
   (progn (reserved "fixpoint") (push (string-literal-p) (fq-info-options info)))
   (progn (reserved "defineLocal")
          (let ((i (int-p)))
            (push (list :local i (brackets (sep-by (let ((x (symbol-p)))
                                                     (reserved ":=")
                                                     (cons x (expr-p)))
                                                   (reserved ";"))))
                  (fq-info-rewrites info))))
   (progn (reserved "define")
          (let* ((name (symbol-p))
                 (params (parens (sep-by (let ((x (symbol-p))) (colon) (cons x (p-sort)))
                                         (comma)))))
            (colon)
            (let ((s (p-sort)))
              (reserved "=")
              (push (list name params s (braces (expr-p))) (fq-info-defines info)))))
   (progn (reserved "match")
          (let* ((f (symbol-p)) (c (symbol-p)) (xs (many (symbol-p))))
            (push (list f c xs (braces (expr-p))) (fq-info-matches info))))
   (progn (reserved "expand")
          (setf (fq-info-expands info) (append (fq-info-expands info)
                                               (pairs-p #'int-p #'bool-p))))
   (progn (reserved "data") (push (data-decl-p) (fq-info-data info)))
   (progn (reserved "autorewrite")
          (let* ((i (int-p))
                 (args (many (sorted-reft-p))))
            (reserved "=")
            (push (list :auto i args (braces (expr-p))) (fq-info-rewrites info))))
   (progn (reserved "rewrite")
          (push (list :map (pairs-p #'int-p #'int-p)) (fq-info-rewrites info)))))

(defun read-fq-string (text &key name)
  "Parse TEXT in .fq format into an FQ-INFO."
  (let ((info (make-fq-info)))
    (with-parse-input (text :name name)
      (let ((*fixities* (builtin-fixities)))
        (skip-spaces)
        (loop until (eof-p)
              do (multiple-value-bind (v ok) (attempt (def-p info))
                   (declare (ignore v))
                   (unless ok (signal-parse-failure))))))
    (dolist (slot '(constraints wfs quals consts distincts data options defines
                    matches kuts packs rewrites sorts))
      (let ((acc (intern (format nil "FQ-INFO-~a" slot) :yale-liquid)))
        (funcall (fdefinition (list 'setf acc)) (reverse (funcall acc info)) info)))
    info))

(defun read-file-string (path)
  (with-open-file (in path :external-format :utf-8)
    (let* ((s (make-string (file-length in)))
           (n (read-sequence s in)))
      (subseq s 0 n))))

(defun read-fq-file (path)
  (read-fq-string (read-file-string path) :name (namestring path)))

;;; ------------------------------------------------------------------
;;; Printing an FQ-INFO back in .fq syntax

(defun print-fq (info &optional (stream *standard-output*))
  (dolist (o (fq-info-options info)) (format stream "fixpoint ~s~%" o))
  (dolist (q (fq-info-quals info))
    (format stream "qualif ~a(~{~a~^, ~}) { ~a }~%" (qual-name q)
            (mapcar (lambda (p) (format nil "~a:~a" (first p) (sort->string (second p))))
                    (qual-params q))
            (expr->string (qual-body q))))
  (dolist (d (fq-info-data info))
    (format stream "data ~a ~d = [~{~%  | ~a~}~%]~%" (data-name d) (data-arity d)
            (mapcar (lambda (c)
                      (format nil "~a {~{~a~^, ~}}" (first c)
                              (mapcar (lambda (f) (format nil "~a : ~a" (car f) (sort->string (cdr f))))
                                      (second c))))
                    (data-ctors d))))
  (dolist (c (fq-info-consts info))
    (format stream "constant ~a : (~a)~%" (car c) (sort->string (cdr c))))
  (dolist (c (fq-info-distincts info))
    (format stream "distinct ~a : (~a)~%" (car c) (sort->string (cdr c))))
  (let ((ids (sort (loop for k being the hash-keys of (fq-info-binds info) collect k) #'<)))
    (dolist (i ids)
      (destructuring-bind (x s vv p) (gethash i (fq-info-binds info))
        (format stream "bind ~d ~a : ~a~%" i x (sorted-reft->string (list s vv p))))))
  (dolist (c (fq-info-constraints info))
    (format stream "~%constraint:~%  env [~{~d~^; ~}]~%  lhs ~a~%  rhs ~a~%  id ~d tag [~{~d~^; ~}]~%"
            (fqc-env c) (sorted-reft->string (fqc-lhs c)) (sorted-reft->string (fqc-rhs c))
            (fqc-id c) (fqc-tag c)))
  (dolist (w (fq-info-wfs info))
    (format stream "~%wf:~%  env [~{~d~^; ~}]~%  reft {~a : ~a | $~a}~%"
            (wf-env w) (wf-vv w) (sort->string (wf-sort w)) (wf-kvar w))))
