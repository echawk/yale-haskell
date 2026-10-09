;;; ffi-runtime.lisp -- the runtime of the foreign function interface
;;; (Haskell 2010 chapter 8): the primitives of lib/haskell98/Foreign/
;;; ForeignPrims.hi, over CFFI.  Plain CL (not mumble), loaded into the
;;; image after CFFI by tools/build/image.lisp; the names are mumble's
;;; prim.xxx symbols.  Code generated for `foreign import' declarations
;;; (backend/interface-codegen.mumble) calls cffi:foreign-funcall itself.
;;;
;;; Representations: Ptr a and FunPtr a are CFFI foreign pointers; Int is
;;; a fixnum, Char a fixnum code, Bool a Lisp boolean, and the Data.Int /
;;; Data.Word newtypes are their (erased) Int or Integer.

(cl:in-package "MUMBLE-USER")

(cl:defparameter prim.null-ptr (cffi:null-pointer))

(cl:defun prim.plus-ptr (p n) (cffi:inc-pointer p n))
(cl:defun prim.minus-ptr (p q)
  (cl:- (cffi:pointer-address p) (cffi:pointer-address q)))
(cl:defun prim.ptr-eq (p q) (cffi:pointer-eq p q))
(cl:defun prim.ptr-le (p q)
  (cl:<= (cffi:pointer-address p) (cffi:pointer-address q)))
(cl:defun prim.ptr-to-integer (p) (cffi:pointer-address p))
(cl:defun prim.integer-to-ptr (n) (cffi:make-pointer n))
(cl:defun prim.cast-ptr (p) p)

;;; peek/poke: (prim.peek-int32 ptr byte-offset), (prim.poke-int32 ptr off v)

(cl:defmacro define-peek-poke (name type)
  (cl:let ((peek (cl:intern (cl:format cl:nil "PRIM.PEEK-~A" name)))
	   (poke (cl:intern (cl:format cl:nil "PRIM.POKE-~A" name))))
    `(cl:progn
       (cl:defun ,peek (p off) (cffi:mem-ref p ,type off))
       (cl:defun ,poke (p off v) (cl:setf (cffi:mem-ref p ,type off) v) 0))))

(define-peek-poke "INT8" :int8)
(define-peek-poke "INT16" :int16)
(define-peek-poke "INT32" :int32)
(define-peek-poke "INT64" :int64)
(define-peek-poke "WORD8" :uint8)
(define-peek-poke "WORD16" :uint16)
(define-peek-poke "WORD32" :uint32)
(define-peek-poke "WORD64" :uint64)
(define-peek-poke "INT" :long)
(define-peek-poke "DOUBLE" :double)
(define-peek-poke "FLOAT" :float)
(define-peek-poke "PTR" :pointer)

;;; Memory

(cl:defun prim.malloc (n)
  (cl:let ((p (cffi:foreign-funcall "malloc" :size (cl:max n 1) :pointer)))
    (cl:when (cffi:null-pointer-p p)
      (haskell-runtime-error "malloc: out of memory"))
    p))
(cl:defun prim.calloc (n)
  (cffi:foreign-funcall "calloc" :size (cl:max n 1) :size 1 :pointer))
(cl:defun prim.realloc (p n)
  (cffi:foreign-funcall "realloc" :pointer p :size (cl:max n 1) :pointer))
(cl:defun prim.free (p) (cffi:foreign-free p) 0)
(cl:defun prim.copy-bytes (dst src n)
  (cffi:foreign-funcall "memcpy" :pointer dst :pointer src :size n :pointer) 0)
(cl:defun prim.move-bytes (dst src n)
  (cffi:foreign-funcall "memmove" :pointer dst :pointer src :size n :pointer) 0)
(cl:defun prim.fill-bytes (dst byte n)
  (cffi:foreign-funcall "memset" :pointer dst :int byte :size n :pointer) 0)

;;; C strings, UTF-8.  The Haskell side's String conversions are done by
;;; the primitive wrappers (a String argument arrives as a Lisp string).

(cl:defun prim.new-cstring (s) (cffi:foreign-string-alloc s :encoding :utf-8))
(cl:defun prim.peek-cstring (p)
  (cl:let ((babel-encodings:*suppress-character-coding-errors* cl:t))  ; bad bytes as U+FFFD
    (cffi:foreign-string-to-lisp p :encoding :utf-8)))
(cl:defun prim.peek-cstring-len (p n)
  (cl:let ((babel-encodings:*suppress-character-coding-errors* cl:t))
    (cffi:foreign-string-to-lisp p :count n :encoding :utf-8)))
(cl:defun prim.cstring-length (s)        ; bytes of s in UTF-8, without the NUL
  (babel:string-size-in-octets s :encoding :utf-8))

;;; Foreign libraries: Foreign.loadLibrary, yale-haskell -l, :set lib.

(cl:defun prim.load-library (name)
  (cl:handler-case (cffi:load-foreign-library name)
    (cl:error (c)
      (haskell-runtime-error
       (cl:format cl:nil "Cannot load foreign library ~A: ~A" name c))))
  0)

;;; For the generated code: the address of a foreign symbol (&sym imports).
(cl:defun ffi-symbol-pointer (name)
  (cl:or (cffi:foreign-symbol-pointer name)
	 (haskell-runtime-error
	  (cl:format cl:nil "Foreign symbol ~A is not defined" name))))

