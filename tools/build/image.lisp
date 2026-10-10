;;; image.lisp -- build the yale-haskell executable on SBCL with ASDF:
;;; program-op on yale-haskell/executable (yale-haskell.asd).  Run from
;;; the top of the source tree, with $YALE_HASKELL_DIALECT naming the
;;; dialect and $YALE_HASKELL_EXECUTABLE the output (see the Makefile).
;;; Other Lisps use launcher.lisp.

(require :asdf)

;;; This tree's systems, and the libraries ocicl installed into ocicl/.
(asdf:initialize-source-registry
 `(:source-registry (:directory ,(uiop:getcwd))
                    (:tree ,(merge-pathnames "ocicl/" (uiop:getcwd)))
                    :inherit-configuration))

;;; program-op loads the system, then saves the image and exits.
(asdf:make :yale-haskell/executable)
