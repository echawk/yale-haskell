;;; base-runtime.lisp -- primitives for the Haskell 2010 / base library
;;; modules that are not the FFI's (lib/haskell98/BasePrims.hi):
;;; exceptions (Control.Exception), processes (System.Process), the
;;; platform (System.Info), the environment and directories.  Plain CL
;;; in the MUMBLE-USER package, loaded into the image by
;;; tools/build/image.lisp like src/ffi/ffi-runtime.lisp.

(cl:in-package "MUMBLE-USER")

;;; Exceptions.  An exception is a Lisp condition: haskell-io-error (an
;;; IOError, src/runtime/io-errors.mumble), haskell-error-call (error and
;;; pattern-match failure, src/compiler/top/errors.mumble) or an
;;; arithmetic-error from the host (division by zero).

(cl:defun prim.catch-any (action handler)
  (cl:let ((result
	    (cl:let ((mark *blackhole-trail*))
	      (cl:handler-case
		  (cl:let ((*track-blackholes* cl:t)
			   (*catch-runtime-errors* cl:t))
		    ;; the action is forced here: it may itself be an error
		    (cl:cons cl:t (force (apply-1 (force action) (box 'state)))))
		((cl:or haskell-io-error haskell-error-call cl:arithmetic-error) (c)
		  ;; thunks left blackholed by the abandoned evaluation
		  (restore-blackholes mark)
		  (cl:cons cl:nil c))))))
    (cl:if (cl:car result)
	   (cl:cdr result)
	   (force (apply-2 handler (box (cl:cdr result)) (box 'state))))))

(cl:defun prim.throw-exc (c) (cl:error c))

;;; 0 an IOError, 1 an ErrorCall, 2 an arithmetic error
(cl:defun prim.exc-kind (c)
  (cl:typecase c
    (haskell-io-error 0)
    (haskell-error-call 1)
    (cl:t 2)))

(cl:defun prim.exc-message (c)
  (cl:typecase c
    (haskell-error-call (haskell-error-call-message c))
    (cl:division-by-zero "divide by zero")
    (cl:t (cl:princ-to-string c))))

(cl:defun prim.make-error-call (msg)
  (cl:make-condition 'haskell-error-call :message msg))

(cl:defun prim.identity (x) x)

;;; Processes: the exit status of sh -c COMMAND, its output going to ours.

(cl:defun prim.system (command)
  (cl:finish-output cl:*standard-output*)
  (cl:nth-value 2 (uiop:run-program (cl:list "/bin/sh" "-c" command)
				    :input :interactive :output :interactive
				    :error-output :interactive
				    :ignore-error-status cl:t)))

;;; The output of sh -c COMMAND with INPUT on its stdin; its exit code
;;; is then prim.last-exit-code.
(cl:defvar *last-exit-code* 0)
(cl:defun prim.read-process-output (command input)
  (cl:finish-output cl:*standard-output*)
  (cl:multiple-value-bind (out err code)
      (cl:with-input-from-string (in input)
	(uiop:run-program (cl:list "/bin/sh" "-c" command)
			  :input in :output :string :error-output :interactive
			  :ignore-error-status cl:t))
    (cl:declare (cl:ignore err))
    (cl:setf *last-exit-code* code)
    out))
(cl:defun prim.last-exit-code () *last-exit-code*)

;;; The platform, in GHC's spelling (System.Info).

(cl:defparameter prim.os
  #+darwin "darwin" #+linux "linux" #+freebsd "freebsd" #+openbsd "openbsd"
  #+win32 "mingw32"
  #-(or darwin linux freebsd openbsd win32) (cl:string-downcase (cl:software-type)))

(cl:defparameter prim.arch
  #+x86-64 "x86_64" #+(or arm64 aarch64) "aarch64" #+x86 "i386"
  #-(or x86-64 arm64 aarch64 x86) (cl:string-downcase (cl:machine-type)))

;;; The environment: "" and a flag, since an empty variable is not unset.
;;; It is read and changed through libc, so that changes are seen by the
;;; host's own getenv (except on the JVM, which keeps a copy).

(cl:defun libc-getenv (name)
  #+yale-cffi (cffi:foreign-funcall "getenv" :string name :string)
  #-yale-cffi (uiop:getenv name))

(cl:defun prim.env-is-set (name) (cl:if (libc-getenv name) cl:t cl:nil))
(cl:defun prim.env-value (name) (cl:or (libc-getenv name) ""))
(cl:defun prim.set-env (name value)
  #+yale-cffi (cffi:foreign-funcall "setenv" :string name :string value :int 1 :int)
  #-yale-cffi (cl:setf (uiop:getenv name) value)
  0)
(cl:defun prim.unset-env (name)
  #+yale-cffi (cffi:foreign-funcall "unsetenv" :string name :int)
  #-yale-cffi (cl:setf (uiop:getenv name) "")
  0)

(cl:defun prim.home-directory ()
  (cl:or (libc-getenv "HOME") (cl:namestring (cl:user-homedir-pathname))))

(cl:defun prim.temporary-directory ()
  (cl:or (libc-getenv "TMPDIR") "/tmp"))

;;; Directories (System.Directory beyond the Haskell 98 module).

(cl:defun prim.create-directory-if-missing (parents? path)
  (cl:if parents?
	 (cl:ensure-directories-exist
	  (cl:concatenate 'cl:string (cl:string-right-trim "/" path) "/"))
	 ;; fails quietly when PATH exists
	 #+yale-cffi (cffi:foreign-funcall "mkdir" :string path :int #o777 :int)
	 #-yale-cffi (cl:ignore-errors
		      (cl:ensure-directories-exist (uiop:ensure-directory-pathname path))))
  0)

(cl:defun prim.remove-directory-recursive (path)
  (uiop:delete-directory-tree
   (uiop:ensure-directory-pathname (cl:string-right-trim "/" path)) :validate cl:t)
  0)

(cl:defun prim.copy-file (from to)
  (cl:with-open-file (in from :element-type '(cl:unsigned-byte 8))
    (cl:with-open-file (out to :element-type '(cl:unsigned-byte 8)
			       :direction :output :if-exists :supersede)
      (cl:let ((buf (cl:make-array 65536 :element-type '(cl:unsigned-byte 8))))
	(cl:loop for n = (cl:read-sequence buf in)
		 while (cl:plusp n) do (cl:write-sequence buf out :end n)))))
  0)

(cl:defun prim.find-executable (name)
  (cl:let ((path (libc-getenv "PATH")))
    (cl:or (cl:and path
		   (cl:loop for dir in (uiop:split-string path :separator ":")
			    for file = (cl:concatenate 'cl:string dir "/" name)
			    when (cl:and (cl:plusp (cl:length dir))
					 ;; access(file, X_OK)
					 #+yale-cffi
					 (cl:zerop (cffi:foreign-funcall "access" :string file
									 :int 1 :int))
					 #-yale-cffi (cl:probe-file file))
			      return file))
	   "")))
