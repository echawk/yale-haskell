;;;; extract-annotations.lisp -- regenerate tests/liquid/lh/ from an
;;;; upstream LiquidHaskell checkout.
;;;;
;;;;   sbcl --script tests/liquid/extract-annotations.lisp /path/to/liquidhaskell
;;;;
;;;; (run from the top of the Yale Haskell tree, after loading nothing: the
;;;; script loads yale-liquid itself).  It copies the library specification
;;;; modules into tests/liquid/lh/assumptions/ and writes, for each
;;;; directory under the checkout's tests/, a file
;;;; tests/liquid/lh/annotations/<dir>.txt with every {-@ ... @-} comment
;;;; of its .hs files, each preceded by "-- FILE path:line:column" and
;;;; indented as in the original so that layout is preserved.  The pinned
;;;; upstream commit is recorded in tests/liquid/README.md.

(require :asdf)
(asdf:load-asd (merge-pathnames "yale-liquid.asd" (uiop:getcwd)))
(asdf:load-system :yale-liquid)

(defpackage :extract-annotations (:use :cl))
(in-package :extract-annotations)

(defvar *upstream* (uiop:ensure-directory-pathname (second sb-ext:*posix-argv*)))
(defvar *out* (merge-pathnames "tests/liquid/lh/" (uiop:getcwd)))

(defun hs-files (dir)
  (sort (remove-if-not (lambda (f) (equal (pathname-type f) "hs"))
                       (directory (merge-pathnames "**/*.hs" dir)))
        #'string< :key #'namestring))

(defun relative (f)
  (enough-namestring f *upstream*))

(defun line-col (text pos)
  (let ((line 1) (start 0))
    (loop for i below pos
          when (char= (char text i) #\Newline) do (incf line) (setf start (1+ i)))
    (values line start)))

(defun copy-assumptions ()
  (dolist (root '("src/" "liquid-prelude/src/" "liquid-vector/src/" "liquid-parallel/src/"))
    (dolist (f (hs-files (merge-pathnames root *upstream*)))
      (let ((text (liquid::read-file-string f)))
        (when (liquid:extract-spec-comments text)
          (let ((dest (merge-pathnames (relative f) (merge-pathnames "assumptions/" *out*))))
            (ensure-directories-exist dest)
            (with-open-file (o dest :direction :output :if-exists :supersede :external-format :utf-8)
              (write-string text o))))))))

(defun extract-annotations ()
  (let ((tests (merge-pathnames "tests/" *upstream*)))
    (dolist (dir (directory (merge-pathnames "*/" tests)))
      (let ((name (car (last (pathname-directory dir))))
            (chunks '()))
        (dolist (f (hs-files dir))
          (let ((text (liquid::read-file-string f)))
            (dolist (r (liquid:extract-spec-comments text))
              (let ((open (- (car r) 3)))
                (multiple-value-bind (line start) (line-col text open)
                  (let* ((close (search "-}" text :start2 (cdr r)))
                         (prefix (map 'string (lambda (c) (if (char= c #\Tab) #\Tab #\Space))
                                      (subseq text start open))))
                    (push (format nil "-- FILE ~a:~d:~d~%~a~a~%"
                                  (relative f) line (1+ (- open start))
                                  prefix (subseq text open (+ close 2)))
                          chunks)))))))
        (when chunks
          (let ((dest (merge-pathnames (format nil "annotations/~a.txt" name) *out*)))
            (ensure-directories-exist dest)
            (with-open-file (o dest :direction :output :if-exists :supersede :external-format :utf-8)
              (format o "-- {-@ @-} comments extracted verbatim from LiquidHaskell's tests/~a/~%-- (see tests/liquid/README.md for the upstream commit and licence)~%~%" name)
              (dolist (c (reverse chunks)) (write-string c o) (terpri o)))))))))

(copy-assumptions)
(extract-annotations)
