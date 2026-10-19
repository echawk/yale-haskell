;;;; package.lisp -- the YALE-LIQUID package.
;;;;
;;;; Yale Liquid: the parts of LiquidHaskell-style refinement type checking
;;;; that do not depend on Yale's typed core (doc/plans/LIQUID-HASKELL.md):
;;;;
;;;;   logic.lisp       sorts, expressions and predicates of the refinement
;;;;                    logic, substitution (after liquid-fixpoint's
;;;;                    Language.Fixpoint.Types.{Sorts,Refinements,Substitutions})
;;;;   pretty.lisp      printing them in liquid-fixpoint's concrete syntax
;;;;   parse-base.lisp  a backtracking, layout-aware scannerless parser kit
;;;;                    (after liquid-fixpoint's Language.Fixpoint.Parse)
;;;;   expr-parser.lisp the expression, predicate and sort grammar shared by
;;;;                    .fq files and {-@ @-} specifications
;;;;   fq.lisp          the .fq constraint format: representation and reader
;;;;   spec.lisp        LiquidHaskell's {-@ ... @-} specification language
;;;;                    (after LiquidHaskell's Language.Haskell.Liquid.Parse)
;;;;   sortcheck.lisp   sort inference and elaboration (after
;;;;                    Language.Fixpoint.SortCheck)
;;;;   smt.lisp         SMT-LIB2 encoding of elaborated formulas
;;;;   z3.lisp          the Z3 process driver
;;;;   fixpoint.lisp    the fixpoint (predicate abstraction) solver
;;;;   check.lisp       checking a program against refined signatures
;;;;
;;;; Everything is plain Common Lisp; the only dependency is UIOP (part of
;;;; ASDF) for running Z3 as a subprocess.

(defpackage :yale-liquid
  (:use :common-lisp)
  (:nicknames :liquid)
  (:shadow #:subst)
  (:export
   ;; logic
   #:sort-p #:pred-and #:pred-or #:pred-not #:conjuncts #:subst #:subst1
   #:free-vars #:kvars-of #:expr-equal
   ;; printing
   #:expr->string #:sort->string #:print-fq
   ;; parsing
   #:parse-expr-string #:parse-sort-string #:parse-pred-string
   #:parse-error-condition #:liquid-parse-error
   #:read-fq-file #:read-fq-string
   #:extract-spec-comments #:parse-spec-string #:parse-spec-file
   ;; fq
   #:fq-info #:fq-info-binds #:fq-info-constraints #:fq-info-wfs
   #:fq-info-quals #:fq-info-consts #:fq-info-options #:fq-info-data
   ;; smt / z3
   #:*z3-path* #:z3-available-p #:with-z3 #:z3-start #:z3-stop
   #:z3-command #:z3-check-sat #:z3-push #:z3-pop #:smt-solver-missing
   #:formula->smt2 #:check-valid
   ;; solver
   #:solve-fq #:solve-fq-file #:fixpoint-result #:result-status
   #:result-unsafe-ids #:result-solution #:result-message
   ;; checking programs
   #:check-program #:failure-name #:failure-line #:failure-what
   #:failure-goal #:failure-message))

(in-package :yale-liquid)
