;;;; parse-base.lisp -- a small backtracking, layout-aware parser kit.
;;;;
;;;; The grammars of .fq files and of LiquidHaskell specifications are
;;;; written in megaparsec in upstream (liquid-fixpoint's
;;;; src/Language/Fixpoint/Parse.hs at commit
;;;; 0b924442ce26a8f270bffac18ba6295bc7411646).  This file provides the
;;;; same primitives in Common Lisp so that the grammar can be ported
;;;; nearly rule by rule:
;;;;
;;;;   - parsers are ordinary functions of no arguments that read the
;;;;     special variables below and either return a value or call
;;;;     PFAIL, which throws to the nearest ALT / ATTEMPT;
;;;;   - every alternative backtracks (megaparsec needs `try' for that;
;;;;     here it is the default), restoring the position, the layout
;;;;     stack and the user state (operator fixities, unique supply);
;;;;   - LEXEME skips whitespace and comments (// and nested /* */)
;;;;     after a token and checks the layout stack before it, exactly as
;;;;     upstream's lexeme' / guardLayout do;
;;;;   - columns are 1-based and computed against the whole source text,
;;;;     so a {-@ ... @-} comment can be parsed in place inside a Haskell
;;;;     file and its layout columns are the file's.

(in-package :yale-liquid)

(defvar *src* "" "The text being parsed.")
(defvar *pos* 0 "The current index into *SRC*.")
(defvar *end* 0 "The end of the region of *SRC* being parsed.")
(defvar *line-starts* #(0) "Indices at which the lines of *SRC* start.")
(defvar *layout* '() "Layout stack: (:at . col), (:after . col) or (:reset).")
(defvar *fixities* '() "Operator table entries: (prec name kind fn assoc).")
(defvar *supply* 0 "Unique supply for parser-generated names.")
(defvar *furthest* 0 "Furthest position at which a parser failed.")
(defvar *expected* '() "What was expected at *FURTHEST*.")
(defvar *source-name* nil "File name for error messages.")
;; LiquidHaskell parses [] and [e] in expressions; liquid-fixpoint does not.
(defvar *list-syntax* nil)
(defvar *allow-exists* t)

(define-condition liquid-parse-error (error)
  ((file :initarg :file :reader parse-error-file :initform nil)
   (line :initarg :line :reader parse-error-line)
   (column :initarg :column :reader parse-error-column)
   (expected :initarg :expected :reader parse-error-expected)
   (text :initarg :text :reader parse-error-text :initform ""))
  (:report (lambda (c s)
             (format s "~@[~a:~]~d:~d: parse error~@[, expected ~{~a~^ or ~}~]~@[ at ~s~]"
                     (parse-error-file c) (parse-error-line c) (parse-error-column c)
                     (parse-error-expected c)
                     (let ((tx (parse-error-text c)))
                       (and (plusp (length tx)) tx))))))

(deftype parse-error-condition () 'liquid-parse-error)

(defun compute-line-starts (text)
  (let ((starts (list 0)))
    (loop for i from 0 below (length text)
          when (char= (char text i) #\Newline) do (push (1+ i) starts))
    (coerce (nreverse starts) 'vector)))

(defun line-index (pos)
  "The 0-based line containing POS (binary search in *LINE-STARTS*)."
  (let ((lo 0) (hi (1- (length *line-starts*))))
    (loop while (< lo hi)
          do (let ((mid (ceiling (+ lo hi) 2)))
               (if (<= (aref *line-starts* mid) pos)
                   (setf lo mid)
                   (setf hi (1- mid)))))
    lo))

(defun pos-line (pos) (1+ (line-index pos)))
(defun pos-column (pos) (1+ (- pos (aref *line-starts* (line-index pos)))))
(defun current-column () (pos-column *pos*))

(defmacro with-parse-input ((text &key (start 0) end name) &body body)
  "Run BODY parsing TEXT from START to END with fresh parser state."
  (let ((tx (gensym)))
    `(let* ((,tx ,text)
            (*src* ,tx)
            (*pos* ,start)
            (*end* (or ,end (length ,tx)))
            (*line-starts* (compute-line-starts ,tx))
            (*layout* '())
            (*supply* 0)
            (*furthest* ,start)
            (*expected* '())
            (*source-name* ,name))
       ,@body)))

;;; ------------------------------------------------------------------
;;; Failure and backtracking

(defun pfail (&optional expected)
  (cond ((> *pos* *furthest*)
         (setf *furthest* *pos* *expected* (and expected (list expected))))
        ((and (= *pos* *furthest*) expected)
         (pushnew expected *expected* :test #'equal)))
  (throw 'pfail nil))

(defun signal-parse-failure ()
  (let ((p (min *furthest* (max 0 (1- (length *src*))))))
    (error 'liquid-parse-error
           :file *source-name*
           :line (pos-line *furthest*) :column (pos-column *furthest*)
           :expected (reverse *expected*)
           :text (subseq *src* (min p (length *src*))
                         (min (length *src*) (+ p 30)
                              (or (position #\Newline *src* :start (min p (length *src*)))
                                  (length *src*)))))))

(defmacro attempt (&body body)
  "Run BODY; on failure restore the parser state.  Returns (values VALUE T)
on success and (values NIL NIL) on failure."
  (let ((pos (gensym)) (lay (gensym)) (fix (gensym)) (sup (gensym))
        (ok (gensym)) (val (gensym)))
    `(let ((,pos *pos*) (,lay *layout*) (,fix *fixities*) (,sup *supply*)
           (,ok nil) (,val nil))
       (catch 'pfail
         (setf ,val (progn ,@body) ,ok t))
       (unless ,ok
         (setf *pos* ,pos *layout* ,lay *fixities* ,fix *supply* ,sup))
       (values ,val ,ok))))

(defmacro alt (&rest forms)
  "The value of the first of FORMS that succeeds (each one backtracks)."
  (let ((blk (gensym)))
    `(block ,blk
       ,@(mapcar (lambda (f)
                   (let ((v (gensym)) (ok (gensym)))
                     `(multiple-value-bind (,v ,ok) (attempt ,f)
                        (when ,ok (return-from ,blk ,v)))))
                 forms)
       (pfail))))

(defmacro opt (form &optional default)
  (let ((v (gensym)) (ok (gensym)))
    `(multiple-value-bind (,v ,ok) (attempt ,form)
       (if ,ok ,v ,default))))

(defmacro succeeds (form)
  "True when FORM parses (its input is consumed), else false (restored)."
  (let ((ok (gensym)))
    `(multiple-value-bind (v ,ok) (attempt ,form) (declare (ignore v)) ,ok)))

(defmacro many (form)
  "Zero or more FORMs; stops at the first failure or when no input is
consumed."
  (let ((acc (gensym)) (v (gensym)) (ok (gensym)) (start (gensym)))
    `(let ((,acc '()))
       (loop
         (let ((,start *pos*))
           (multiple-value-bind (,v ,ok) (attempt ,form)
             (unless ,ok (return))
             (push ,v ,acc)
             (when (= *pos* ,start) (return)))))
       (nreverse ,acc))))

(defmacro many1 (form)
  (let ((x (gensym)))
    `(let ((,x ,form)) (cons ,x (many ,form)))))

(defmacro sep-by1 (form sep)
  (let ((x (gensym)))
    `(let ((,x ,form))
       (cons ,x (many (progn ,sep ,form))))))

(defmacro sep-by (form sep)
  `(opt (sep-by1 ,form ,sep) '()))

(defmacro sep-end-by (form sep)
  "Items separated and optionally terminated by SEP (megaparsec sepEndBy)."
  (let ((acc (gensym)) (v (gensym)) (ok (gensym)))
    `(let ((,acc '()))
       (loop
         (multiple-value-bind (,v ,ok) (attempt ,form)
           (unless ,ok (return))
           (push ,v ,acc)
           (unless (succeeds ,sep) (return))))
       (nreverse ,acc))))

(defmacro sep-end-by1 (form sep)
  (let ((r (gensym)))
    `(let ((,r (sep-end-by ,form ,sep)))
       (if ,r ,r (pfail)))))

(defun eof-p () (>= *pos* *end*))
(defun expect-eof () (unless (eof-p) (pfail "end of input")))

(defun peek (&optional (offset 0))
  (let ((i (+ *pos* offset)))
    (and (< i *end*) (char *src* i))))

(defun match-string-p (s)
  (let ((e (+ *pos* (length s))))
    (and (<= e *end*) (string= s *src* :start2 *pos* :end2 e))))

(defun raw-string (s)
  "Match S exactly (no whitespace handling)."
  (if (match-string-p s)
      (progn (incf *pos* (length s)) s)
      (pfail (format nil "~s" s))))

(defun raw-char-if (pred &optional what)
  (let ((c (peek)))
    (if (and c (funcall pred c))
        (progn (incf *pos*) c)
        (pfail what))))

;;; ------------------------------------------------------------------
;;; Whitespace and layout (Parse.hs: spaces, guardLayout, lexeme')

(defun skip-block-comment ()
  ;; at "/*": nested block comment
  (incf *pos* 2)
  (let ((depth 1))
    (loop while (and (plusp depth) (< *pos* *end*))
          do (cond ((match-string-p "/*") (incf depth) (incf *pos* 2))
                   ((match-string-p "*/") (decf depth) (incf *pos* 2))
                   (t (incf *pos*))))))

(defun skip-spaces ()
  (loop
    (let ((c (peek)))
      (cond ((null c) (return))
            ((member c '(#\Space #\Tab #\Newline #\Return #\Page)) (incf *pos*))
            ((match-string-p "//")
             (loop while (and (< *pos* *end*) (char/= (char *src* *pos*) #\Newline))
                   do (incf *pos*)))
            ((match-string-p "/*") (skip-block-comment))
            (t (return))))))

(defun guard-layout ()
  "Check the current column against the layout stack; return the
function to run after the token (Parse.hs guardLayout)."
  (let ((top (car *layout*)))
    (case (car top)
      (:at (unless (= (current-column) (cdr top)) (pfail "layout"))
       (let ((stack *layout*) (i (cdr top)))
         (lambda () (setf *layout* (cons (cons :after i) stack)))))
      (:after (unless (> (current-column) (cdr top)) (pfail "layout"))
       nil)
      (t nil))))

(defmacro lexeme (&body body)
  (let ((after (gensym)) (v (gensym)))
    `(let* ((,after (guard-layout))
            (,v (progn ,@body)))
       (skip-spaces)
       (when ,after (funcall ,after))
       ,v)))

(defun strict-guard-layout ()
  (let ((top (car *layout*)))
    (when (member (car top) '(:at :after))
      (unless (> (current-column) (cdr top)) (pfail "indentation")))))

(defun set-layout () (push (cons :at (current-column)) *layout*))
(defun reset-layout () (push (list :reset) *layout*))
(defun pop-layout ()
  (when (null *layout*) (error "unbalanced layout stack"))
  (pop *layout*))

(defmacro indented-block (form)
  "Parse.hs indentedBlock: items laid out at one column, more indented than
the surrounding block; the empty list if there are none."
  (let ((acc (gensym)) (v (gensym)) (ok (gensym)))
    `(opt (progn
            (strict-guard-layout)
            (set-layout)
            (let ((,acc '()))
              (loop (multiple-value-bind (,v ,ok) (attempt (prog1 ,form (pop-layout)))
                      (unless ,ok (return))
                      (push ,v ,acc)))
              (pop-layout)
              (nreverse ,acc)))
          '())))

(defmacro indented-line (form)
  `(progn (set-layout) (prog1 ,form (pop-layout) (pop-layout))))

(defmacro explicit-block (open close sep form)
  `(progn (reset-layout) ,open
          (prog1 (sep-end-by ,form ,sep) ,close (pop-layout))))

(defmacro indented-or-explicit-block (open close sep form)
  `(alt (explicit-block ,open ,close ,sep ,form)
        (reduce #'append (indented-block (sep-end-by1 ,form ,sep)))))

(defun sym (s) (lexeme (raw-string s)))
(defun semi () (sym ";"))
(defun comma () (sym ","))
(defun colon () (sym ":"))
(defun dcolon () (alt (sym "::") (sym (string (code-char #x2237)))))
(defun dot () (sym "."))

(defmacro block-of (form)
  "Parse.hs block: a layout block, or { .. } with ; separators."
  `(indented-or-explicit-block (progn (sym "{") (many (semi))) (sym "}")
                               (many1 (semi)) ,form))

(defmacro parens (form) `(progn (sym "(") (prog1 ,form (sym ")"))))
(defmacro brackets (form) `(progn (sym "[") (prog1 ,form (sym "]"))))
(defmacro braces (form) `(progn (sym "{") (prog1 ,form (sym "}"))))
(defmacro angles (form) `(progn (sym "<") (prog1 ,form (sym ">"))))

;;; ------------------------------------------------------------------
;;; Tokens

(defun ident-letter-p (c) (or (alphanumericp c) (char= c #\_)))
(defun op-letter-p (c) (find c ":!#$%&*+./<=>?@\\^|-~'"))
(defun sym-char-p (c)
  ;; Language.Fixpoint.Types.Names.symChars
  (or (and (alphanumericp c) (< (char-code c) 128)) (find c "_.%#$'")
      (and (alpha-char-p c) (>= (char-code c) 128))))

(defparameter *reserved-names*
  '("SAT" "UNSAT" "true" "false" "mod" "data" "Bexp" "import" "if" "then" "else"
    "func" "autorewrite" "rewrite" "lit"
    "forall" "coerce" "exists" "module" "spec" "where" "decrease" "lazyvar"
    "LIQUID" "lazy" "local" "assert" "assume" "automatic-instances" "autosize"
    "axiomatize" "bound" "class" "define" "defineLocal" "defined" "embed"
    "expression" "include" "infix" "infixl" "infixr" "inline" "instance"
    "invariant" "measure" "newtype" "predicate" "qualif" "reflect" "type"
    "using" "with" "in")
  "Parse.hs reservedNames.")

(defun reserved-name-p (s) (member s *reserved-names* :test #'string=))

(defun reserved (word)
  "The reserved word WORD, not followed by an identifier letter."
  (lexeme
    (if (and (match-string-p word)
             (let ((c (peek (length word)))) (not (and c (ident-letter-p c)))))
        (progn (incf *pos* (length word)) word)
        (pfail word))))

(defun unicode-alias (op)
  (cond ((string= op "::") (string (code-char #x2237)))
        ((string= op "=>") (string (code-char #x21D2)))
        ((string= op "->") (string (code-char #x2192)))))

(defun reserved-op-single (op)
  (if (and (match-string-p op)
           (let ((c (peek (length op)))) (not (and c (op-letter-p c)))))
      (progn (incf *pos* (length op)) op)
      (pfail op)))

(defun reserved-op (op)
  (lexeme (let ((u (unicode-alias op)))
            (if u
                (alt (reserved-op-single op) (progn (reserved-op-single u) op))
                (reserved-op-single op)))))

(defun cond-id-raw (initial-p ok-p condition &optional (what "identifier"))
  "Parse.hs condIdR."
  (let ((start *pos*))
    (unless (and (peek) (funcall initial-p (peek))) (pfail what))
    (incf *pos*)
    (loop while (and (peek) (funcall ok-p (peek))) do (incf *pos*))
    (let ((s (subseq *src* start *pos*)))
      (if (funcall condition s)
          s
          (progn (setf *pos* start) (pfail what))))))

(defun not-reserved-p (s) (not (reserved-name-p s)))
(defun lower-or-underscore-p (c) (or (lower-case-p c) (char= c #\_)))
(defun letter-or-underscore-p (c) (or (alpha-char-p c) (char= c #\_)))

(defun upper-id-raw () (cond-id-raw #'upper-case-p #'sym-char-p (constantly t) "upper-case identifier"))
(defun lower-id-raw () (cond-id-raw #'lower-or-underscore-p #'sym-char-p #'not-reserved-p "lower-case identifier"))
(defun symbol-raw () (cond-id-raw #'letter-or-underscore-p #'sym-char-p #'not-reserved-p "identifier"))

(defun upper-id () (lexeme (upper-id-raw)))
(defun lower-id () (lexeme (lower-id-raw)))
(defun symbol-p () (lexeme (symbol-raw)))

(defun natural-raw ()
  (flet ((digits (radix)
           (let ((start *pos*))
             (loop while (and (peek) (digit-char-p (peek) radix)) do (incf *pos*))
             (when (= start *pos*) (pfail "digits"))
             (parse-integer *src* :start start :end *pos* :radix radix))))
    (cond ((and (eql (peek) #\0) (member (peek 1) '(#\x #\X)) (peek 2) (digit-char-p (peek 2) 16))
           (incf *pos* 2) (digits 16))
          ((and (eql (peek) #\0) (member (peek 1) '(#\o #\O)) (peek 2) (digit-char-p (peek 2) 8))
           (incf *pos* 2) (digits 8))
          (t (digits 10)))))

(defun natural () (lexeme (natural-raw)))
(defun int-p () (natural))
(defun integer-p ()
  (alt (progn (raw-string "-") (- (natural))) (natural)))

(defun float-raw ()
  "megaparsec's L.float: digits . digits [exponent] or digits exponent;
the value as an exact rational."
  (let ((start *pos*))
    (flet ((digits ()
             (let ((s *pos*))
               (loop while (and (peek) (digit-char-p (peek))) do (incf *pos*))
               (when (= s *pos*) (pfail "digits"))
               (subseq *src* s *pos*))))
      (let* ((int (digits))
             (frac (when (and (eql (peek) #\.) (peek 1) (digit-char-p (peek 1)))
                     (incf *pos*) (digits)))
             (expo (when (and (member (peek) '(#\e #\E))
                              (or (and (peek 1) (digit-char-p (peek 1)))
                                  (and (member (peek 1) '(#\+ #\-)) (peek 2)
                                       (digit-char-p (peek 2)))))
                     (incf *pos*)
                     (let ((sign (cond ((eql (peek) #\-) (incf *pos*) -1)
                                       ((eql (peek) #\+) (incf *pos*) 1)
                                       (t 1))))
                       (* sign (parse-integer (digits)))))))
        (unless (or frac expo) (setf *pos* start) (pfail "float"))
        (* (+ (parse-integer int)
              (if frac (/ (parse-integer frac) (expt 10 (length frac))) 0))
           (expt 10 (or expo 0)))))))

(defun string-literal-raw ()
  (raw-string "\"")
  (with-output-to-string (o)
    (loop
      (let ((c (peek)))
        (cond ((null c) (pfail "closing quote"))
              ((char= c #\") (incf *pos*) (return))
              ((char= c #\\)
               (incf *pos*)
               (let ((e (peek)))
                 (incf *pos*)
                 (case e
                   (#\n (write-char #\Newline o))
                   (#\t (write-char #\Tab o))
                   (#\\ (write-char #\\ o))
                   (#\" (write-char #\" o))
                   (#\' (write-char #\' o))
                   (t (if (and e (digit-char-p e))
                          (let ((s (1- *pos*)))
                            (loop while (and (peek) (digit-char-p (peek))) do (incf *pos*))
                            (write-char (code-char (parse-integer *src* :start s :end *pos*)) o))
                          (when e (write-char e o)))))))
              (t (incf *pos*) (write-char c o)))))))

(defun string-literal-p () (lexeme (string-literal-raw)))

(defun fresh-int ()
  (prog1 *supply* (incf *supply*)))
