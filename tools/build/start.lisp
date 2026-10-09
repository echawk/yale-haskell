;;; start.lisp -- the yale-haskell executable on Lisps that cannot save
;;; an image (see image.lisp): load the system built by image.lisp from
;;; $Y2, quietly, then run the command line with this process's
;;; arguments.

(let ((cwd *default-pathname-defaults*)
      (y2 (let ((dir (or (ext:getenv "Y2") (error "Y2 is not set"))))
            (pathname (if (char= (char dir (1- (length dir))) #\/)
                          dir
                          (concatenate 'string dir "/"))))))
  ;; The build files use paths relative to $Y2.
  (setf *default-pathname-defaults* y2)
  #+ecl (ext:chdir y2)
  (let ((*standard-output* (make-broadcast-stream))
        (*error-output* (make-broadcast-stream))
        (*load-verbose* nil)
        (*compile-verbose* nil))
    (load (merge-pathnames "tools/build/runtime.lisp" y2)))
  (setf *default-pathname-defaults* cwd)
  #+ecl (ext:chdir cwd))

(funcall (find-symbol "MAIN" "YALE-HASKELL-CLI")
         ;; the arguments after --, which the launcher passes
         (rest (member "--" #+ecl ext:*command-args*
                       #+abcl (cons "--" ext:*command-line-argument-list*)
                       :test #'string=)))
(uiop:quit 0)
