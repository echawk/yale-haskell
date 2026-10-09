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
