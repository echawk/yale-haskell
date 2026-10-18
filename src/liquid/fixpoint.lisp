;;;; fixpoint.lisp -- the fixpoint solver: predicate abstraction over
;;;; qualifiers.
;;;;
;;;; A port of the non-eliminating path of liquid-fixpoint's solver
;;;; (https://github.com/ucsd-progsys/liquid-fixpoint, commit
;;;; 0b924442ce26a8f270bffac18ba6295bc7411646; the default --eliminate=none):
;;;;
;;;;   1. Each subtyping constraint env ⊢ {v|p} <: {v|q1 ∧ .. ∧ qn} is split
;;;;      into one simple constraint per right-hand kvar plus one with the
;;;;      concrete conjuncts (Types/Constraints.hs subC, reftConjuncts).
;;;;   2. Every kvar starts as the conjunction of all well-sorted instances of
;;;;      the qualifiers over its wf environment and the global constants
;;;;      (Solver/Solution.hs init, instK, okInst).
;;;;   3. A worklist repeatedly takes a constraint whose right-hand side is a
;;;;      kvar and keeps only the candidates that its left-hand side
;;;;      implies, one SMT validity query each (Solver/Solve.hs refine,
;;;;      refineC, filterValid); constraints that read a weakened kvar are
;;;;      queued again.
;;;;   4. At the fixpoint the constraints with concrete right-hand sides are
;;;;      checked (Solver/Solve.hs result_, isUnsat): all valid is SAFE,
;;;;      otherwise UNSAFE with the failing constraint ids.
;;;;
;;;; Not ported: kvar elimination (--eliminate), PLE and rewriting
;;;; (--rewrite, define/match/expand), extensionality, the interpreter, and
;;;; environment reduction.  Hypotheses that do not sort-check are dropped
;;;; (sound), goals that do not sort-check count as not valid.

(in-package :yale-liquid)

(defstruct (fixpoint-result (:conc-name result-))
  status            ; :safe, :unsafe or :crash
  unsafe-ids        ; ids of the failing constraints
  solution          ; hash kvar -> predicate
  message           ; text for :crash
  (queries 0)
  (iterations 0))

(defstruct (simp-c (:conc-name sc-))
  id                ; the original constraint's id
  env               ; bind ids
  vv vv-sort        ; the value variable (renamed apart) and its sort
  lhs               ; left-hand predicate, in terms of VV
  rhs               ; right-hand predicate: one kvar, or concrete
  kvar              ; the rhs kvar (:kvar k su), or NIL
  reads)            ; kvar names read by env and lhs

