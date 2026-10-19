;;; primops-runtime.lisp -- GHC's primitive operations on arrays, byte
;;; arrays, addresses and mutable variables (lib/haskell98/GHC/PrimOps.hi),
;;; for packages written against GHC.Exts (primitive, vector, ...).  Plain
;;; CL in the MUMBLE-USER package, SBCL only, loaded into the image by
;;; yale-haskell/executable (yale-haskell.asd).
;;;
;;; A State# token is threaded as GHC threads it: every operation that
;;; reads or changes state takes the token, strictly, and returns it (or a
;;; pair (# token, value #), an ordinary tuple: lexer.mumble), so that the
;;; operations happen in the order the tokens are passed.  The token itself
;;; is any value (0).
;;;
;;; Representations:
;;;   Array# a, MutableArray# s a, SmallArray#, SmallMutableArray#
;;;                       simple vectors of boxed values (freezing in place
;;;                       is the identity);
;;;   ByteArray#, MutableByteArray# s
;;;                       a BYTES struct: memory from malloc (freed by a
;;;                       finalizer), so that it never moves and its
;;;                       contents have a stable Addr#;
;;;   Addr#               a system-area pointer (as Ptr is, Foreign.Ptr);
;;;                       a literal "..."# is copied to memory once;
;;;   MutVar# s a         a one-element vector, as Data.IORef's cells;
;;;   MVar# s a           a one-element vector, *empty-mvar* when empty
;;;                       (one thread: taking from an empty one fails);
;;;   StablePtr# a        an index into a table of objects.
;;; Indexes are in elements of the access's size, as GHC's.  A Char is
;;; its code, as everywhere in the runtime.  Multi-byte
;;; values are in the machine's order (little-endian).

(cl:in-package "MUMBLE-USER")

(cl:defconstant +state-token+ 0)

(cl:defmacro with-state ((s) cl:&body body)
  "Evaluate BODY after S (the incoming token, already evaluated: the
operations are strict in it) and return the token."
  `(cl:progn ,s ,@body +state-token+))

(cl:defmacro state-and (s value)
  `(cl:progn ,s (make-tuple +state-token+ ,value)))

;;; ------------------------------------------------------------------
;;; Byte arrays

(cl:defstruct (prim-bytes (:constructor %make-prim-bytes (sap size)))
  sap size)

(cl:defun make-bytes (n)
  (cl:let* ((sap (sb-alien:alien-sap (sb-alien:make-alien (sb-alien:unsigned 8) (cl:max n 1))))
            (b (%make-prim-bytes sap n)))
    (sb-ext:finalize b (cl:lambda () (sb-alien:free-alien
                                      (sb-alien:sap-alien sap (cl:* (sb-alien:unsigned 8)))))
                     :dont-save cl:t)
    b))

(cl:defun prim.new-byte-array# (n s) (state-and s (make-bytes n)))
(cl:defun prim.new-pinned-byte-array# (n s) (state-and s (make-bytes n)))
(cl:defun prim.new-aligned-pinned-byte-array# (n align s)
  (cl:declare (cl:ignore align))
  (state-and s (make-bytes n)))
;;; Its address may outlive the array (a ForeignPtr made from it keeps
;;; nothing alive, GHC.ForeignPtr): an array whose contents are taken is
;;; never freed.
(cl:defun prim.byte-array-contents# (b)
  (sb-ext:cancel-finalization b)
  (prim-bytes-sap b))
(cl:defun prim.mutable-byte-array-contents# (b)
  (sb-ext:cancel-finalization b)
  (prim-bytes-sap b))
(cl:defun prim.sizeof-byte-array# (b) (prim-bytes-size b))
(cl:defun prim.sizeof-mutable-byte-array# (b) (prim-bytes-size b))
(cl:defun prim.get-sizeof-mutable-byte-array# (b s) (state-and s (prim-bytes-size b)))
(cl:defun prim.unsafe-freeze-byte-array# (b s) (state-and s b))
(cl:defun prim.unsafe-thaw-byte-array# (b s) (state-and s b))
(cl:defun prim.is-pinned# (b) (cl:declare (cl:ignore b)) 1)
(cl:defun prim.same-byte-array# (a b) (cl:if (cl:eq a b) 1 0))

(cl:defun prim.shrink-mutable-byte-array# (b n s)
  (with-state (s) (cl:setf (prim-bytes-size b) n)))

(cl:defun prim.resize-mutable-byte-array# (b n s)
  (cl:if (cl:<= n (prim-bytes-size b))
         (cl:progn (cl:setf (prim-bytes-size b) n) (state-and s b))
         (cl:let ((new (make-bytes n)))
           (copy-memory (prim-bytes-sap b) 0 (prim-bytes-sap new) 0 (prim-bytes-size b))
           (state-and s new))))

(cl:defun copy-memory (from from-off to to-off n)
  "Copy N bytes (overlapping allowed)."
  (cl:when (cl:plusp n)
    (cl:let ((src (sb-sys:sap+ from from-off))
             (dst (sb-sys:sap+ to to-off)))
      (cl:if (cl:and (sb-sys:sap> dst src) (sb-sys:sap< dst (sb-sys:sap+ src n)))
             (cl:loop for i from (cl:1- n) downto 0
                      do (cl:setf (sb-sys:sap-ref-8 dst i) (sb-sys:sap-ref-8 src i)))
             (cl:loop for i below n
                      do (cl:setf (sb-sys:sap-ref-8 dst i) (sb-sys:sap-ref-8 src i)))))))

(cl:defun prim.copy-byte-array# (src so dst do n s)
  (with-state (s) (copy-memory (prim-bytes-sap src) so (prim-bytes-sap dst) do n)))
(cl:defun prim.copy-mutable-byte-array# (src so dst do n s)
  (with-state (s) (copy-memory (prim-bytes-sap src) so (prim-bytes-sap dst) do n)))
(cl:defun prim.copy-byte-array-to-addr# (src so dst n s)
  (with-state (s) (copy-memory (prim-bytes-sap src) so dst 0 n)))
(cl:defun prim.copy-mutable-byte-array-to-addr# (src so dst n s)
  (with-state (s) (copy-memory (prim-bytes-sap src) so dst 0 n)))
(cl:defun prim.copy-addr-to-byte-array# (src dst do n s)
  (with-state (s) (copy-memory src 0 (prim-bytes-sap dst) do n)))

(cl:defun prim.set-byte-array# (b off n byte s)
  (with-state (s)
    (cl:let ((sap (prim-bytes-sap b)))
      (cl:loop for i from off below (cl:+ off n)
               do (cl:setf (sb-sys:sap-ref-8 sap i) (cl:logand byte 255))))))

(cl:defun prim.compare-byte-arrays# (a ao b bo n)
  (cl:let ((sa (prim-bytes-sap a)) (sb (prim-bytes-sap b)))
    (cl:loop for i below n
             do (cl:let ((x (sb-sys:sap-ref-8 sa (cl:+ ao i)))
                         (y (sb-sys:sap-ref-8 sb (cl:+ bo i))))
                  (cl:cond ((cl:< x y) (cl:return -1))
                           ((cl:> x y) (cl:return 1))))
             finally (cl:return 0))))

;;; Typed access: FAMILY is the name in the primop (Int, Word8, ...); REF
;;; reads at a byte offset; SIZE is the element size; TO converts the
;;; stored value to Haskell's, FROM back.
(cl:defmacro define-typed-access (family ref size to from)
  (cl:flet ((name (fmt) (cl:intern (cl:format cl:nil fmt family) "MUMBLE-USER")))
    (cl:let ((get `(cl:lambda (sap off) (,to (,ref sap (cl:* off ,size)))))
             (put `(cl:lambda (sap off x) (cl:setf (,ref sap (cl:* off ,size)) (,from x)))))
      `(cl:progn
         (cl:defun ,(name "PRIM.INDEX-~a-ARRAY#") (b i) (cl:funcall ,get (prim-bytes-sap b) i))
         (cl:defun ,(name "PRIM.READ-~a-ARRAY#") (b i s)
           (state-and s (cl:funcall ,get (prim-bytes-sap b) i)))
         (cl:defun ,(name "PRIM.WRITE-~a-ARRAY#") (b i x s)
           (with-state (s) (cl:funcall ,put (prim-bytes-sap b) i x)))
         (cl:defun ,(name "PRIM.INDEX-~a-OFF-ADDR#") (a i) (cl:funcall ,get a i))
         (cl:defun ,(name "PRIM.READ-~a-OFF-ADDR#") (a i s) (state-and s (cl:funcall ,get a i)))
         (cl:defun ,(name "PRIM.WRITE-~a-OFF-ADDR#") (a i x s)
           (with-state (s) (cl:funcall ,put a i x)))
         (cl:defun ,(name "PRIM.SET-~a-ARRAY#") (b off n x s)
           (with-state (s)
             (cl:loop for i from off below (cl:+ off n)
                      do (cl:funcall ,put (prim-bytes-sap b) i x))))
         (cl:defun ,(name "PRIM.SET-~a-OFF-ADDR#") (a off n x s)
           (with-state (s)
             (cl:loop for i from off below (cl:+ off n)
                      do (cl:funcall ,put a i x))))))))

(cl:defun identity1 (x) x)

(define-typed-access "CHAR" sb-sys:sap-ref-8 1 identity1 identity1)
(define-typed-access "WIDE-CHAR" sb-sys:sap-ref-32 4 identity1 identity1)
(define-typed-access "INT" sb-sys:signed-sap-ref-64 8 identity1 identity1)
(define-typed-access "WORD" sb-sys:sap-ref-64 8 identity1 identity1)
(define-typed-access "INT8" sb-sys:signed-sap-ref-8 1 identity1 identity1)
(define-typed-access "INT16" sb-sys:signed-sap-ref-16 2 identity1 identity1)
(define-typed-access "INT32" sb-sys:signed-sap-ref-32 4 identity1 identity1)
(define-typed-access "INT64" sb-sys:signed-sap-ref-64 8 identity1 identity1)
(define-typed-access "WORD8" sb-sys:sap-ref-8 1 identity1 identity1)
(define-typed-access "WORD16" sb-sys:sap-ref-16 2 identity1 identity1)
(define-typed-access "WORD32" sb-sys:sap-ref-32 4 identity1 identity1)
(define-typed-access "WORD64" sb-sys:sap-ref-64 8 identity1 identity1)
(define-typed-access "FLOAT" sb-sys:sap-ref-single 4 identity1 identity1)
(define-typed-access "DOUBLE" sb-sys:sap-ref-double 8 identity1 identity1)
(define-typed-access "ADDR" sb-sys:sap-ref-sap 8 identity1 identity1)
(define-typed-access "STABLE-PTR" sb-sys:sap-ref-64 8 identity1 identity1)

;;; Atomic operations on Int arrays (one thread here, or a lock-free
;;; compare-and-swap is not needed: the spark pool does not run IO).
(cl:defun prim.cas-int-array# (b i old new s)
  (cl:let* ((sap (prim-bytes-sap b)) (cur (sb-sys:signed-sap-ref-64 sap (cl:* i 8))))
    (cl:when (cl:= cur old) (cl:setf (sb-sys:signed-sap-ref-64 sap (cl:* i 8)) new))
    (state-and s cur)))
(cl:defmacro define-fetch-op (name op)
  `(cl:defun ,name (b i x s)
     (cl:let* ((sap (prim-bytes-sap b)) (cur (sb-sys:signed-sap-ref-64 sap (cl:* i 8))))
       (cl:setf (sb-sys:signed-sap-ref-64 sap (cl:* i 8))
                (wrap-int64 (,op cur x)))
       (state-and s cur))))
(cl:defun wrap-int64 (n)
  (cl:let ((m (cl:ldb (cl:byte 64 0) n)))
    (cl:if (cl:logbitp 63 m) (cl:- m (cl:expt 2 64)) m)))
(cl:defun lognand2 (a b) (cl:lognot (cl:logand a b)))
(define-fetch-op prim.fetch-add-int-array# cl:+)
(define-fetch-op prim.fetch-sub-int-array# cl:-)
(define-fetch-op prim.fetch-and-int-array# cl:logand)
(define-fetch-op prim.fetch-or-int-array# cl:logior)
(define-fetch-op prim.fetch-xor-int-array# cl:logxor)
(define-fetch-op prim.fetch-nand-int-array# lognand2)
(cl:defun prim.atomic-read-int-array# (b i s)
  (state-and s (sb-sys:signed-sap-ref-64 (prim-bytes-sap b) (cl:* i 8))))
(cl:defun prim.atomic-write-int-array# (b i x s)
  (with-state (s) (cl:setf (sb-sys:signed-sap-ref-64 (prim-bytes-sap b) (cl:* i 8)) x)))

;;; ------------------------------------------------------------------
;;; Addresses

(cl:defparameter prim.null-addr# (sb-sys:int-sap 0))
(cl:defun prim.plus-addr# (a n) (sb-sys:sap+ a n))
(cl:defun prim.minus-addr# (a b) (sb-sys:sap- a b))
(cl:defun prim.addr-to-int# (a) (sb-sys:sap-int a))
(cl:defun prim.int-to-addr# (n) (sb-sys:int-sap (cl:ldb (cl:byte 64 0) n)))
(cl:defun prim.eq-addr# (a b) (cl:if (sb-sys:sap= a b) 1 0))
(cl:defun prim.lt-addr# (a b) (cl:if (sb-sys:sap< a b) 1 0))

;;; "..."#: the string's bytes (its chars' codes, mod 256), NUL-terminated,
;;; copied once into memory that is never freed (a literal is a constant).
(cl:defun prim.addr-lit# (s)
  (cl:let* ((str (cl:if (cl:stringp s) s (haskell-string->string s)))
            (n (cl:length str))
            (sap (sb-alien:alien-sap (sb-alien:make-alien (sb-alien:unsigned 8) (cl:1+ n)))))
    (cl:dotimes (i n) (cl:setf (sb-sys:sap-ref-8 sap i) (cl:logand (cl:char-code (cl:char str i)) 255)))
    (cl:setf (sb-sys:sap-ref-8 sap n) 0)
    sap))

;;; ------------------------------------------------------------------
;;; Boxed arrays (Array#, SmallArray# alike)

(cl:defun prim.new-array# (n x s) (state-and s (cl:make-array n :initial-element x)))
(cl:defun prim.read-array# (a i s) (state-and s (cl:svref a i)))
(cl:defun prim.write-array# (a i x s) (with-state (s) (cl:setf (cl:svref a i) x)))
(cl:defun prim.index-array# (a i) (cl:svref a i))
(cl:defun prim.sizeof-array# (a) (cl:length a))
(cl:defun prim.get-sizeof-array# (a s) (state-and s (cl:length a)))
(cl:defun prim.unsafe-freeze-array# (a s) (state-and s a))
(cl:defun prim.unsafe-thaw-array# (a s) (state-and s a))
(cl:defun prim.freeze-array# (a off n s) (state-and s (cl:subseq a off (cl:+ off n))))
(cl:defun prim.thaw-array# (a off n s) (state-and s (cl:subseq a off (cl:+ off n))))
(cl:defun prim.clone-array# (a off n) (cl:subseq a off (cl:+ off n)))
(cl:defun prim.clone-mutable-array# (a off n s) (state-and s (cl:subseq a off (cl:+ off n))))
(cl:defun prim.copy-array# (src so dst do n s)
  (with-state (s) (cl:replace dst src :start1 do :end1 (cl:+ do n) :start2 so)))
(cl:defun prim.same-array# (a b) (cl:if (cl:eq a b) 1 0))
(cl:defun prim.shrink-array# (a n s)
  ;; a simple vector cannot shrink: the caller keeps using the old one
  (cl:declare (cl:ignore a n))
  s)
(cl:defun prim.resize-array# (a n x s)
  (cl:let ((new (cl:make-array n :initial-element x)))
    (cl:replace new a)
    (state-and s new)))
(cl:defun prim.cas-array# (a i old new s)
  (cl:let ((cur (cl:svref a i)))
    (cl:if (cl:eq cur old)
           (cl:progn (cl:setf (cl:svref a i) new) (state-and s (make-tuple 0 new)))
           (state-and s (make-tuple 1 cur)))))

;;; ------------------------------------------------------------------
;;; Mutable variables and MVars

(cl:defun prim.new-mut-var# (x s) (state-and s (cl:vector x)))
(cl:defun prim.read-mut-var# (v s) (state-and s (cl:svref v 0)))
(cl:defun prim.write-mut-var# (v x s) (with-state (s) (cl:setf (cl:svref v 0) x)))
(cl:defun prim.same-mut-var# (a b) (cl:if (cl:eq a b) 1 0))
(cl:defun prim.cas-mut-var# (v old new s)
  (cl:let ((cur (cl:svref v 0)))
    (cl:if (cl:eq cur old)
           (cl:progn (cl:setf (cl:svref v 0) new) (state-and s (make-tuple 0 new)))
           (state-and s (make-tuple 1 cur)))))

(cl:defvar *empty-mvar* (cl:make-symbol "EMPTY-MVAR"))
(cl:defun prim.new-mvar# (s) (state-and s (cl:vector *empty-mvar*)))
(cl:defun mvar-blocked ()
  (haskell-runtime-error "thread blocked indefinitely in an MVar operation"))
(cl:defun prim.take-mvar# (v s)
  (cl:let ((x (cl:svref v 0)))
    (cl:when (cl:eq x *empty-mvar*) (mvar-blocked))
    (cl:setf (cl:svref v 0) *empty-mvar*)
    (state-and s x)))
(cl:defun prim.read-mvar# (v s)
  (cl:let ((x (cl:svref v 0)))
    (cl:when (cl:eq x *empty-mvar*) (mvar-blocked))
    (state-and s x)))
(cl:defun prim.put-mvar# (v x s)
  (cl:unless (cl:eq (cl:svref v 0) *empty-mvar*) (mvar-blocked))
  (with-state (s) (cl:setf (cl:svref v 0) x)))
;;; the try forms answer (# s, 0 or 1, value #) as a pair of pairs
(cl:defun prim.try-take-mvar# (v s)
  (cl:let ((x (cl:svref v 0)))
    (cl:if (cl:eq x *empty-mvar*)
           (state-and s (make-tuple 0 0))
           (cl:progn (cl:setf (cl:svref v 0) *empty-mvar*) (state-and s (make-tuple 1 x))))))
(cl:defun prim.try-read-mvar# (v s)
  (cl:let ((x (cl:svref v 0)))
    (cl:if (cl:eq x *empty-mvar*)
           (state-and s (make-tuple 0 0))
           (state-and s (make-tuple 1 x)))))
(cl:defun prim.try-put-mvar# (v x s)
  (cl:if (cl:eq (cl:svref v 0) *empty-mvar*)
         (cl:progn (cl:setf (cl:svref v 0) x) (state-and s 1))
         (state-and s 0)))
(cl:defun prim.is-empty-mvar# (v s) (state-and s (cl:if (cl:eq (cl:svref v 0) *empty-mvar*) 1 0)))
(cl:defun prim.same-mvar# (a b) (cl:if (cl:eq a b) 1 0))

;;; ------------------------------------------------------------------
;;; Stable pointers

(cl:defvar *stable-objects* (cl:make-array 16 :adjustable cl:t :fill-pointer 1))
(cl:defun prim.make-stable-ptr# (x s)
  (state-and s (cl:vector-push-extend x *stable-objects*)))
(cl:defun prim.deref-stable-ptr# (p s) (state-and s (cl:aref *stable-objects* p)))
(cl:defun prim.free-stable-ptr# (p s) (with-state (s) (cl:setf (cl:aref *stable-objects* p) 0)))
(cl:defun prim.eq-stable-ptr# (a b) (cl:if (cl:eql a b) 1 0))

;;; ------------------------------------------------------------------
;;; The rest

(cl:defun prim.touch# (x s) (cl:declare (cl:ignore x)) s)
(cl:defun prim.really-unsafe-ptr-equality# (a b) (cl:if (cl:eq a b) 1 0))
