;;; concurrent-runtime.lisp -- Haskell threads for Control.Concurrent
;;; (lib/haskell98/ConcurrentPrims.hi): forkIO's threads are host threads
;;; (bordeaux-threads), with MVars, delays, asynchronous exceptions
;;; (throwTo, killThread) and masking, and the lock STM's transactions
;;; hold.  Plain CL in the MUMBLE-USER package, loaded into the SBCL image
;;; by yale-haskell/executable (yale-haskell.asd).
;;;
;;; Thunks.  The first forkIO turns on the thread-safe evaluation of
;;; thunks that Control.Parallel's sparks use (*parallel-active*,
;;; src/base/parallel-runtime.lisp): a thunk is claimed with a
;;; compare-and-swap, and a thread that finds one another thread is
;;; evaluating waits for it.  A forked thread records the thunks it enters
;;; (*track-blackholes*), so that one an exception interrupts is put back
;;; to unevaluated, for a waiting thread to evaluate itself.
;;;
;;; Blocking.  An MVar operation that cannot proceed, and a transaction
;;; that retries, wait on a condition variable.  The runtime counts the
;;; live Haskell threads (the main one included) and those waiting: a
;;; thread that would wait while every live thread waits is deadlocked,
;;; and gets the exception its operation was given
;;; (BlockedIndefinitelyOnMVar, BlockedIndefinitelyOnSTM), as GHC's
;;; garbage collector finds such threads.  A thread in threadDelay, or in
;;; I/O, is not waiting, so a thread it could wake is not deadlocked.
;;;
;;; Asynchronous exceptions.  throwTo queues the exception on the target
;;; and interrupts it (bt2:interrupt-thread); the interruption raises the
;;; first queued exception unless the target masks them.  The runtime's
;;; own critical sections defer interruptions (without-interrupts), and a
;;; waiting thread is woken to find the exception itself: waiting is
;;; interruptible, as in GHC, unless uninterruptibleMask is in force.

(cl:in-package "MUMBLE-USER")

