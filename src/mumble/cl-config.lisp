;;; cl-config.lisp -- the host Lisp's file types and name, which the
;;; mumble support layer needs before cl-support and cl-definitions load.
;;; Loaded by cl-init.lisp (the Makefile build) and by mumble.asd.

(in-package "MUMBLE-IMPLEMENTATION")

(defvar *lisp-source-file-type* ".lisp")
(defvar *lisp-binary-file-type*
  #+lucid
  (namestring (make-pathname :type (car lcl:*load-binary-pathname-types*)))
  #+allegro
  (concatenate 'string "." excl:*fasl-default-type*)
  #+cmu
  (concatenate 'string "." (c:backend-fasl-file-type c:*backend*))
  #+sbcl
  (concatenate 'string "." sb-fasl:*fasl-file-type*)
  #+akcl
  ".o"
  #+mcl
  ".fasl"
  #+lispworks
  ".wfasl"
  #+wcl
  ".o"
  #-(or sbcl lucid allegro cmu akcl mcl lispworks wcl)
  (error "Don't know how to initialize *LISP-BINARY-FILE-TYPE*.")
  )

(defvar *lisp-implementation-name*
  #+lucid "lucid"
  #+(and allegro next) "allegro-next"
  #+(and allegro (not next)) "allegro"
  #+cmu "cmu"
  #+sbcl "sbcl"
  #+akcl "akcl"
  #+mcl "mcl"
  #+lispworks "lispworks"
  #+wcl "wcl"
  #-(or sbcl lucid allegro cmu akcl mcl lispworks wcl)
  (error "Don't know how to initialize *LISP-IMPLEMENTATION-NAME*.")
  )
