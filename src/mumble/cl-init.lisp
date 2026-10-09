;;; cl-init.lisp -- initialize Common Lisp, loading cl-specific files.
;;;
;;; author :  Sandra Loosemore
;;; date   :  23 Oct 1991
;;;
;;; All of the files loaded here are assumed to be regular Common Lisp
;;; files.

(in-package "MUMBLE-IMPLEMENTATION")


;;; Turn off bogus warnings and messages!!!

;;; Lucid complains if files don't start with IN-PACKAGE.
#+lucid
(setq lcl:*warn-if-no-in-package* '())


;;; CMU CL prints too many compiler progress messages.
#+(or cmu sbcl ecl abcl)
(progn
  (setq *compile-print* '())
  (setq *load-verbose* t)
  )


;;; AKCL complains if any package operations appear at top-level
;;; after any other code.
;;; Also prints useless notes about when it does tail recursion elimination.
#+akcl
(progn
  (setq compiler:*suppress-compiler-notes* t)
  (setq compiler:*compile-verbose* t)
  (setq *load-verbose* t)
  (setq compiler::*compile-ordinaries* t)
  (si:putprop 'make-package nil 'compiler::package-operation)
  (si:putprop 'shadow nil 'compiler::package-operation)
  (si:putprop 'shadowing-import nil 'compiler::package-operation)
  (si:putprop 'export nil 'compiler::package-operation)
  (si:putprop 'unexport nil 'compiler::package-operation)
  (si:putprop 'use-package nil 'compiler::package-operation)
  (si:putprop 'unuse-package nil 'compiler::package-operation)
  (si:putprop 'import nil 'compiler::package-operation)
  (si:putprop 'provide nil 'compiler::package-operation)
  (si:putprop 'require nil 'compiler::package-operation)
  )


;;; Allegro also issues too many messages.
;;; ***We really ought to rename the defstructs that give the package
;;; locked errors....

#+allegro
(progn
  (setf *compile-print* nil)
  (setf compiler:*cltl1-compile-file-toplevel-compatibility-p* nil)
  (setq excl:*enable-package-locked-errors* nil)
  (setf excl:*load-source-file-info* nil)
  (setf excl:*record-source-file-info* nil)
  (setf excl:*load-xref-info* nil)
  (setf excl:*record-source-file-info* nil)
  )


;;; Harlequin Lispworks prints too many messages too.

#+lispworks
(progn
  (setf *compile-print* nil)
  (setf *load-print* nil)
  (lw:toggle-source-debugging nil)
  )


;;; Load up definitions

;;; cl-config is plain definitions, so it is loaded from source.
(load (concatenate 'string "src/mumble/cl-config" ".lisp"))




;;; Note that this assumes that the current directory is $Y2.
;;; Environment variables in pathnames may not be supported by the
;;; host Lisp.

#-mcl (progn
        (defvar *support-directory* "src/mumble/")
        (defvar *support-binary-directory*
          (concatenate 'string
                       "build/"
                       *lisp-implementation-name*
                       "/"
                       *support-directory*)))

(defun load-compiled-cl-file (filename)
  (let ((source-file (concatenate 'string
				  *support-directory*
				  filename
				  *lisp-source-file-type*))
	(binary-file (concatenate 'string
				  *support-binary-directory*
				  filename
				  *lisp-binary-file-type*)))
    (if (or (not (probe-file binary-file))
	    (< (file-write-date binary-file) (file-write-date source-file)))
	(compile-file source-file
		      :output-file (ensure-directories-exist
				     (merge-pathnames binary-file))))
    (load binary-file)))


;;; ABCL's fasls look up MUMBLE:FOO when they are loaded, before the
;;; file's own export forms have run, so the exports are recorded when
;;; the support files are first compiled and replayed before loading.

#+abcl
(defvar *mumble-exports-file*
  (concatenate 'string *support-binary-directory* "mumble-exports.lisp"))

;;; Do NOT change the load order of these files.

(load-compiled-cl-file "cl-setup")
#+abcl
(when (probe-file *mumble-exports-file*)
  (load *mumble-exports-file*))
(load-compiled-cl-file "cl-support")
(load-compiled-cl-file "cl-definitions")
(load-compiled-cl-file "cl-types")
(load-compiled-cl-file "cl-structs")


;;; It would be nice if at this point we could switch *package*
;;; over to the right package.  But because *package* is rebound while 
;;; this file is being loaded, it will get set back to whatever it was 
;;; anyway.  Bummer.  Well, let's at least make the package that we want 
;;; to use.

(load-compiled-cl-file "mumble-user")

#+abcl
(with-open-file (s (ensure-directories-exist *mumble-exports-file*)
                   :direction :output :if-exists :supersede)
  ;; (name home-package) for each; some are CL symbols mumble re-exports
  (let ((names '()))
    (do-external-symbols (sym "MUMBLE")
      (push (list (symbol-name sym) (package-name (symbol-package sym))) names))
    (format s "(dolist (n '~s)
  (let ((sym (intern (first n) (second n))))
    (import (list sym) \"MUMBLE\")
    (export (list sym) \"MUMBLE\")))~%"
            names)))


;;; Compile and load the rest of the system.  (The Lucid compiler is fast
;;; enough to make it practical to compile things all the time.)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *package* (find-package "MUMBLE-USER")))

(load "$Y2/src/compiler/system")
(compile-haskell)


;;; All done

(write-line "Remember to do (in-package \"MUMBLE-USER\")!")