(cl:defmacro without-host-interrupts (cl:&body body)
  #+sbcl `(sb-sys:without-interrupts ,@body)
  #-sbcl `(cl:progn ,@body))

;;; A Haskell thread: its number (ThreadId), host thread, exceptions
;;; thrown to it and not yet raised, masking state (0 unmasked, 1 masked
;;; interruptibly, 2 uninterruptibly), and whether it has finished.
(cl:defstruct (hthread (:constructor make-hthread (id thread)))
  id thread (pending '()) (mask 0) (done cl:nil))

(cl:defvar **conc-lock** (bt2:make-lock :name "Haskell threads"))
(cl:defvar **conc-cv** (bt2:make-condition-variable :name "MVar"))
;;; STM: transactions run one at a time, holding this lock; a retrying
;;; transaction waits on the condition variable for another one to commit
(cl:defvar **stm-lock** (bt2:make-lock :name "STM"))
(cl:defvar **stm-cv** (bt2:make-condition-variable :name "STM"))

(cl:defvar **threads**                          ; number -> hthread
  #+sbcl (cl:make-hash-table :synchronized cl:t)
  #-sbcl (cl:make-hash-table))
(cl:defvar **next-thread-id** 1)
(cl:defvar **live-threads** 1)
(cl:defvar **waiting-threads** 0)
(cl:defvar **main-hthread** cl:nil)

(cl:defmacro with-conc-lock (cl:&body body)
  `(without-host-interrupts
     (bt2:with-lock-held (**conc-lock**) ,@body)))

;;; The thread's own record: bound in each forked thread; the main thread
;;; (and any other host thread) has the main record.
(cl:defvar *current-hthread* cl:nil)

;;; (made before the first thread is forked, and may be wanted with the
;;; lock held: the table is synchronized instead)
(cl:defun current-hthread ()
  (cl:or *current-hthread*
         **main-hthread**
         (cl:let ((h (make-hthread 1 (bt2:current-thread))))
           (cl:setf (cl:gethash 1 **threads**) h
                    **main-hthread** h))))

(cl:defun activate-threads ()
  "Before the first forked thread runs: thread-safe thunk evaluation."
  (cl:unless *parallel-active*
    (cl:setf *parallel-active* cl:t)
    #+sbcl (sb-thread:barrier (:memory))))

;;; ------------------------------------------------------------------
;;; Asynchronous exceptions

;;; With the lock held: the first exception queued on H, when it may be
;;; raised now (WAITING: in an interruptible wait, where mask 1 allows it).
(cl:defun take-pending (h waiting)
  (cl:when (cl:and (hthread-pending h)
                   (cl:or (cl:eql (hthread-mask h) 0)
                          (cl:and waiting (cl:eql (hthread-mask h) 1))))
    (cl:pop (hthread-pending h))))

;;; In the target thread, at the interruption.
(cl:defun raise-pending ()
  (cl:let ((c (without-host-interrupts
                (bt2:with-lock-held (**conc-lock**)
                  (take-pending (current-hthread) cl:nil)))))
    (cl:when c (cl:error c))))

;;; primThrowTo :: Int -> Exc -> IO ()
(cl:defun prim.throw-to (id c)
  (cl:let ((self (current-hthread)))
    (cl:if (cl:eql id (hthread-id self))
           (cl:error c)
           (cl:let ((target (without-host-interrupts
                              (bt2:with-lock-held (**conc-lock**)
                                (cl:let ((h (cl:gethash id **threads**)))
                                  (cl:when (cl:and h (cl:not (hthread-done h)))
                                    (cl:setf (hthread-pending h)
                                             (cl:append (hthread-pending h) (cl:list c)))
                                    (bt2:condition-broadcast **conc-cv**)
                                    h))))))
             (cl:when target
               ;; (a thread waiting on STM is woken to find it too)
               (bt2:with-lock-held (**stm-lock**)
                 (bt2:condition-broadcast **stm-cv**))
               (cl:ignore-errors
                (bt2:interrupt-thread (hthread-thread target) #'raise-pending))))))
  0)

;;; primGetMask :: IO Int ; primSetMask :: Int -> IO ()
(cl:defun prim.get-mask () (hthread-mask (current-hthread)))
(cl:defun prim.set-mask (m)
  (cl:let ((h (current-hthread)))
    (cl:setf (hthread-mask h) m)
    (cl:when (cl:eql m 0) (raise-pending)))
  0)

;;; ------------------------------------------------------------------
;;; Threads

(cl:defun thread-finished (h)
  (without-host-interrupts
    (bt2:with-lock-held (**conc-lock**)
      (cl:setf (hthread-done h) cl:t)
      (cl:remhash (hthread-id h) **threads**)
      (cl:decf **live-threads**)
      ;; the threads still waiting may now all be deadlocked
      (bt2:condition-broadcast **conc-cv**)))
  (bt2:with-lock-held (**stm-lock**)
    (bt2:condition-broadcast **stm-cv**)))

;;; primForkThread :: IO () -> IO Int
;;; The action reports its own exceptions (Control.Concurrent's forkIO);
;;; one that escapes it (an asynchronous one, after) ends the thread.
(cl:defun prim.fork-thread (action)
  (current-hthread)
  (activate-threads)
  (cl:let* ((out cl:*standard-output*) (in cl:*standard-input*)
            (err cl:*error-output*) (term cl:*terminal-io*)
            (pkg cl:*package*) (rt cl:*readtable*)
            (h (without-host-interrupts
                 (bt2:with-lock-held (**conc-lock**)
                   (cl:let ((h (make-hthread (cl:incf **next-thread-id**) cl:nil)))
                     (cl:setf (cl:gethash (hthread-id h) **threads**) h)
                     (cl:incf **live-threads**)
                     h)))))
    ;; the new thread starts with the parent's masking state, as in GHC
    (cl:setf (hthread-mask h) (hthread-mask (current-hthread)))
    (cl:setf (hthread-thread h)
             (bt2:make-thread
              (cl:lambda ()
                (cl:let ((cl:*standard-output* out) (cl:*standard-input* in)
                         (cl:*error-output* err) (cl:*terminal-io* term)
                         (cl:*package* pkg) (cl:*readtable* rt)
                         (*current-hthread* h)
                         (*track-blackholes* cl:t)
                         (*blackhole-trail* '())
                         (*catch-runtime-errors* cl:t))
                  (cl:unwind-protect
                       (cl:handler-case (run-io-action action)
                         (cl:serious-condition ()
                           (restore-blackholes '())))
                    (thread-finished h))))
              :name (cl:format cl:nil "Haskell thread ~D" (hthread-id h))))
    (hthread-id h)))

;;; primMyThreadId :: IO Int
(cl:defun prim.my-thread-id () (hthread-id (current-hthread)))

;;; primThreadDelay :: Int -> IO ()  (microseconds)
;;; Interruptible, as a wait is (an exception thrown to the thread wakes
;;; it), but not counted as waiting: the thread will go on by itself.
(cl:defun prim.thread-delay (us)
  (cl:when (cl:> us 0)
    (cl:let* ((self (current-hthread))
              (end (cl:+ (cl:get-internal-real-time)
                         (cl:ceiling (cl:* us cl:internal-time-units-per-second) 1000000)))
              (stop (with-conc-lock
                      (cl:loop
                        (cl:let ((c (take-pending self cl:t))
                                 (left (cl:- end (cl:get-internal-real-time))))
                          (cl:when c (cl:return c))
                          (cl:when (cl:<= left 0) (cl:return cl:nil))
                          (bt2:condition-wait **conc-cv** **conc-lock**
                                              :timeout (cl:/ left cl:internal-time-units-per-second)))))))
      (cl:when stop (cl:error stop))))
  0)

;;; primYield :: IO ()
(cl:defun prim.yield () (bt2:thread-yield) 0)

;;; primThreadFinished :: Int -> IO Bool
(cl:defun prim.thread-finished (id)
  (bt2:with-lock-held (**conc-lock**)
    (cl:let ((h (cl:gethash id **threads**)))
      (cl:or (cl:null h) (hthread-done h)))))

;;; ------------------------------------------------------------------
;;; Waiting

;;; With LOCK held: wait on CV until (funcall READY) is true; NIL then.
;;; Otherwise what stopped the wait, for the caller to raise once the lock
;;; is released: an exception thrown to the thread (waiting is
;;; interruptible), or :deadlock.
(cl:defun wait-for (lock cv ready)
  (cl:let ((self (current-hthread))
           (conc? (cl:eq lock **conc-lock**)))
    (cl:macrolet ((under-conc (cl:&body body)
                    `(cl:if conc?
                            (cl:progn ,@body)
                            (bt2:with-lock-held (**conc-lock**) ,@body))))
      (under-conc (cl:incf **waiting-threads**))
      (cl:unwind-protect
           (cl:loop
             (cl:when (cl:funcall ready) (cl:return cl:nil))
             (cl:let ((stop (under-conc
                             (cl:or (take-pending self cl:t)
                                    (cl:and (cl:>= **waiting-threads** **live-threads**)
                                            :deadlock)))))
               (cl:when stop (cl:return stop)))
             (bt2:condition-wait cv lock))
        (under-conc (cl:decf **waiting-threads**))))))

