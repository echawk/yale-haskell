;;;; embed.lisp -- Haskell in Lisp source files, #@hs{ ... }# blocks
;;;; (doc/EMBEDDING.md), in the style of cl-sml's #@sml{ ... }#
;;;; (https://github.com/echawk/cl-sml at 891d4f6, src/reader.lisp).
;;;;
;;;; The reader collects a block's text, replacing each Lisp splice ($name
;;;; or $(form)) by a placeholder, and returns a %HS-BLOCK form.  That
;;;; macro compiles the block when it is expanded, so a compile error is
;;;; reported then, and expands into code that compiles it again when it
;;;; is loaded into an image that has not (a FASL loaded into a new image),
;;;; then evaluates it with the splices' values.  The compiler's side is
;;;; src/compiler/command-interface/embed.mumble.

(in-package :yale-haskell)

(define-condition haskell-compile-error (error)
  ((source :initarg :source :initform nil :reader haskell-compile-error-source)
   (line :initarg :line :initform nil :reader haskell-compile-error-line)
   (message :initarg :message :reader haskell-compile-error-message))
  (:report (lambda (c stream)
             (format stream "Haskell block~@[ at ~a~]~@[:~d~] did not compile:~%~a"
                     (haskell-compile-error-source c) (haskell-compile-error-line c)
                     (string-right-trim '(#\Newline) (haskell-compile-error-message c))))))

(define-condition haskell-error (error)
  ((message :initarg :message :reader haskell-error-message))
  (:report (lambda (c stream) (write-string (haskell-error-message c) stream))))

(defun mumble-symbol (name)
  (uiop:find-symbol* name "MUMBLE-USER"))

(defun ensure-runtime-error-hook ()
  (setf (symbol-value (mumble-symbol "*EMBED-RUNTIME-ERROR-HOOK*"))
        (lambda (message) (error 'haskell-error :message message))))


;;;; Compiling and running blocks

(defun compile-block (package text nsplices source line)
  "Compile block TEXT of Lisp package PACKAGE (a name).  :DECLARED for
imports and definitions, or the compiled expression."
  (ensure-runtime-error-hook)
  (multiple-value-bind (result message)
      (call-mumble "EMBED-BLOCK" package text nsplices (or source "<embedded>"))
    (cond ((and (symbolp result) (string= (symbol-name result) "ERROR"))
           (error 'haskell-compile-error :source source :line line :message message))
          ((symbolp result) :declared)
          (t result))))

(defun call-block (block &rest values)
  (funcall (mumble-symbol "EMBED-CALL") block values))

(defun eval-haskell (text &optional (package *package*))
  "Evaluate Haskell TEXT as a #@hs{ ... }# block without splices read in
PACKAGE: an expression's value as Lisp, or NIL after imports and
definitions."
  (let ((block (compile-block (package-name (find-package package))
                              (dedent text) 0 nil nil)))
    (if (eq block :declared) nil (call-block block))))

(defmacro %hs-block (text package source line splices)
  "Expansion of #@hs{ ... }#; SPLICES are its (PLACEHOLDER FORM)s."
  (let ((block (compile-block package text (length splices) source line)))
    (if (eq block :declared)
        ;; also at compile time, so that later blocks in the file are
        ;; compiled knowing these imports and definitions
        `(eval-when (:compile-toplevel :load-toplevel :execute)
           (compile-block ,package ,text 0 ,source ,line)
           (values))
        `(call-block (load-time-value
                      (compile-block ,package ,text ,(length splices) ,source ,line))
                     ,@(mapcar #'second splices)))))


;;;; Search paths and options

(defun add-package-db (directory)
  "Find the modules of the packages installed in DIRECTORY (a MicroCabal
--package-db, doc/PACKAGES.md) as bin/yale-haskell --package-db does."
  (let ((dbs (mumble-symbol "*PACKAGE-DBS*")))
    (setf (symbol-value dbs)
          (append (symbol-value dbs)
                  (list (namestring (uiop:ensure-directory-pathname
                                     (merge-pathnames directory))))))))

(defun add-search-path (directory)
  "Find modules in DIRECTORY too, as bin/yale-haskell -i DIRECTORY does."
  (let ((path (mumble-symbol "*MODULE-SEARCH-PATH*")))
    (setf (symbol-value path)
          (append (symbol-value path)
                  (list (namestring (uiop:ensure-directory-pathname
                                     (merge-pathnames directory))))))))

(defun enable-extensions (&rest names)
  "Turn on language extensions (strings, as -X NAME) for the modules
compiled from now on."
  (let ((exts (mumble-symbol "*DEFAULT-LANGUAGE-EXTENSIONS*")))
    (setf (symbol-value exts) (append (symbol-value exts) names))))


(defun use-language (language)
  "Compile the blocks from now on in LANGUAGE, as bin/yale-haskell's flags
do: :HASKELL98 (the default), :HASKELL2010, or :GHC2021 or :GHC2024 (GHC
base's Prelude, and that language's extensions).  Hackage packages
generally need :GHC2021.  Each package's blocks start again: its imports
and definitions are forgotten."
  (flet ((set-mumble (name value) (setf (symbol-value (mumble-symbol name)) value)))
    (set-mumble "*HASKELL2010?*" (eq language :haskell2010))
    (set-mumble "*MODERN-PRELUDE?*" (and (member language '(:ghc2021 :ghc2024)) t))
    (set-mumble "*DEFAULT-LANGUAGE-EXTENSIONS*"
                (case language
                  (:ghc2021 (list "GHC2021"))
                  (:ghc2024 (list "GHC2024"))
                  ((:haskell98 :haskell2010) '())
                  (t (error "Unknown language ~s" language))))
    (clrhash (symbol-value (mumble-symbol "*EMBED-CONTEXTS*")))
    language))


;;;; The reader

(defparameter *splice-placeholder-prefix* "cl_hs_splice_")

(defun haskell-symbol-char-p (c)
  (and (characterp c) (find c "!#$%&*+./<=>?@\\^|-~:")))

(defun haskell-ident-char-p (c)
  (and (characterp c) (or (alphanumericp c) (char= c #\_) (char= c #\'))))

(defun splice-token-char-p (c)
  "Characters of the Lisp symbol named by a $name splice."
  (and (characterp c) (or (alphanumericp c) (find c "-_*%!?"))))

(defun read-splice (stream)
  "The Lisp form of a splice whose $ has been read, as a list of it, or
NIL when the $ does not start one."
  (let ((next (peek-char nil stream nil :eof)))
    (cond ((eql next #\() (list (read stream t nil t)))
          ;; (and *special* variables)
          ((and (characterp next) (or (alpha-char-p next) (char= next #\*)))
           (let ((token (with-output-to-string (out)
                          (loop for c = (peek-char nil stream nil :eof)
                                while (splice-token-char-p c)
                                do (write-char (read-char stream) out)))))
             (list (let ((*read-eval* nil)) (read-from-string token)))))
          (t nil))))

(defun read-block-text (stream)
  "The Haskell text of a block up to its closing }#, with splices replaced
by placeholders, and the list of (PLACEHOLDER FORM).  Strings, character
literals and comments are copied as they are, so }# or $ in them neither
ends the block nor starts a splice."
  (let ((splices nil)
        (previous nil))
    (labels ((next ()
               (let ((c (read-char stream nil :eof)))
                 (when (eq c :eof)
                   (error 'simple-reader-error :stream stream
                          :format-control "Unterminated Haskell block: no closing }#"
                          :format-arguments nil))
                 c))
             (peek () (peek-char nil stream nil :eof)))
      (values
       (with-output-to-string (out)
         (loop
           (let ((c (next)))
             (cond
               ((and (char= c #\}) (eql (peek) #\#))
                (read-char stream)
                (return))
               ;; a string
               ((char= c #\")
                (write-char c out)
                (loop for d = (next)
                      do (write-char d out)
                         (cond ((char= d #\\) (write-char (next) out))
                               ((char= d #\") (return)))))
               ;; a character literal ('a', '\n'), not a prime (x')
               ((and (char= c #\') (not (haskell-ident-char-p previous)))
                (write-char c out)
                (let ((d (next)))
                  (write-char d out)
                  (cond ((char= d #\\)
                         (loop for e = (next)
                               do (write-char e out)
                               until (char= e #\')))
                        ((eql (peek) #\')
                         (write-char (read-char stream) out)))
                  (setf c d)))
               ;; a nested comment {- ... -}
               ((and (char= c #\{) (eql (peek) #\-))
                (write-char c out)
                (write-char (read-char stream) out)
                (let ((depth 1))
                  (loop while (plusp depth)
                        do (let ((d (next)))
                             (write-char d out)
                             (cond ((and (char= d #\{) (eql (peek) #\-))
                                    (write-char (read-char stream) out)
                                    (incf depth))
                                   ((and (char= d #\-) (eql (peek) #\}))
                                    (write-char (read-char stream) out)
                                    (decf depth)))))))
               ;; a line comment: two or more dashes, not part of an operator
               ((and (char= c #\-) (eql (peek) #\-)
                     (not (haskell-symbol-char-p previous)))
                (let ((dashes (with-output-to-string (d)
                                (write-char c d)
                                (loop while (eql (peek) #\-)
                                      do (write-char (read-char stream) d)))))
                  (write-string dashes out)
                  (unless (haskell-symbol-char-p (peek))
                    (loop for d = (peek)
                          until (or (eq d :eof) (char= d #\Newline))
                          do (write-char (read-char stream) out)))))
               ;; a splice: $name or $(form), not an operator's $ (<$>, $!)
               ((and (char= c #\$) (not (haskell-symbol-char-p previous)))
                (let ((form (read-splice stream)))
                  (if form
                      (let ((placeholder (format nil "~a~d" *splice-placeholder-prefix*
                                                 (length splices))))
                        (push (list placeholder (first form)) splices)
                        (write-string placeholder out)
                        (setf c #\Space))
                      (write-char c out))))
               (t (write-char c out)))
             (setf previous c))))
       (reverse splices)))))

(defun dedent (text)
  "TEXT with the indentation its lines share removed, so that a block's
top-level declarations start in column 0.  A first line with text (after
#@hs{ ) is taken to be as indented as the rest."
  (let* ((lines (uiop:split-string text :separator '(#\Newline)))
         (first-blank (every (lambda (c) (member c '(#\Space #\Tab #\Return)))
                             (first lines)))
         (rest (if first-blank (rest lines) lines))
         (indent (loop for l in (if first-blank rest (rest lines))
                       for i = (position-if-not (lambda (c) (member c '(#\Space #\Tab #\Return))) l)
                       when i minimize i)))
    (unless first-blank
      (setf rest (cons (string-left-trim '(#\Space #\Tab) (first rest)) (rest rest))))
    (format nil "~{~a~^~%~}"
            (loop for l in rest
                  for n from 0
                  collect (cond ((and (zerop n) (not first-blank)) l)
                                ((and indent (>= (length l) indent)) (subseq l indent))
                                (t (string-left-trim '(#\Space #\Tab) l)))))))

(defun block-source-location (stream)
  "The file name and line of STREAM's position, if it reads a file."
  (let ((pathname (ignore-errors (and (typep stream 'file-stream) (pathname stream))))
        (position (ignore-errors (file-position stream))))
    (if (and pathname position)
        (values (namestring pathname)
                (ignore-errors
                 (with-open-file (in pathname :element-type '(unsigned-byte 8))
                   (1+ (loop repeat position
                             count (eql (read-byte in nil 0) 10))))))
        (values nil nil))))

(defvar *previous-at-reader* nil
  "The #@ reader enable-haskell-syntax replaced, for other languages'
blocks (cl-sml's #@sml{ ... }#).")

(defun read-at-block (stream char arg)
  "Reader for #@hs{ HASKELL }# (or #@haskell{ ... }#)."
  (let ((language (with-output-to-string (out)
                    (loop for c = (read-char stream t nil t)
                          until (char= c #\{)
                          do (write-char c out)))))
    (cond ((member language '("hs" "haskell") :test #'string-equal)
           (multiple-value-bind (source line) (block-source-location stream)
             (multiple-value-bind (text splices) (read-block-text stream)
               `(%hs-block ,(dedent text) ,(package-name *package*) ,source ,line
                           ,splices))))
          (*previous-at-reader*
           (funcall *previous-at-reader*
                    (make-concatenated-stream
                     (make-string-input-stream (format nil "~a{" language))
                     stream)
                    char arg))
          (t (error 'simple-reader-error :stream stream
                    :format-control "Unknown embedded language #@~a{"
                    :format-arguments (list language))))))

(defun enable-haskell-syntax (&optional (readtable *readtable*))
  "Make READTABLE read Haskell blocks, #@hs{ ... }#, and return it.  For
the rest of a file:
  (eval-when (:compile-toplevel :load-toplevel :execute)
    (setf *readtable* (yale-haskell:enable-haskell-syntax (copy-readtable))))"
  (let ((old (get-dispatch-macro-character #\# #\@ readtable)))
    (unless (or (null old) (eq old #'read-at-block))
      (setf *previous-at-reader* old)))
  (set-dispatch-macro-character #\# #\@ #'read-at-block readtable)
  readtable)