(defstruct (solver (:conc-name sv-))
  info genv ctx z3
  (sol (make-hash-table :test 'equal))   ; kvar -> list of candidate predicates
  (wfs (make-hash-table :test 'equal))   ; kvar -> fq-wf
  (bind-locals (make-hash-table))        ; cache: bind id -> (name . sort)
  (dropped 0)
  (crash-notes '()))

;;; ------------------------------------------------------------------
;;; Constraints

(defun split-constraint (c)
  (destructuring-bind (ls lvv lp) (fqc-lhs c)
    (declare (ignore ls))
    (destructuring-bind (rs rvv rp) (fqc-rhs c)
      (let* ((vv (format nil "VV#~d" (fqc-id c)))
             (lhs (reft-pred-at lvv lp vv))
             (rhs (reft-pred-at rvv rp vv))
             (parts (conjuncts rhs))
             (ks (remove-if-not #'kvar-p parts))
             (concrete (remove-if #'kvar-p parts)))
        (flet ((mk (r k) (make-simp-c :id (fqc-id c) :env (fqc-env c) :vv vv :vv-sort rs
                                      :lhs lhs :rhs r :kvar k)))
          (append (mapcar (lambda (k) (mk k k)) ks)
                  (when (or concrete (null ks))
                    (list (mk (pred-and-list concrete) nil)))))))))

(defun bind-of (sv id)
  (or (gethash id (fq-info-binds (sv-info sv)))
      (error "unknown bind ~d" id)))

(defun usable-local-p (sv x s)
  "Binders that are not local variables in SMT: polymorphic ones
constants (func(n, [t]) with n > 0, whose SMT sort would vary) and ones that rebind a constructor, selector,
tester or theory symbol (the global meaning is kept)."
  (not (or (and (func-sort-p s) (plusp (second s)) (null (third s)))
           (member (global-kind (sv-genv sv) x) '(:ctor :selector :tester :theory)))))

(defun constraint-locals (sv c)
  "((name . sort) ..) for the binders of C, the last binding of a name
winning, then the value variable."
  (let ((acc '()))
    (dolist (id (sc-env c))
      (destructuring-bind (x s vv p) (bind-of sv id)
        (declare (ignore vv p))
        (setf acc (remove x acc :key #'car :test #'string=))
        (when (usable-local-p sv x s)
          (push (cons x s) acc))))
    (resolve-sort-binders (cons (cons (sc-vv c) (sc-vv-sort c))
                                (remove (sc-vv c) acc :key #'car :test #'string=))
                          (sv-genv sv))))

(defun effective-binds (sv c)
  "The bind ids of C's environment whose binders are local variables.  As
upstream, binders with the same name and sort are the same variable, so
all their refinements are assumed."
  (remove-duplicates
   (remove-if-not (lambda (id) (destructuring-bind (x s &rest r) (bind-of sv id)
                                 (declare (ignore r))
                                 (usable-local-p sv x s)))
                  (sc-env c))
   :from-end t))

(defun constraint-reads (sv c)
  (let ((ks '()))
    (dolist (id (sc-env c))
      (dolist (k (kvars-of (fourth (bind-of sv id))))
        (pushnew (second k) ks :test #'string=)))
    (dolist (k (kvars-of (sc-lhs c)))
      (pushnew (second k) ks :test #'string=))
    ks))

;;; ------------------------------------------------------------------
;;; Solutions

(defun apply-solution (sv p)
  "P with each kvar replaced by its current solution (substituted)."
  (map-expr (lambda (e)
              (if (kvar-p e)
                  (multiple-value-bind (cands found) (gethash (second e) (sv-sol sv))
                    (if found
                        (subst (pred-and-list cands) (third e))
                        :true))
                  e))
            p))

(defun hypotheses (sv c)
  "The conjuncts that C's environment and left-hand side assume."
  (let ((hyps '()))
    (dolist (id (effective-binds sv c))
      (destructuring-bind (x s vv p) (bind-of sv id)
        (declare (ignore s))
        (unless (string= x (sc-vv c))
          (setf hyps (append hyps (conjuncts (apply-solution sv (reft-pred-at vv p x))))))))
    (append hyps (conjuncts (apply-solution sv (sc-lhs c))))))

;;; ------------------------------------------------------------------
;;; Qualifier instantiation (Solver/Solution.hs instK, instKSig, okInst)

(defun qualifier-candidates (sv)
  "Global constants that may instantiate qualifier parameters."
  (let ((ho (sym-env-allow-ho (sv-genv sv))))
    (loop for (x . s) in (fq-info-consts (sv-info sv))
          unless (or (lit-symbol-p x) (and (not ho) (func-sort-p s)))
            collect (cons x s))))

(defun sorts-compatible-p (pairs)
  "Do the (QUALIFIER-SORT . CANDIDATE-SORT) PAIRS unify simultaneously?
Qualifier sort variables (:var i) are shared across the pairs."
  (with-elaboration (nil)
    (let ((vars (make-hash-table)))
      (flet ((inst (s)
               (map-sort (lambda (x)
                           (if (and (consp x) (eq (car x) :var))
                               (or (gethash (second x) vars)
                                   (setf (gethash (second x) vars) (fresh-uv)))
                               x))
                         s)))
        (handler-case (progn (dolist (p pairs) (unify (inst (car p)) (cdr p))) t)
          (sort-error () nil))))))

(defun match-pattern (pat name)
  (or (null pat)
      (ecase (first pat)
        (:exact (string= (second pat) name))
        (:prefix (let ((s (second pat))) (and (> (length name) (length s)) (string= s name :end2 (length s)))))
        (:suffix (let ((s (third pat))) (and (> (length name) (length s))
                                             (string= s name :start2 (- (length name) (length s)))))))))

(defun instantiate-kvar (sv w)
  "The initial candidate predicates of the kvar of wf W."
  (let* ((vv (wf-vv w))
         (env-binds (resolve-sort-binders
                     (loop for id in (wf-env w)
                           for (x s) = (bind-of sv id)
                           unless (or (string= x vv) (not (usable-local-p sv x s)))
                             collect (cons x s))
                     (sv-genv sv)))
         (vsort (cdr (first (resolve-sort-binders (cons (cons vv (wf-sort w)) env-binds)
                                                  (sv-genv sv)))))
         (cands (append env-binds
                        (remove-if (lambda (p) (assoc (car p) env-binds :test #'string=))
                                   (qualifier-candidates sv))))
         (groups '())
         (locals (cons (cons vv vsort) (append env-binds (qualifier-candidates sv))))
         (out '()))
    ;; group candidates by sort (as instCands does)
    (dolist (c (reverse cands))
      (let ((g (assoc (cdr c) groups :test #'equal)))
        (if g (push (car c) (cdr g)) (push (list (cdr c) (car c)) groups))))
    (dolist (q (fq-info-quals (sv-info sv)))
      (let ((params (qual-params q)))
        (labels ((search-params (rest pairs names)
                   ;; RAST: remaining params; PAIRS: sort constraints so far;
                   ;; NAMES: chosen symbol lists (one list of alternatives per param)
                   (if (null rest)
                       (emit (reverse names))
                       (destructuring-bind (px psort pat) (first rest)
                         (declare (ignore px))
                         (dolist (g groups)
                           (let ((pairs2 (cons (cons psort (car g)) pairs)))
                             (when (sorts-compatible-p pairs2)
                               (let ((ok (remove-if-not (lambda (n) (match-pattern pat n)) (cdr g))))
                                 (when ok
                                   (search-params (rest rest) pairs2 (cons ok names))))))))))
                 (emit (alternatives)
                   (labels ((walk (alts chosen)
                              (if (null alts)
                                  (let* ((names (reverse chosen))
                                         (su (mapcar (lambda (p n) (cons (first p) n))
                                                     params (cons vv names)))
                                         (pred (subst (qual-body q) su)))
                                    (pushnew pred out :test #'equal))
                                  (dolist (n (car alts))
                                    (walk (cdr alts) (cons n chosen))))))
                     (walk alternatives '()))))
          (when (and params
                     (sorts-compatible-p (list (cons (second (first params)) vsort)))
                     (match-pattern nil vv))
            (search-params (rest params) (list (cons (second (first params)) vsort)) '())))))
    ;; okInst: keep the well-sorted instances
    (let ((genv (sv-genv sv)))
      (remove-if-not (lambda (p) (well-sorted-p p locals genv)) (nreverse out)))))

;;; ------------------------------------------------------------------
;;; SMT queries

(defun local-smt-names (sv locals)
  (let ((genv (sv-genv sv)))
    (mapcar (lambda (p)
              (let ((x (car p)))
                (cons x (smt-symbol (if (or (global-sort genv x)
                                            (member x *smt-reserved* :test #'string=))
                                        (format nil "~a@local" x)
                                        x)))))
            locals)))

(defun encode-pred (sv p locals names)
  "Elaborate and encode P; NIL (and a note) if it does not sort-check."
  (handler-case
      (let ((te (elaborate p locals (sv-genv sv))))
        (multiple-value-list (formula->smt2 te (sv-ctx sv) names)))
    (sort-error (c)
      (incf (sv-dropped sv))
      (push (format nil "~a in ~a" (sort-error-message c) (expr->string p)) (sv-crash-notes sv))
      nil)))

(defun filter-valid (sv c candidates)
  "The CANDIDATES that the hypotheses of C imply.  Each candidate is a
pair (PRED . KEY); KEYs of the valid ones are returned."
  (let* ((z (sv-z3 sv))
         (locals (constraint-locals sv c))
         (names (local-smt-names sv locals))
         (hyps (remove nil (mapcar (lambda (h) (encode-pred sv h locals names))
                                   (hypotheses sv c))))
         (goals (mapcar (lambda (cand) (cons (encode-pred sv (car cand) locals names) (cdr cand)))
                        candidates))
         (valid '()))
    ;; global declarations at the outer scope
    (dolist (e (append hyps (remove nil (mapcar #'car goals))))
      (dolist (d (second e)) (z3-declare z d)))
    (with-z3-scope (z)
      (dolist (p locals)
        (z3-command z (format nil "(declare-const ~a ~a)" (cdr (assoc (car p) names :test #'string=))
                              (smt-sort (cdr p) (sv-ctx sv)))))
      (dolist (h hyps) (z3-command z (format nil "(assert ~a)" (first h))))
      (dolist (g goals)
        (when (car g)
          (let ((r (handler-case
                       (with-z3-scope (z)
                         (z3-command z (format nil "(assert (not ~a))" (first (car g))))
                         (z3-check-sat z))
                     (smt-error (e)
                       (push (princ-to-string e) (sv-crash-notes sv))
                       :error))))
            (when (eq r :unsat) (push (cdr g) valid))))))
    (nreverse valid)))

(defun kvar-candidates (sv c)
  "The current candidates of C's rhs kvar, as (instantiated-pred . pred)."
  (let ((k (sc-kvar c)))
    (mapcar (lambda (p) (cons (subst p (third k)) p))
            (gethash (second k) (sv-sol sv)))))

;;; ------------------------------------------------------------------
;;; The solver

(defun option-p (info opt)
  (member opt (fq-info-options info) :test #'string=))

(defun solve-fq (info &key log (verbose nil))
  "Solve the constraints of FQ-INFO.  Returns a FIXPOINT-RESULT."
  (let* ((genv (make-global-env :consts (append (fq-info-consts info) (fq-info-distincts info))
                                :data (fq-info-data info)
                                :allow-ho (option-p info "--allowho")))
         (ctx (make-smt-ctx :genv genv))
         (sv (make-solver :info info :genv genv :ctx ctx))
         (cs (mapcan #'split-constraint (fq-info-constraints info)))
         (iterations 0))
    (with-z3 (z :log log)
      (setf (sv-z3 sv) z)
      (let ((dd (datatype-decls ctx)))
        (when dd (z3-command z dd)))
      (assert-distincts sv)
      (dolist (w (fq-info-wfs info))
        (setf (gethash (wf-kvar w) (sv-wfs sv)) w
              (gethash (wf-kvar w) (sv-sol sv)) (instantiate-kvar sv w)))
      (dolist (c cs) (setf (sc-reads c) (constraint-reads sv c)))
      ;; refine
      (let* ((kcs (remove-if-not #'sc-kvar cs))
             (queue (copy-list kcs))
             (queued (make-hash-table :test 'eq)))
        (dolist (c queue) (setf (gethash c queued) t))
        (loop while queue
              do (let ((c (pop queue)))
                   (remhash c queued)
                   (incf iterations)
                   (let* ((k (second (sc-kvar c)))
                          (old (gethash k (sv-sol sv))))
                     (when (and old (gethash k (sv-wfs sv)))
                       (let ((new (filter-valid sv c (kvar-candidates sv c))))
                         (when (< (length new) (length old))
                           (when verbose
                             (format t "~&iter ~d: id ~d: $~a ~d -> ~d~%" iterations (sc-id c) k
                                     (length old) (length new)))
                           (setf (gethash k (sv-sol sv)) new)
                           (dolist (d kcs)
                             (when (and (member k (sc-reads d) :test #'string=)
                                        (not (gethash d queued)))
                               (setf (gethash d queued) t)
                               (setf queue (append queue (list d))))))))))))
      ;; result
      (let ((bad '()))
        (dolist (c cs)
          (unless (sc-kvar c)
            (unless (eq (sc-rhs c) :true)
              (when (null (filter-valid sv c (list (cons (sc-rhs c) t))))
                (pushnew (sc-id c) bad)))))
        (let ((solution (make-hash-table :test 'equal)))
          (maphash (lambda (k v) (setf (gethash k solution) (pred-and-list v))) (sv-sol sv))
          (make-fixpoint-result :status (if bad :unsafe :safe)
                                :unsafe-ids (sort bad #'<)
                                :solution solution
                                :message (format nil "~{~a~^~%~}" (reverse (sv-crash-notes sv)))
                                :queries (z3-queries z)
                                :iterations iterations))))))

(defun assert-distincts (sv)
  (let ((groups '()))
    (dolist (d (fq-info-distincts (sv-info sv)))
      (unless (func-sort-p (cdr d))
        (let ((g (assoc (cdr d) groups :test #'equal)))
          (if g (push (car d) (cdr g)) (push (list (cdr d) (car d)) groups)))))
    (dolist (g groups)
      (when (cddr g)
        (let ((terms (mapcar (lambda (x)
                               (let ((e (encode-pred* sv x)))
                                 (dolist (d (second e)) (z3-declare (sv-z3 sv) d))
                                 (first e)))
                             (cdr g))))
          (z3-command (sv-z3 sv) (format nil "(assert (distinct~{ ~a~}))" terms)))))))

(defun encode-pred* (sv x)
  (multiple-value-list
   (formula->smt2 (elaborate x '() (sv-genv sv) :expect nil) (sv-ctx sv) '())))

(defun solve-fq-file (path &rest keys)
  "Read and solve the .fq file at PATH."
  (let ((info (handler-case (read-fq-file path)
                (liquid-parse-error (e)
                  (return-from solve-fq-file
                    (make-fixpoint-result :status :crash :message (princ-to-string e)))))))
    (apply #'solve-fq info keys)))
