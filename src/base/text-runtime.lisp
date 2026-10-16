;;; text-runtime.lisp -- the packed representations of Data.Text and
;;; Data.ByteString (lib/haskell98/TextPrims.hi).  Plain CL in the
;;; MUMBLE-USER package, loaded into the image by tools/build/runtime.lisp
;;; like base-runtime.lisp.
;;;
;;; A Text is a simple string of characters, a ByteString a simple vector
;;; of octets; both are immutable once made.  A Haskell Char is its code,
;;; Bool a Lisp boolean, and a Haskell list a chain of conses whose cars
;;; and cdrs may be thunks.  A list of texts crosses as the opaque
;;; TextList / BytesList: given, it is forced here (force-list); made
;;; here, it is a plain Lisp list, which is a Haskell list as it stands.
;;; Functions passed in (map, filter, span, folds) are evaluated Haskell
;;; functions, called with apply-1 / apply-2.

(cl:in-package "MUMBLE-USER")

(cl:deftype text () '(cl:simple-array cl:character (cl:*)))
(cl:deftype bytes () '(cl:simple-array (cl:unsigned-byte 8) (cl:*)))

(cl:defmacro with-text-speed (cl:&body body)
  `(cl:locally (cl:declare (cl:optimize (cl:speed 3) (cl:safety 0) (cl:debug 0)))
     ,@body))

(cl:declaim (cl:inline new-text))
(cl:defun new-text (n) (cl:make-string n :element-type 'cl:character))

;;; A Haskell list (forced cell by cell) as a Lisp list of its forced
;;; elements; no recursion, so long lists are fine.
(cl:defun force-list (l)
  (cl:let ((res '()))
    (cl:loop for cell = (force l) then (force (cl:cdr cell))
	     until (cl:null cell)
	     do (cl:push (force (cl:car cell)) res))
    (cl:nreverse res)))

(cl:defun text-from-string (s)
  (cl:if (cl:typep s 'text) s (cl:coerce s 'text)))

;;; Haskell's Data.Char.isSpace (PreludeChar.hs)
(cl:declaim (cl:inline space-code-p))
(cl:defun space-code-p (c)
  (cl:declare (cl:fixnum c))
  (cl:or (cl:= c 32) (cl:<= 9 c 13) (cl:= c 160)))

(cl:defmacro call-pred (p c)
  `(force (apply-1 ,p (cl:char-code ,c))))

;;; Conversions

(cl:defun prim.text-pack (s) (text-from-string s))
(cl:defun prim.text-unpack (s) s)
(cl:defun prim.text-singleton (c) (cl:make-string 1 :initial-element c))
(cl:defun prim.text-empty () (new-text 0))

;;; Size and access

(cl:defun prim.text-length (s) (cl:length (cl:the text s)))
(cl:defun prim.text-index (s i)
  (cl:char-code (cl:schar (cl:the text s) i)))

;;; Comparison: -1, 0 or 1 by code points, as Haskell's String order.
(cl:defun prim.text-compare (a b)
  (with-text-speed
    (cl:let* ((a a) (b b)
	      (la (cl:length a)) (lb (cl:length b))
	      (m (cl:mismatch a b)))
      (cl:declare (text a b) (cl:fixnum la lb))
      (cl:cond ((cl:null m) 0)
	       ((cl:= m la) -1)
	       ((cl:= m lb) 1)
	       ((cl:char< (cl:schar a m) (cl:schar b m)) -1)
	       (cl:t 1)))))

(cl:defun prim.text-eq (a b) (cl:string= (cl:the text a) (cl:the text b)))

;;; Building

(cl:defun prim.text-append (a b)
  (cl:concatenate 'text a b))

(cl:defun prim.text-concat (l)
  (concat-texts (force-list l)))

(cl:defun concat-texts (parts)
  (with-text-speed
    (cl:let* ((n (cl:loop for p in parts sum (cl:length (cl:the text p)) fixnum))
	      (res (new-text n))
	      (i 0))
      (cl:declare (cl:fixnum n i))
      (cl:dolist (p parts res)
	(cl:replace res (cl:the text p) :start1 i)
	(cl:incf i (cl:length (cl:the text p)))))))

(cl:defun prim.text-intercalate (sep l)
  (cl:let ((parts (force-list l)))
    (concat-texts (cl:loop for (p . rest) on parts
			   collect p
			   when rest collect sep))))

(cl:defun prim.text-cons (c s)
  (cl:let ((r (new-text (cl:1+ (cl:length s)))))
    (cl:setf (cl:schar r 0) c)
    (cl:replace r s :start1 1)
    r))

(cl:defun prim.text-snoc (s c)
  (cl:let ((r (new-text (cl:1+ (cl:length s)))))
    (cl:replace r s)
    (cl:setf (cl:schar r (cl:length s)) c)
    r))

(cl:defun prim.text-replicate (n s)
  (cl:if (cl:<= n 0)
	 (new-text 0)
	 (concat-texts (cl:make-list n :initial-element s))))

(cl:defun prim.text-reverse (s) (cl:reverse (cl:the text s)))

;;; Slices, clamped to the text: START <= END.
(cl:defun prim.text-slice (s start end)
  (cl:let* ((n (cl:length (cl:the text s)))
	    (a (cl:max 0 (cl:min start n)))
	    (b (cl:max a (cl:min end n))))
    (cl:if (cl:and (cl:= a 0) (cl:= b n)) s (cl:subseq s a b))))

;;; The position of NEEDLE in HAY at or after START, or nil: CL's search
;;; on strings is generic (an element access through the array header
;;; per comparison, a third of textproc's searching time).
(cl:declaim (cl:inline text-find))
(cl:defun text-find (needle hay start)
  (with-text-speed
    (cl:let* ((needle needle) (hay hay) (start start)
	      (m (cl:length needle))
	      (last (cl:- (cl:length hay) m)))
      (cl:declare (text needle hay) (cl:fixnum start m last))
      (cl:cond ((cl:> start last) cl:nil)
	       ((cl:= m 0) start)
	       (cl:t
		(cl:let ((c0 (cl:schar needle 0)))
		  (cl:loop for i of-type cl:fixnum from start to last
			   when (cl:and (cl:char= (cl:schar hay i) c0)
					(cl:loop for j of-type cl:fixnum from 1 below m
						 always (cl:char= (cl:schar hay (cl:+ i j))
								  (cl:schar needle j))))
			     return i)))))))

;;; Searching: the position of NEEDLE in HAY at or after START, or -1.
(cl:defun prim.text-search (needle hay start)
  (cl:or (text-find needle hay start) -1))

(cl:defun prim.text-is-prefix (a b)
  (cl:let ((la (cl:length a)))
    (cl:and (cl:<= la (cl:length b)) (cl:string= a b :end2 la))))

(cl:defun prim.text-is-suffix (a b)
  (cl:let ((la (cl:length a)) (lb (cl:length b)))
    (cl:and (cl:<= la lb) (cl:string= a b :start2 (cl:- lb la)))))

(cl:defun prim.text-is-infix (a b)
  (cl:if (text-find a b 0) cl:t cl:nil))

;;; Non-overlapping occurrences of NEEDLE (not empty)
(cl:defun prim.text-count (needle hay)
  (cl:let ((n (cl:length needle)))
    (cl:loop for i = (text-find needle hay 0) then (text-find needle hay (cl:+ i n))
	     while i count cl:t)))

(cl:defun prim.text-replace (needle rep hay)
  (cl:let ((n (cl:length needle))
	   (parts '())
	   (start 0))
    (cl:loop for i = (text-find needle hay start)
	     while i
	     do (cl:push (cl:subseq hay start i) parts)
		(cl:push rep parts)
		(cl:setf start (cl:+ i n)))
    (cl:if (cl:= start 0)
	   hay
	   (cl:progn (cl:push (cl:subseq hay start) parts)
		     (concat-texts (cl:nreverse parts))))))

;;; splitOn SEP (not empty)
(cl:defun prim.text-split-on (sep s)
  (cl:let ((n (cl:length sep))
	   (parts '())
	   (start 0))
    (cl:loop for i = (text-find sep s start)
	     while i
	     do (cl:push (cl:subseq s start i) parts)
		(cl:setf start (cl:+ i n)))
    (cl:push (cl:subseq s start) parts)
    (cl:nreverse parts)))

;;; lines: split at newlines; a final newline ends the last line.
(cl:defun prim.text-lines (s)
  (with-text-speed
    (cl:let ((s s) (n (cl:length s)) (parts '()) (start 0))
      (cl:declare (text s) (cl:fixnum n start))
      (cl:loop
	(cl:when (cl:>= start n) (cl:return (cl:nreverse parts)))
	(cl:let ((i (cl:position #\Newline s :start start)))
	  (cl:push (cl:subseq s start (cl:or i n)) parts)
	  (cl:setf start (cl:if i (cl:1+ (cl:the cl:fixnum i)) n)))))))

(cl:defun prim.text-words (s)
  (with-text-speed
    (cl:let ((s s) (n (cl:length s)) (parts '()) (i 0))
      (cl:declare (text s) (cl:fixnum n i))
      (cl:loop
	(cl:loop while (cl:and (cl:< i n) (space-code-p (cl:char-code (cl:schar s i))))
		 do (cl:incf i))
	(cl:when (cl:>= i n) (cl:return (cl:nreverse parts)))
	(cl:let ((start i))
	  (cl:loop while (cl:and (cl:< i n)
				 (cl:not (space-code-p (cl:char-code (cl:schar s i)))))
		   do (cl:incf i))
	  (cl:push (cl:subseq s start i) parts))))))

(cl:defun prim.text-unlines (l)
  (concat-texts (cl:loop for p in (force-list l)
			 collect p collect (cl:string #\Newline))))

(cl:defun prim.text-unwords (l)
  (prim.text-intercalate (cl:string #\Space) l))

;;; The leading run of spaces, and the trailing one: strip and friends.
(cl:defun prim.text-strip (s which)	; 0 both, 1 start, 2 end
  (cl:let* ((n (cl:length s))
	    (a (cl:if (cl:= which 2) 0
		      (cl:or (cl:position-if-not (cl:lambda (c) (space-code-p (cl:char-code c))) s)
			     n)))
	    (b (cl:if (cl:= which 1) n
		      (cl:let ((j (cl:position-if-not (cl:lambda (c) (space-code-p (cl:char-code c)))
						      s :from-end cl:t)))
			(cl:if j (cl:1+ j) a)))))
    (prim.text-slice s a (cl:max a b))))

;;; Higher-order

(cl:defun prim.text-map (f s)
  (cl:let* ((n (cl:length (cl:the text s)))
	    (r (new-text n)))
    (cl:dotimes (i n r)
      (cl:setf (cl:schar r i)
	       (cl:code-char (force (apply-1 f (cl:char-code (cl:schar s i)))))))))

(cl:defun prim.text-filter (p s)
  (cl:let* ((s s) (n (cl:length s)) (out (new-text n)) (k 0))
    (cl:declare (text s out) (cl:fixnum n k))
    (cl:loop for i of-type cl:fixnum from 0 below n
	     do (cl:let ((c (cl:schar s i)))
		  (cl:when (call-pred p c)
		    (cl:setf (cl:schar out k) c)
		    (cl:incf k))))
    (cl:if (cl:= k n) out (cl:subseq out 0 k))))

;;; The length of the longest prefix whose characters satisfy P, and of
;;; the longest such suffix.
(cl:defun prim.text-span-length (p s)
  (cl:or (cl:position-if-not (cl:lambda (c) (call-pred p c)) (cl:the text s))
	 (cl:length s)))

(cl:defun prim.text-span-length-end (p s)
  (cl:let ((j (cl:position-if-not (cl:lambda (c) (call-pred p c)) (cl:the text s)
				  :from-end cl:t)))
    (cl:if j (cl:- (cl:length s) j 1) (cl:length s))))

;;; The index of the first character satisfying P, or -1.
(cl:defun prim.text-find-index (p s)
  (cl:or (cl:position-if (cl:lambda (c) (call-pred p c)) (cl:the text s)) -1))

;;; foldl', with the accumulator evaluated at each step
(cl:defun prim.text-foldl-strict (f z s)
  (cl:let ((acc (force z)))
    (cl:loop for c across (cl:the text s)
	     do (cl:setf acc (force (apply-2 f acc (cl:char-code c)))))
    acc))

(cl:defun prim.text-to-upper (s)
  (cl:map 'text (cl:lambda (c) (cl:code-char (prim.unicode-to-upper (cl:char-code c)))) s))
(cl:defun prim.text-to-lower (s)
  (cl:map 'text (cl:lambda (c) (cl:code-char (prim.unicode-to-lower (cl:char-code c)))) s))

;;; Text IO: whole files and the rest of a handle in one string (UTF-8,
;;; as the handles are; invalid bytes are U+FFFD).

(cl:defun prim.text-read-file (name)
  (with-host-io-errors "readFile" name
    (cl:with-open-file (in (native-pathname name) :external-format *file-external-format*)
      (read-rest-of-stream in))))

(cl:defun read-rest-of-stream (in)
  (cl:let ((out (cl:make-string-output-stream))
	   (buf (new-text 65536)))
    (cl:loop for n = (cl:read-sequence buf in)
	     while (cl:> n 0)
	     do (cl:write-string buf out :end n))
    (text-from-string (cl:get-output-stream-string out))))

;;; hGetContents: the handle is then semi-closed, as GHC's is (here at
;;; once, since the contents are read at once).
(cl:defun prim.text-h-get-contents (h)
  (check-readable h "hGetContents")
  (cl:prog1 (with-handle-errors "hGetContents" h
	      (read-rest-of-stream (handle-stream h)))
    (cl:unless (standard-handle? h)
      (cl:close (handle-stream h)))
    (cl:setf (haskell-handle-state h) 'semi-closed)))

(cl:defun prim.text-h-put-str (h s)
  (check-writable h "hPutStr")
  (with-handle-errors "hPutStr" h
    (cl:write-string s (handle-stream h))
    (after-output h (cl:find #\Newline s)))
  0)

;;; ByteString IO (Data.ByteString.Char8): a ByteString is a string of
;;; characters 0..255, one per byte.  A file is read in Latin-1.  On a
;;; handle whose encoding is not Latin-1 (stdout, a text file), the bytes
;;; written are those of the ByteString: they are decoded as UTF-8 first,
;;; which the handle encodes back (bytes that are not UTF-8 become
;;; U+FFFD); bytes read from such a handle are its text encoded in UTF-8.

(cl:defun prim.bytes-read-file (name)
  (with-host-io-errors "readFile" name
    (cl:with-open-file (in (native-pathname name) :external-format :latin-1)
      (read-rest-of-stream in))))

(cl:defun latin-1-stream-p (s)
  #+sbcl (cl:let ((ef (cl:stream-external-format s)))
	   (cl:member (cl:if (cl:consp ef) (cl:car ef) ef) '(:latin-1 :latin1 :iso-8859-1)))
  #-sbcl cl:nil)

(cl:defun bytes-to-text (b)
  (cl:if (cl:every (cl:lambda (c) (cl:< (cl:char-code c) 128)) b)
	 b
	 #+sbcl
	 (text-from-string
	  (sb-ext:octets-to-string
	   (cl:map '(cl:vector (cl:unsigned-byte 8)) #'cl:char-code b)
	   :external-format '(:utf-8 :replacement #\U+FFFD)))
	 #-sbcl b))

(cl:defun text-to-bytes (s)
  (cl:if (cl:every (cl:lambda (c) (cl:< (cl:char-code c) 128)) s)
	 s
	 #+sbcl (cl:map 'text #'cl:code-char (sb-ext:string-to-octets s :external-format :utf-8))
	 #-sbcl s))

(cl:defun prim.bytes-h-put-str (h b)
  (cl:let ((s (handle-stream h)))
    (prim.text-h-put-str h (cl:if (latin-1-stream-p s) b (bytes-to-text b)))))

(cl:defun prim.bytes-h-get-contents (h)
  (cl:let* ((latin? (latin-1-stream-p (handle-stream h)))
	    (s (prim.text-h-get-contents h)))
    (cl:if latin? s (text-to-bytes s))))