;;; Raise what stopped a wait: BLOCKED (a thunk, the operation's deadlock
;;; exception; NIL for the runtime's own error) for a deadlock.
(cl:defun raise-wait-stop (stop blocked)
  (cl:cond ((cl:null stop) cl:nil)
           ((cl:eq stop :deadlock)
            (cl:if blocked (cl:error (force blocked)) (mvar-blocked)))
           (cl:t (cl:error stop))))

;;; ------------------------------------------------------------------
;;; MVars: a cell holding the value or *empty-mvar*
;;; (src/base/primops-runtime.lisp's, which GHC.Exts' MVar# shares)

(cl:defun mvar-full? (v) (cl:not (cl:eq (cl:svref v 0) *empty-mvar*)))

(cl:defun mvar-take (v blocked)
  (cl:let* ((x *empty-mvar*)
            (stop (with-conc-lock
                    (cl:or (wait-for **conc-lock** **conc-cv** (cl:lambda () (mvar-full? v)))
                           (cl:progn
                             (cl:setf x (cl:svref v 0)
                                      (cl:svref v 0) *empty-mvar*)
                             (bt2:condition-broadcast **conc-cv**)
                             cl:nil)))))
    (raise-wait-stop stop blocked)
    x))

(cl:defun mvar-read (v blocked)
  (cl:let* ((x *empty-mvar*)
            (stop (with-conc-lock
                    (cl:or (wait-for **conc-lock** **conc-cv** (cl:lambda () (mvar-full? v)))
                           (cl:progn (cl:setf x (cl:svref v 0)) cl:nil)))))
    (raise-wait-stop stop blocked)
    x))

(cl:defun mvar-put (v x blocked)
  (raise-wait-stop
   (with-conc-lock
     (cl:or (wait-for **conc-lock** **conc-cv** (cl:lambda () (cl:not (mvar-full? v))))
            (cl:progn
              (cl:setf (cl:svref v 0) x)
              (bt2:condition-broadcast **conc-cv**)
              cl:nil)))
   blocked)
  0)

;;; the value, or *empty-mvar*
(cl:defun mvar-try-take (v)
  (with-conc-lock
    (cl:let ((x (cl:svref v 0)))
      (cl:unless (cl:eq x *empty-mvar*)
        (cl:setf (cl:svref v 0) *empty-mvar*)
        (bt2:condition-broadcast **conc-cv**))
      x)))

(cl:defun mvar-try-put (v x)
  (with-conc-lock
    (cl:unless (mvar-full? v)
      (cl:setf (cl:svref v 0) x)
      (bt2:condition-broadcast **conc-cv**)
      cl:t)))

(cl:defun prim.new-mvar () (cl:vector *empty-mvar*))
(cl:defun prim.take-mvar (v blocked) (mvar-take v blocked))
(cl:defun prim.read-mvar (v blocked) (mvar-read v blocked))
(cl:defun prim.put-mvar (v x blocked) (mvar-put v x blocked))
;;; the try forms store the value in REF (a Data.IORef cell)
(cl:defun prim.try-take-mvar (v ref)
  (cl:let ((x (mvar-try-take v)))
    (cl:unless (cl:eq x *empty-mvar*)
      (cl:setf (cl:svref ref 0) x)
      cl:t)))
(cl:defun prim.try-read-mvar (v ref)
  (cl:let ((x (cl:svref v 0)))
    (cl:unless (cl:eq x *empty-mvar*)
      (cl:setf (cl:svref ref 0) x)
      cl:t)))
(cl:defun prim.try-put-mvar (v x) (mvar-try-put v x))
(cl:defun prim.is-empty-mvar (v) (cl:not (mvar-full? v)))

;;; ------------------------------------------------------------------
;;; STM (lib/haskell98/STMBase.hs): the transaction's lock, and waiting
;;; for another transaction to commit

;;; primSTMLock :: IO ()
(cl:defun prim.stm-lock ()
  (without-host-interrupts (bt2:acquire-lock **stm-lock**))
  0)

;;; primSTMUnlock :: Bool -> IO ()  (whether the transaction wrote)
(cl:defun prim.stm-unlock (wrote)
  (without-host-interrupts
    (cl:when wrote (bt2:condition-broadcast **stm-cv**))
    (bt2:release-lock **stm-lock**))
  0)

;;; primSTMWait :: Exc -> IO ()  (with the lock held: until a commit;
;;; the lock is still held after, also when it raises an exception)
(cl:defun prim.stm-wait (blocked)
  (cl:let ((seen cl:nil))
    (raise-wait-stop
     (without-host-interrupts
       (wait-for **stm-lock** **stm-cv**
                 ;; once woken: a transaction committed (or a thread
                 ;; ended, or an exception came: wait-for looks first)
                 (cl:lambda () (cl:prog1 seen (cl:setf seen cl:t)))))
     blocked))
  0)
