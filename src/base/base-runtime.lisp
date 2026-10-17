;;; base-runtime.lisp -- primitives for the Haskell 2010 / base library
;;; modules that are not the FFI's (lib/haskell98/BasePrims.hi):
;;; exceptions (Control.Exception), processes (System.Process), the
;;; platform (System.Info), the environment and directories.  Plain CL
;;; in the MUMBLE-USER package, loaded into the image by
;;; tools/build/image.lisp like src/ffi/ffi-runtime.lisp.

(cl:in-package "MUMBLE-USER")

;;; Mutable references (Data.IORef, Data.STRef) are the runtime's cells
;;; (prim.new-ref etc., src/runtime/handle-prims.mumble).

(cl:defun prim.ref-eq (a b) (cl:eq a b))

;;; Mutable arrays (Data.Array.Base): simple vectors of unevaluated values,
;;; or, for an unboxed (element-strict) array whose newArray value is a
;;; Bool, a bit vector (see prim.vector-sel in array-prims.mumble).  Of
;;; the element types GHC's unboxed arrays allow, only Bool is a Lisp
;;; boolean; a value of another type written into a bit vector is an error.

(cl:defun prim.new-mut-arr (n x) (cl:make-array n :initial-element x))
(cl:defun prim.new-unboxed-mut-arr (n x)
  (cl:if (cl:or (cl:eq x cl:t) (cl:null x))
	 (cl:make-array n :element-type 'cl:bit :initial-element (cl:if x 1 0))
	 (cl:make-array n :initial-element x)))
(cl:defun prim.read-mut-arr (a i)
  (cl:if (cl:simple-bit-vector-p a)
	 (cl:eql (cl:sbit a i) 1)
	 (cl:svref a i)))
(cl:defun prim.write-mut-arr (a i x)
  (cl:if (cl:simple-bit-vector-p a)
	 (cl:setf (cl:sbit a i) (bool-bit x))
	 (cl:setf (cl:svref a i) x))
  0)

;;; Between mutable arrays and the Prelude's Array, MkArray bounds vector
;;; (a cons: a two-field constructor; src/runtime/runtime-utils.mumble's
;;; make-tuple), whose vector holds the same values: a Box is its field.

(cl:defun prim.mut-arr-to-array (b a) (cl:cons b a))
(cl:defun prim.copy-mut-arr-to-array (b a) (cl:cons b (cl:copy-seq a)))
(cl:defun prim.array-to-mut-arr (arr) (cl:cdr arr))
(cl:defun prim.copy-array-to-mut-arr (arr) (cl:copy-seq (cl:cdr arr)))

;;; Running an IO action outside IO (System.IO.Unsafe, runST): it is
;;; applied to the state token as the IO monad's bind does.

(cl:defun run-io-action (action)
  (force (apply-1 (force action) (box 'state))))

(cl:defun prim.unsafe-perform-io (action)
  (force (run-io-action action)))

;;; The action runs when its result is first demanded.
(cl:defun prim.unsafe-interleave-io (action)
  (delay (force (run-io-action action))))

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
		    ;; the action is forced here: it may itself be an error;
		    ;; its result value stays lazy (try (return undefined)
		    ;; is Right undefined, as in GHC)
		    (cl:cons cl:t (apply-1 (force action) (box 'state))))
		((cl:or haskell-io-error haskell-error-call cl:arithmetic-error) (c)
		  ;; thunks left blackholed by the abandoned evaluation
		  (restore-blackholes mark)
		  (cl:cons cl:nil c))))))
    (cl:if (cl:car result)
	   (cl:cdr result)
	   (apply-2 handler (box (cl:cdr result)) (box 'state)))))

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
    (haskell-arith-error (cl:svref *arith-messages* (haskell-arith-error-code c)))
    (cl:division-by-zero "divide by zero")
    (cl:t (cl:princ-to-string c))))

(cl:defun prim.make-error-call (msg)
  (cl:make-condition 'haskell-error-call :message msg))

;;; An ArithException thrown by a program (throw Underflow): an
;;; arithmetic-error, as the host's own (division by zero) are, with
;;; Control.Exception's constructor number: 0 Overflow, 1 Underflow,
;;; 2 LossOfPrecision, 3 DivideByZero, 4 Denormal, 5 RatioZeroDenominator.
(cl:define-condition haskell-arith-error (cl:arithmetic-error)
  ((code :initarg :code :reader haskell-arith-error-code))
  (:report (cl:lambda (c s)
	     (cl:write-string (cl:svref *arith-messages* (haskell-arith-error-code c)) s))))

(cl:defparameter *arith-messages*
  #("arithmetic overflow" "arithmetic underflow" "loss of precision"
    "divide by zero" "denormal" "Ratio has zero denominator"))

(cl:defun prim.make-arith-error (code)
  (cl:make-condition 'haskell-arith-error :code code))

;;; The constructor number of an arithmetic error: the host's division by
;;; zero is DivideByZero, its overflows Overflow.
(cl:defun prim.arith-code (c)
  (cl:typecase c
    (haskell-arith-error (haskell-arith-error-code c))
    (cl:division-by-zero 3)
    (cl:floating-point-overflow 0)
    (cl:floating-point-underflow 1)
    (cl:t 3)))

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

;;; System.Process's createProcess and readProcessWithExitCode, over
;;; uiop:launch-program / run-program.  A command is its argument words
;;; joined by NUL characters (the Haskell side's [String]); ENV, when
;;; HAS-ENV? is true, is NAME=VALUE words likewise, and replaces the
;;; environment (through env -i).  A stream mode is 0 inherit, 1 a new
;;; pipe, 2 no stream (/dev/null), 3 the handle given.

(cl:defun split-nul (s)
  (cl:if (cl:string= s "")
	 '()
	 (cl:loop for start = 0 then (cl:1+ end)
		  for end = (cl:position (cl:code-char 0) s :start start)
		  collect (cl:subseq s start end)
		  while end)))

(cl:defun process-command (argv has-env? env)
  (cl:let ((words (split-nul argv)))
    (cl:if has-env?
	   (cl:append (cl:list "/usr/bin/env" "-i") (split-nul env) words)
	   words)))

(cl:defun process-stream-arg (mode h)
  (cl:case mode
    (0 :interactive)
    (1 :stream)
    (2 cl:nil)
    (cl:t (cl:if (standard-handle? h)
		 :interactive
		 (handle-stream h)))))

(cl:defun prim.launch-process (argv cwd has-env? env in-mode in-h out-mode out-h
				    err-mode err-h)
  ;; our buffered output is not flushed first, as GHC's is not
  (cl:let ((command (process-command argv has-env? env)))
    (cl:handler-case
	(uiop:launch-program command
			     :input (process-stream-arg in-mode in-h)
			     :output (process-stream-arg out-mode out-h)
			     :error-output (process-stream-arg err-mode err-h)
			     :directory (cl:if (cl:string= cwd "") cl:nil
					       (uiop:ensure-directory-pathname cwd)))
      (cl:error (c)
	(cl:error (make-io-error 'does-not-exist "createProcess"
				 (cl:princ-to-string c)
				 (cl:first command) cl:nil))))))

;;; The process's end of a pipe as a handle: 0 its stdin (we write), 1
;;; its stdout, 2 its stderr (we read).
(cl:defun prim.process-handle (p which)
  (cl:let ((name (cl:format cl:nil "<process ~A>"
			    (cl:case which (0 "stdin") (1 "stdout") (cl:t "stderr")))))
    (cl:case which
      (0 (make-haskell-handle (uiop:process-info-input p) name cl:nil cl:t cl:nil))
      (1 (make-haskell-handle (uiop:process-info-output p) name cl:t cl:nil cl:nil))
      (cl:t (make-haskell-handle (uiop:process-info-error-output p) name
				 cl:t cl:nil cl:nil)))))

;;; The exit code; a process killed by signal N is -N, as in the process
;;; package (uiop gives 128+N and N).
(cl:defun prim.wait-process (p)
  (cl:let ((in (uiop:process-info-input p)))
    (cl:when (cl:and in (cl:open-stream-p in))
      (cl:finish-output in)))
  (cl:multiple-value-bind (code signal) (uiop:wait-process p)
    (cl:cond (signal (cl:- signal))
	     ((cl:integerp code) code)
	     (cl:t -1))))

(cl:defun prim.process-running (p) (cl:if (uiop:process-alive-p p) cl:t cl:nil))

(cl:defun prim.terminate-process (p)
  (cl:when (uiop:process-alive-p p) (uiop:terminate-process p))
  0)

;;; readCreateProcess(WithExitCode): the output of the command ARGV
;;; with INPUT on its stdin; its exit code is then prim.last-exit-code,
;;; and its standard error, when CAPTURE-ERR?, prim.last-stderr (else it
;;; goes to ours).
(cl:defvar *last-stderr* "")
(cl:defun prim.read-process-full (argv cwd has-env? env input capture-err?)
  (cl:let ((command (process-command argv has-env? env)))
    (cl:multiple-value-bind (out err code)
	(cl:handler-case
	    (cl:with-input-from-string (in input)
	      (uiop:run-program command :input in :output :string
				:error-output (cl:if capture-err? :string :interactive)
				:directory (cl:if (cl:string= cwd "") cl:nil
						  (uiop:ensure-directory-pathname cwd))
				:ignore-error-status cl:t))
	  (cl:error (c)
	    (cl:error (make-io-error 'does-not-exist "readCreateProcessWithExitCode"
				     (cl:princ-to-string c) (cl:first command) cl:nil))))
      (cl:setf *last-exit-code* code *last-stderr* (cl:or err ""))
      out)))
(cl:defun prim.last-stderr () *last-stderr*)

;;; A failed command: an IOError of no particular kind ("LOC: failed").
(cl:defun prim.process-failed (location)
  (cl:error (make-io-error 'other location "" cl:nil cl:nil)))

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

;;; getEnvironment: the NAME=VALUE strings, each followed by a NUL.  From
;;; libc's environ, so setEnv's changes are seen.
(cl:defun prim.environment ()
  (cl:let ((entries
	     (cl:or
	      #+yale-cffi
	      (cl:let ((p (cffi:foreign-symbol-pointer "environ")))
		(cl:when p
		  (cl:loop with env = (cffi:mem-ref p :pointer)
			   for i from 0
			   for e = (cffi:mem-aref env :pointer i)
			   until (cffi:null-pointer-p e)
			   collect (cffi:foreign-string-to-lisp e))))
	      #+sbcl (sb-ext:posix-environ)
	      #-sbcl cl:nil)))
    (cl:format cl:nil "~{~a~a~}"
	       (cl:loop for e in entries append (cl:list e (cl:code-char 0))))))

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

;;; Terminals (System.IO hIsTerminalDevice, hGetEcho, hSetEcho).  Only
;;; the standard handles (file descriptors 0, 1, 2) can be terminals;
;;; System.IO passes -1 for the others.

(cl:defun prim.is-terminal (fd)
  (cl:and (cl:<= 0 fd 2)
	  #+yale-cffi (cl:= 1 (cffi:foreign-funcall "isatty" :int fd :int))
	  #-yale-cffi (cl:interactive-stream-p
		       (cl:if (cl:= fd 0) cl:*standard-input* cl:*standard-output*))))

;;; Echo is the terminal's (stty), changed on /dev/tty.
(cl:defun prim.get-echo ()
  (cl:let ((settings (cl:ignore-errors
		      (uiop:run-program (cl:list "/bin/sh" "-c" "stty -a </dev/tty")
					:output :string :ignore-error-status cl:t))))
    (cl:and settings
	    (cl:not (cl:search " -echo " (cl:substitute #\Space #\Newline
						     (cl:concatenate 'cl:string " " settings " "))))
	    cl:t)))

(cl:defun prim.set-echo (on?)
  (uiop:run-program (cl:list "/bin/sh" "-c"
			     (cl:if on? "stty echo </dev/tty" "stty -echo </dev/tty"))
		    :ignore-error-status cl:t)
  0)

;;; hSetFileSize: the file named PATH (the handle's, flushed first by
;;; System.IO) truncated or extended to SIZE bytes.
(cl:defun prim.truncate-file (path size)
  #+yale-cffi
  (cl:unless (cl:zerop (cffi:foreign-funcall "truncate" :string path :int64 size :int))
    (raise-io-error 'illegal-operation "hSetFileSize" "cannot set the size" path))
  #-yale-cffi
  (raise-io-error 'illegal-operation "hSetFileSize" "not supported on this Lisp" path)
  0)

;;; openTempFile (base): a new file DIR/PREFIX<n>SUFFIX, created empty;
;;; its name is returned for System.IO to open.
(cl:defvar *temp-random-state* (cl:make-random-state cl:t))
(cl:defun prim.create-temp-file (dir prefix suffix)
  (cl:loop
    (cl:let ((path (cl:format cl:nil "~a/~a~d~a" (cl:string-right-trim "/" dir)
			      prefix (cl:random 1000000000 *temp-random-state*) suffix)))
      (cl:with-open-file (s path :direction :output :if-exists cl:nil
				 :if-does-not-exist :create)
	(cl:when s (cl:return path))))))

;;; Text.Regex (regex-compat): a POSIX extended regular expression as a
;;; cl-ppcre scanner, whose syntax (Perl's) agrees with ERE for the
;;; patterns programs write, [[:class:]] included.  A match is returned as
;;; one string, "M" and each group's text after a NUL (an unmatched group
;;; is empty), or "" for no match; Text.Regex splits it.
(cl:defun prim.regex-compile (pattern case-sensitive? multiline?)
  (cl:handler-case
      (cl-ppcre:create-scanner pattern
			       :case-insensitive-mode (cl:not case-sensitive?)
			       :multi-line-mode multiline?)
    (cl-ppcre:ppcre-syntax-error (c)
      (cl:error 'haskell-error-call
		:message (cl:format cl:nil "Text.Regex.mkRegex: ~a" c)))))

(cl:defun prim.regex-match (scanner string)
  (cl:multiple-value-bind (start end gstarts gends)
      (cl-ppcre:scan scanner string)
    (cl:if (cl:null start)
	   ""
	   (cl:with-output-to-string (out)
	     (cl:write-string "M" out)
	     (cl:write-char (cl:code-char 0) out)
	     (cl:write-string (cl:subseq string start end) out)
	     (cl:loop for s across gstarts
		      for e across gends
		      do (cl:write-char (cl:code-char 0) out)
			 (cl:when s (cl:write-string (cl:subseq string s e) out)))))))

;;; Data.Typeable.  A type's representation is (name . argument reps),
;;; NAME a Lisp string ("Maybe", "[]", "->", "(,)").  The type checker
;;; makes Typeable T's dictionary as primTypeableDict "T" d1 .. dn, the di
;;; the arguments' dictionaries (util/instance-manager.mumble); Typeable
;;; has one method, so the dictionary is that method, a function from a
;;; Proxy to the representation.
(cl:defparameter prim.typeable-dict
  (make-vfun (cl:lambda (name cl:&rest dicts)
	       (cl:let ((rep (cl:cons (haskell-string->string (force name))
				      (cl:mapcar (cl:lambda (d)
						   (force (apply-1 (force d) (box 0))))
						 dicts))))
		 (cl:lambda (proxy)
		   (cl:declare (cl:ignore proxy))
		   rep)))))

(cl:defun prim.typerep-name (rep) (cl:car rep))
(cl:defun prim.typerep-arity (rep) (cl:length (cl:cdr rep)))
(cl:defun prim.typerep-arg (rep i) (cl:nth i (cl:cdr rep)))

;;; Data.Knob (knob): an in-memory file.  A knob is its contents (a string
;;; of bytes as characters, as ByteString's) and the string output streams
;;; of the handles writing it, drained into the contents when they are
;;; read.  Its handles are text handles in UTF-8, as the real ones are in
;;; the locale's encoding.  Mode: 0 read, 1 write (truncating), 2 append,
;;; 3 read-write (as write).
(cl:defstruct knob (data "") (outs cl:nil))

(cl:defun knob-utf8-encode (s)
  #+sbcl (cl:map 'cl:string (cl:function cl:code-char)
		 (sb-ext:string-to-octets s :external-format :utf-8))
  #-sbcl s)

(cl:defun knob-utf8-decode (s)
  #+sbcl (sb-ext:octets-to-string
	  (cl:map '(cl:vector (cl:unsigned-byte 8))
		  (cl:lambda (c) (cl:logand (cl:char-code c) 255)) s)
	  :external-format '(:utf-8 :replacement #\?))
  #-sbcl s)

(cl:defun prim.knob-new (s) (make-knob :data s))

(cl:defun prim.knob-contents (k)
  (cl:dolist (o (cl:reverse (knob-outs k)))
    (cl:setf (knob-data k)
	     (cl:concatenate 'cl:string (knob-data k)
			     (knob-utf8-encode (cl:get-output-stream-string o)))))
  (knob-data k))

(cl:defun prim.knob-set (k s)
  (prim.knob-contents k)
  (cl:setf (knob-data k) s)
  0)

(cl:defun prim.knob-handle (k name mode)
  (cl:if (cl:eql mode 0)
	 (make-haskell-handle (cl:make-string-input-stream
			       (knob-utf8-decode (prim.knob-contents k)))
			      name cl:t cl:nil cl:nil)
	 (cl:let ((o (cl:make-string-output-stream)))
	   (prim.knob-contents k)
	   (cl:unless (cl:eql mode 2) (cl:setf (knob-data k) ""))
	   (cl:push o (knob-outs k))
	   (make-haskell-handle o name cl:nil cl:t cl:nil))))
