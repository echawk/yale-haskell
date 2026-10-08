;;; profile.lisp -- profile a Haskell 98 program with sb-sprof
;;; (make profile FILE=prog.hs).  The program is compiled first, as
;;; bin/yale-haskell would (optimizers on, batch mode), and only the run
;;; of Main.main is sampled.  The flat report goes to stdout; generated
;;; functions are named |Module:name/OPT|, so it reads in Haskell terms.

(require :sb-sprof)
(load "tools/build/compiler.lisp")

(in-package :mumble-user)

;;; Read the rest of this file with mumble's #t/#f syntax.
(lisp:setq lisp:*readtable* mumble-implementation:*mumble-readtable*)

(setf *printers* '())
(setf *optimizers* *all-optimizers*)
(compile/load *prelude-unit-filename*)

(define (profile-main file)
  (setf *haskell-batch-mode* '#t)
  (set-haskell-program-args file '())
  (when (not (compile/load file))
    (error "~a did not compile" file))
  (let* ((main-mod  (table-entry *modules* '|Main|))
	 (main-var  (table-entry (module-symbol-table main-mod) '|main|)))
    (let ((bytes  (sb-ext:get-bytes-consed)))
      (sb-sprof:with-profiling (:max-samples 200000 :mode :cpu
				:sample-interval 0.001 :report :flat)
	(apply-exec main-var))
      ;; allocation does not depend on machine load, unlike time
      (lisp:format lisp:*standard-output* "~&bytes consed: ~:d~%"
		   (- (sb-ext:get-bytes-consed) bytes)))))

(profile-main (getenv "PROFILE_FILE"))
