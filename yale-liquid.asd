;;;; yale-liquid.asd -- LiquidHaskell-style refinement checking: the parts
;;;; that do not depend on Yale's typed core.
;;;;
;;;; A standalone system in plain Common Lisp (no mumble), not yet wired
;;;; into the compiler pipeline.  See doc/plans/LIQUID-HASKELL.md and
;;;; src/liquid/package.lisp for the layout.
;;;;
;;;;   (asdf:load-asd "yale-liquid.asd")
;;;;   (asdf:load-system :yale-liquid)
;;;;   (liquid:solve-fq-file "tests/liquid/fq/pos/test1.fq")
;;;;   (asdf:test-system :yale-liquid)          ; make liquid-test
;;;;
;;;; Its only dependency is UIOP (shipped with ASDF), used to run Z3.

(defsystem :yale-liquid
  :description "Refinement types for Yale Haskell: the specification language, the refinement logic, an SMT (Z3) backend and a liquid-fixpoint-compatible Horn solver."
  :author "Yale Haskell revival"
  :license "BSD-3-Clause (ports and data from LiquidHaskell and liquid-fixpoint, see tests/liquid/README.md)"
  :depends-on (:uiop)
  :pathname "src/liquid/"
  :serial t
  :components ((:file "package")
               (:file "logic")
               (:file "pretty")
               (:file "parse-base")
               (:file "expr-parser")
               (:file "fq")
               (:file "spec")
               (:file "sortcheck")
               (:file "smt")
               (:file "z3")
               (:file "fixpoint")
               (:file "prolog"))
  :in-order-to ((test-op (test-op :yale-liquid/test))))

(defsystem :yale-liquid/test
  :description "Tests for yale-liquid: parsing, round trips, SMT, and the vendored liquid-fixpoint and LiquidHaskell test data."
  :depends-on (:yale-liquid)
  :pathname "tests/liquid/"
  :components ((:file "tests"))
  :perform (test-op (o c)
             (declare (ignore o c))
             (unless (uiop:symbol-call :yale-liquid-tests :run-all)
               (error "yale-liquid tests failed"))))