;;; unsafePerformIO (Foreign.Marshal.Unsafe.unsafeLocalState): an IO
;;; action is a function of the state (prim.returnio, io-primitives.mumble).
(cl:defun prim.unsafe-perform-io (io)
  (force (apply-1 (force io) 'state)))

;;; Storable Char: the primitive wrapper passes a Char as a Lisp character
;;; and returns the code of the one peeked (a Haskell Char is its code).
(cl:defun prim.peek-char (p off) (cffi:mem-ref p :int32 off))
(cl:defun prim.poke-char (p off c)
  (cl:setf (cffi:mem-ref p :int32 off) (cl:char-code c)) 0)

;;; Foreign.C.Error.  errno is read and set through libc; *errno-values*
;;; (src/ffi/errno-<os>.lisp, from tools/gen/gen-errno.sh) gives the
;;; values of the E* constants, -1 for those the system lacks.

(cl:defvar *errno-values* '())

(cl:defun prim.errno-value (name)
  (cl:let ((entry (cl:assoc name *errno-values* :test #'cl:string=)))
    (cl:if entry (cl:cdr entry) -1)))

(cl:defun errno-location ()
  #+(or darwin freebsd openbsd) (cffi:foreign-funcall "__error" :pointer)
  #-(or darwin freebsd openbsd) (cffi:foreign-funcall "__errno_location" :pointer))

(cl:defun prim.get-errno () (cffi:mem-ref (errno-location) :int))
(cl:defun prim.set-errno (n) (cl:setf (cffi:mem-ref (errno-location) :int) n) 0)

;;; errnoToIOError: the IOError kind for an errno, as GHC classifies it,
;;; and strerror's text.
(cl:defparameter *errno-io-error-kinds*
  '(("ENOENT" . does-not-exist) ("ENOTDIR" . does-not-exist)
    ("ENXIO" . does-not-exist) ("ESRCH" . does-not-exist)
    ("EEXIST" . already-exists)
    ("EBUSY" . already-in-use) ("ETXTBSY" . already-in-use)
    ("EACCES" . permission) ("EPERM" . permission) ("EROFS" . permission)
    ("ENOSPC" . full) ("EDQUOT" . full) ("EMFILE" . full) ("ENFILE" . full)
    ("ENOMEM" . full)
    ("EISDIR" . illegal-operation) ("EINVAL" . illegal-operation)
    ("EXDEV" . illegal-operation) ("EBADF" . illegal-operation)))

(cl:defun prim.errno-io-error (location errno has-handle? handle has-file? file)
  (cl:let ((kind (cl:or (cl:loop for (name . kind) in *errno-io-error-kinds*
				 when (cl:eql errno (prim.errno-value name))
				   return kind)
			'other)))
    (make-io-error kind location
		   (cffi:foreign-funcall "strerror" :int errno :string)
		   (cl:if has-file? file cl:nil)
		   (cl:if has-handle? handle cl:nil))))

;;; A function pointer to a C function by name (finalizerFree is free).
(cl:defun prim.foreign-symbol-ptr (name)
  (cl:or (cffi:foreign-symbol-pointer name) (cffi:null-pointer)))

;;; Foreign.ForeignPtr.  A ForeignPtr is the pointer and an FPState: a
;;; cell #(finalizers finalized? pointer), registered with the host's GC
;;; so that the finalizers (FunPtrs, or (FunPtr . env) pairs, newest
;;; first) run once the ForeignPtr is unreachable, or when
;;; finalizeForeignPtr runs them.  The GC finalizer closes over the cell,
;;; not the state it watches.

(cl:defstruct (fp-state (:constructor make-fp-state (cell))) cell)

(cl:defun run-fp-finalizers (cell)
  (cl:unless (cl:svref cell 1)
    (cl:setf (cl:svref cell 1) cl:t)
    (cl:let ((p (cl:svref cell 2)))
      (cl:dolist (f (cl:svref cell 0))
	(cl:if (cl:consp f)
	       (cffi:foreign-funcall-pointer (cl:car f) () :pointer (cl:cdr f)
					     :pointer p :void)
	       (cffi:foreign-funcall-pointer f () :pointer p :void))))))

(cl:defun prim.new-fp-state (p)
  (cl:let* ((cell (cl:vector '() cl:nil p))
	    (state (make-fp-state cell)))
    #+sbcl (sb-ext:finalize state (cl:lambda () (run-fp-finalizers cell))
			    :dont-save cl:t)
    #+ecl (ext:set-finalizer state (cl:lambda (o) (cl:declare (cl:ignore o))
				     (run-fp-finalizers cell)))
    state))

(cl:defun prim.add-fp-finalizer (state fn)
  (cl:push fn (cl:svref (fp-state-cell state) 0)) 0)
(cl:defun prim.add-fp-finalizer-env (state fn env)
  (cl:push (cl:cons fn env) (cl:svref (fp-state-cell state) 0)) 0)
(cl:defun prim.finalize-fp (state)
  (run-fp-finalizers (fp-state-cell state)) 0)
;;; touchForeignPtr: keeps STATE reachable until here
(cl:defun prim.touch-fp (state)
  (cl:if (fp-state-p state) 0 1))

;;; Foreign.StablePtr: values kept in a table, known by their number
;;; (never 0, which would be the null pointer).

(cl:defvar *stable-ptrs* (cl:make-hash-table))
(cl:defvar *stable-ptr-counter* 0)

(cl:defun prim.new-stable-ptr (x)
  (cl:let ((n (cl:incf *stable-ptr-counter*)))
    (cl:setf (cl:gethash n *stable-ptrs*) x)
    (cffi:make-pointer n)))

(cl:defun prim.deref-stable-ptr (p)
  (cl:multiple-value-bind (x found?)
      (cl:gethash (cffi:pointer-address p) *stable-ptrs*)
    (cl:if found? x (haskell-runtime-error "deRefStablePtr: not a live StablePtr"))))

(cl:defun prim.free-stable-ptr (p)
  (cl:remhash (cffi:pointer-address p) *stable-ptrs*) 0)
