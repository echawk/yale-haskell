;;; parallel-runtime.lisp -- parallel evaluation for Control.Parallel
;;; (lib/haskell98/ParallelPrims.hi): sparks evaluated by a pool of
;;; lparallel worker threads, and the thread-safe thunk evaluation they
;;; need.  Plain CL in the MUMBLE-USER package, loaded into the SBCL image
;;; by yale-haskell/executable (yale-haskell.asd).
;;;
;;; As with GHC, the number of capabilities is +RTS -N[n] (or GHCRTS),
;;; read by strip-rts-options (src/runtime/system-prims.mumble); with one,
;;; the default, par does nothing.  Otherwise the first spark starts n - 1
;;; workers (the main thread is the n-th) and sets *parallel-active*, from
;;; which point force-thunk (src/runtime/runtime-utils.mumble) calls
;;; force-thunk-parallel below.
;;;
;;; A spark is a thunk handed to the pool, as in GHC: a worker that finds
;;; it already evaluated or being evaluated drops it (the spark
;;; "fizzles"), and one whose evaluation fails puts the thunks it had
;;; claimed back to unevaluated, so the error happens again, in the thread
;;; that demands the value.  Sparks beyond *max-sparks* waiting are
;;; dropped, as GHC's spark pool overflows.
;;;
;;; Memory ordering: the writer of a result orders its stores with write
;;; barriers (above), and force-thunk-parallel reads with a read barrier.
;;; The inline fast path that reads an already evaluated thunk
;;; (force-inline, unbox) has no read barrier, so that sequential programs
;;; do not pay for one: on weakly ordered hardware (arm64) a thread could
;;; in principle load the cdr before the marker and see a claim instead of
;;; the value of a thunk that another thread has just finished.  This was
;;; not observed; a read barrier there costs about 0.3 ns per read.

(cl:in-package "MUMBLE-USER")

(cl:defparameter *max-sparks* 8192)

(sb-ext:defglobal **pending-sparks** (cl:list 0))
(sb-ext:defglobal **spark-lock** (sb-thread:make-mutex :name "spark pool"))

(cl:defun capabilities ()
  "The number of capabilities: -N's, or for -N alone one per processor."
  (cl:if (cl:eql *capabilities* 0)
         (cl:max 1 (cl:or (cl:ignore-errors
                           (cl:parse-integer
                            (uiop:run-program '("sysctl" "-n" "hw.ncpu")
                                              :output :string :ignore-error-status cl:t)
                            :junk-allowed cl:t))
                          (cl:ignore-errors
                           (cl:parse-integer
                            (uiop:run-program '("nproc") :output :string
                                                         :ignore-error-status cl:t)
                            :junk-allowed cl:t))
                          1))
         *capabilities*))

(cl:defun ensure-spark-pool ()
  "Start the workers, once; true when there are any."
  (cl:or lparallel:*kernel*
         (sb-thread:with-mutex (**spark-lock**)
           (cl:or lparallel:*kernel*
                  (cl:let ((n (capabilities)))
                    (cl:when (cl:> n 1)
                      (cl:setf *capabilities* n)
                      (cl:prog1 (cl:setf lparallel:*kernel*
                                         (lparallel:make-kernel (cl:1- n) :name "spark"))
                        (cl:setf *parallel-active* cl:t))))))))

;;; ------------------------------------------------------------------
;;; Thunks

(cl:defun force-thunk-parallel (th)
  "Evaluate thunk TH (not known to be evaluated) when other threads may
be evaluating thunks too."
  (cl:let ((spins 0))
    (cl:loop
      (cl:let ((c (cl:car th)))
        (cl:cond
          ((cl:eq c '|%thunk-evaluated%|)
           (sb-thread:barrier (:read))
           (cl:return (cl:cdr th)))
          ((cl:eq c '|%thunk-unevaluated%|)
           (cl:when (cl:eq (sb-ext:compare-and-swap (cl:car th) '|%thunk-unevaluated%|
                                                    '|%thunk-blackhole%|)
                           '|%thunk-unevaluated%|)
             (cl:return (evaluate-claimed-thunk th))))
          (cl:t
           ;; blackholed: by this thread (a loop), or by another one, or
           ;; (before parallel evaluation began) by the main thread
           (cl:let ((d (cl:cdr th)))
             (cl:when (cl:and (claim? d) (cl:eq (claim-owner d) sb-thread:*current-thread*))
               (haskell-loop-error))
             (cl:incf spins)
             (cl:if (cl:< spins 1000)
                    (sb-thread:thread-yield)
                    (cl:sleep 0.0002)))))))))

(cl:defun evaluate-claimed-thunk (th)
  (cl:let ((code (cl:cdr th)))
    (cl:setf (cl:cdr th) (make-claim sb-thread:*current-thread* code))
    (cl:let ((result
               (cl:if *track-blackholes*
                      (cl:let ((old *blackhole-trail*))
                        (cl:setf *blackhole-trail* (cl:cons th old))
                        (cl:prog1 (cl:funcall (cl:the cl:function code))
                          (cl:setf *blackhole-trail* old)))
                      (cl:funcall (cl:the cl:function code)))))
      ;; publish: the result's own fields, then the result, then the
      ;; marker, each visible before the next (arm64 reorders stores)
      (sb-thread:barrier (:write))
      (cl:setf (cl:cdr th) result)
      (sb-thread:barrier (:write))
      (cl:setf (cl:car th) '|%thunk-evaluated%|)
      result)))

;;; ------------------------------------------------------------------
;;; Sparks

(cl:defun run-spark (th)
  (sb-ext:atomic-decf (cl:car **pending-sparks**))
  ;; a spark already evaluated, or being evaluated, fizzles
  (cl:when (cl:eq (cl:car th) '|%thunk-unevaluated%|)
    (cl:let ((*track-blackholes* cl:t)
             (*blackhole-trail* '())
             ;; a Haskell error signals a condition (caught below)
             ;; instead of aborting the program
             (*catch-runtime-errors* cl:t))
      (cl:handler-case (force th)
        (cl:serious-condition ()
          (restore-blackholes '()))))))

;;; primPar :: a -> b -> b   (lazy in both: X is sparked, then Y evaluated)
(cl:defun prim.par (x y)
  (spark x)
  (force y))

(cl:defun spark (x)
  (cl:when (cl:and (cl:consp x)
                   (cl:eq (cl:car x) '|%thunk-unevaluated%|)
                   (cl:not (cl:eql *capabilities* 1))
                   (ensure-spark-pool)
                   (cl:< (cl:car **pending-sparks**) *max-sparks*))
    (sb-ext:atomic-incf (cl:car **pending-sparks**))
    (cl:let ((lparallel:*task-priority* :low))
      (lparallel:future (run-spark x)))))

;;; primNumCapabilities :: IO Int
(cl:defun prim.num-capabilities ()
  (cl:if (cl:eql *capabilities* 0) (capabilities) *capabilities*))

