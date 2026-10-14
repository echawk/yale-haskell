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
  (cl:or (cl:gethash name *foreign-exports*)
	 (cffi:foreign-symbol-pointer name)
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
;;; so that the finalizers (FunPtrs, (FunPtr . env) pairs, or #(action)
;;; for a Haskell IO action, newest
;;; first) run once the ForeignPtr is unreachable, or when
;;; finalizeForeignPtr runs them.  The GC finalizer closes over the cell,
;;; not the state it watches.

(cl:defstruct (fp-state (:constructor make-fp-state (cell))) cell)

(cl:defun run-fp-finalizers (cell)
  (cl:unless (cl:svref cell 1)
    (cl:setf (cl:svref cell 1) cl:t)
    (cl:let ((p (cl:svref cell 2)))
      (cl:dolist (f (cl:svref cell 0))
	(cl:cond ((cl:simple-vector-p f)
		  ;; a Haskell IO action (Foreign.Concurrent.newForeignPtr)
		  (run-io-action (cl:svref f 0)))
		 ((cl:consp f)
		  (cffi:foreign-funcall-pointer (cl:car f) () :pointer (cl:cdr f)
						:pointer p :void))
		 (cl:t
		  (cffi:foreign-funcall-pointer f () :pointer p :void)))))))

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
(cl:defun prim.add-fp-finalizer-io (state action)
  (cl:push (cl:vector action) (cl:svref (fp-state-cell state) 0)) 0)
(cl:defun prim.finalize-fp (state)
  (run-fp-finalizers (fp-state-cell state)) 0)
;;; touchForeignPtr: keeps STATE reachable until here
(cl:defun prim.touch-fp (state)
  (cl:if (fp-state-p state) 0 1))

;;; System.IO's hPutBuf and hGetBuf: N bytes between memory at P and the
;;; handle H, one Char per byte, as a binary handle (openBinaryFile,
;;; hSetBinaryMode) reads and writes them; on a text handle a byte over
;;; 127 is written as that code point.  hGetBuf returns the count read,
;;; less than N only at the end of the input.
(cl:defun prim.h-put-buf (h p n)
  (cl:let ((s (handle-stream h)))
    (cl:dotimes (i n)
      (cl:write-char (cl:code-char (cffi:mem-aref p :uint8 i)) s))
    (after-output h cl:nil))
  0)

(cl:defun prim.h-get-buf (h p n)
  (cl:let ((s (handle-stream h)))
    (cl:dotimes (i n n)
      (cl:let ((c (cl:read-char s cl:nil cl:nil)))
	(cl:unless c (cl:return i))
	(cl:setf (cffi:mem-aref p :uint8 i) (cl:logand (cl:char-code c) 255))))))

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

;;; Callbacks: Haskell functions called from C ("wrapper" imports and
;;; foreign export).  A C function pointer has no room for an
;;; environment, so every live callback needs code of its own.  A
;;; callback pool, one per "wrapper" import (one C signature), is a
;;; trampoline table: slot I is a CFFI callback, compiled when the pool
;;; first needs it, that calls the pool's ADAPTER with the Haskell
;;; function in FNS[I] and the C arguments.  freeHaskellFunPtr empties
;;; the slot and puts it on the free list; the code is kept for reuse.
;;; The adapter (generated by backend/interface-codegen.mumble) converts
;;; the arguments, applies the function and converts its result.

(cl:defstruct (callback-pool
	       (:constructor make-callback-pool (name adapter rtype atypes)))
  name adapter rtype atypes
  (fns (cl:make-array 4 :adjustable cl:t :fill-pointer 0))
  (pointers (cl:make-array 4 :adjustable cl:t :fill-pointer 0))
  (free '()))

;;; a live callback's address -> (pool . slot)
(cl:defvar *callback-slots* (cl:make-hash-table))

;;; Compile a CFFI callback named SYM that calls FN on its C arguments,
;;; and return its address.  CFFI's callbacks are defined by a macro, so
;;; one made at run time goes through EVAL.
(cl:defun ffi-compile-callback (sym rtype atypes fn)
  (cl:let ((params (cl:loop for i from 0 below (cl:length atypes)
			    collect (cl:intern (cl:format cl:nil "A~D" i)))))
    (cl:eval `(cffi:defcallback ,sym ,rtype
		  ,(cl:mapcar #'cl:list params atypes)
		(cl:funcall ',fn ,@params)))
    (cffi:get-callback sym)))

(cl:defun ffi-make-callback-pool (name adapter rtype atypes)
  (make-callback-pool name adapter rtype atypes))

;;; The FunPtr for the Haskell function FN (evaluated), in a free slot of
;;; POOL or a new one.
(cl:defun ffi-new-callback (pool fn)
  (cl:let ((i (cl:pop (callback-pool-free pool))))
    (cl:if i
	   (cl:setf (cl:aref (callback-pool-fns pool) i) fn)
	   (cl:progn
	     (cl:setf i (cl:vector-push-extend fn (callback-pool-fns pool)))
	     (cl:let* ((fns (callback-pool-fns pool))
		       (adapter (callback-pool-adapter pool))
		       (slot i)
		       (p (ffi-compile-callback
			   (cl:intern (cl:format cl:nil "~A/CALLBACK-~D"
						 (callback-pool-name pool) i))
			   (callback-pool-rtype pool) (callback-pool-atypes pool)
			   (cl:lambda (cl:&rest args)
			     (cl:apply adapter (cl:aref fns slot) args)))))
	       (cl:vector-push-extend p (callback-pool-pointers pool)))))
    (cl:let ((p (cl:aref (callback-pool-pointers pool) i)))
      (cl:setf (cl:gethash (cffi:pointer-address p) *callback-slots*)
	       (cl:cons pool i))
      p)))

;;; freeHaskellFunPtr: a FunPtr that is not a live callback (one from C,
;;; or already freed) is left alone, as GHC's is undefined there.
(cl:defun prim.free-haskell-fun-ptr (p)
  (cl:let* ((a (cffi:pointer-address p))
	    (entry (cl:gethash a *callback-slots*)))
    (cl:when entry
      (cl:remhash a *callback-slots*)
      (cl:let ((pool (cl:car entry)) (i (cl:cdr entry)))
	(cl:setf (cl:aref (callback-pool-fns pool) i) cl:nil)
	(cl:push i (callback-pool-free pool)))))
  0)

;;; foreign export ccall "name" f :: T.  The callback calls the current
;;; value of the global VALUE-SYM (f, under its declared type) through
;;; ADAPTER.  C code that is already linked cannot see it by name (that
;;; would need a C stub), but `foreign import ccall "&name"` finds it, so
;;; Haskell can pass it to C as a FunPtr.
(cl:defvar *foreign-exports* (cl:make-hash-table :test #'cl:equal))

(cl:defun ffi-define-export (name value-sym adapter rtype atypes)
  (cl:setf (cl:gethash name *foreign-exports*)
	   (ffi-compile-callback
	    (cl:intern (cl:format cl:nil "FOREIGN-EXPORT/~A" name))
	    rtype atypes
	    (cl:lambda (cl:&rest args)
	      (cl:apply adapter (force (cl:symbol-value value-sym)) args))))
  0)
