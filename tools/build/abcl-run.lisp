;;; abcl-run.lisp -- load the file named by the first argument after
;;; "--" (the Makefile's RUN_LISP on ABCL), exiting with status 1 on an
;;; error: ABCL's --batch would otherwise enter the debugger.

(handler-bind ((serious-condition
                 (lambda (c)
                   (format *error-output* "~&~a~%" c)
                   (finish-output *error-output*)
                   (ext:exit :status 1))))
  (load (first ext:*command-line-argument-list*)))
(ext:exit :status 0)
