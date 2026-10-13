;;; posix-runtime.lisp -- primitives for the System.Posix subset
;;; (lib/haskell98/PosixPrims.hi, System/Posix*.hs): file status, modes and
;;; times, links, file descriptors, signals.  Plain CL in the MUMBLE-USER
;;; package, over SBCL's sb-posix (on another Lisp each raises an IOError),
;;; loaded into the image like base-runtime.lisp.  Platform constants
;;; (open flags, S_IF* bits, signal numbers) come from sb-posix, not from
;;; the Haskell side.

(cl:in-package "MUMBLE-USER")

#+sbcl (cl:require :sb-posix)

(cl:defmacro with-posix-errors ((location cl:&optional path) cl:&body body)
  #+sbcl
  `(cl:handler-case (cl:progn ,@body)
     (sb-posix:syscall-error (c)
       (raise-errno-error (sb-posix:syscall-errno c) ,location ,path)))
  #-sbcl
  `(cl:progn ,(cl:first body)
	     (raise-io-error 'other ,location "not supported on this Lisp" ,path)))

;;; File status: an sb-posix stat object, read by the accessors below.

(cl:defun prim.posix-stat (path follow?)
  (with-posix-errors ("getFileStatus" path)
    (cl:if follow? (sb-posix:stat path) (sb-posix:lstat path))))

(cl:defun prim.posix-fstat (fd)
  (with-posix-errors ("getFdStatus")
    (sb-posix:fstat fd)))

(cl:defun prim.stat-mode (st) #+sbcl (sb-posix:stat-mode st) #-sbcl 0)
(cl:defun prim.stat-size (st) #+sbcl (sb-posix:stat-size st) #-sbcl 0)
(cl:defun prim.stat-mtime (st) #+sbcl (sb-posix:stat-mtime st) #-sbcl 0)
(cl:defun prim.stat-atime (st) #+sbcl (sb-posix:stat-atime st) #-sbcl 0)

;;; The file type of a mode: 0 regular, 1 directory, 2 symbolic link,
;;; 3 named pipe, 4 other.
(cl:defun prim.mode-file-type (mode)
  #+sbcl
  (cl:let ((ty (cl:logand mode sb-posix:s-ifmt)))
    (cl:cond ((cl:= ty sb-posix:s-ifreg) 0)
	     ((cl:= ty sb-posix:s-ifdir) 1)
	     ((cl:= ty sb-posix:s-iflnk) 2)
	     ((cl:= ty sb-posix:s-ififo) 3)
	     (cl:t 4)))
  #-sbcl 4)

(cl:defun prim.posix-chmod (path mode)
  (with-posix-errors ("setFileMode" path) (sb-posix:chmod path mode)) 0)

(cl:defun prim.posix-utimes (path atime mtime)
  (with-posix-errors ("setFileTimes" path) (sb-posix:utimes path atime mtime)) 0)

(cl:defun prim.posix-link (old new)
  (with-posix-errors ("createLink" new) (sb-posix:link old new)) 0)

(cl:defun prim.posix-symlink (old new)
  (with-posix-errors ("createSymbolicLink" new) (sb-posix:symlink old new)) 0)

(cl:defun prim.posix-sleep (seconds)
  (cl:sleep seconds)
  0)

;;; File descriptors.  open: the access (0 read, 1 write, 2 read-write),
;;; the creation mode (or -1: no O_CREAT) and the flags.
(cl:defun prim.posix-open (path access mode append? exclusive? noctty? nonblock? trunc?)
  (with-posix-errors ("openFd" path)
    (sb-posix:open path
		   (cl:logior (cl:case access
				(0 sb-posix:o-rdonly)
				(1 sb-posix:o-wronly)
				(cl:t sb-posix:o-rdwr))
			      (cl:if (cl:>= mode 0) sb-posix:o-creat 0)
			      (cl:if append? sb-posix:o-append 0)
			      (cl:if exclusive? sb-posix:o-excl 0)
			      (cl:if noctty? sb-posix:o-noctty 0)
			      (cl:if nonblock? sb-posix:o-nonblock 0)
			      (cl:if trunc? sb-posix:o-trunc 0))
		   (cl:max mode 0))))

(cl:defun prim.posix-close (fd)
  (with-posix-errors ("closeFd") (sb-posix:close fd)) 0)

(cl:defun prim.posix-dup2 (old new)
  (with-posix-errors ("dupTo") (sb-posix:dup2 old new)))

(cl:defun prim.posix-dup (fd)
  (with-posix-errors ("dup") (sb-posix:dup fd)))

;;; setFdOption: 0 AppendOnWrite, 1 CloseOnExec (FD_CLOEXEC is 1), 2 NonBlockingRead,
;;; 3 SynchronousWrites.
(cl:defun prim.posix-set-fd-option (fd option on?)
  (with-posix-errors ("setFdOption")
    (cl:if (cl:= option 1)
	   (cl:let ((flags (sb-posix:fcntl fd sb-posix:f-getfd)))
	     (sb-posix:fcntl fd sb-posix:f-setfd
			     (cl:if on? (cl:logior flags 1)
				    (cl:logandc2 flags 1))))
	   (cl:let ((bit (cl:case option
			   (0 sb-posix:o-append)
			   (2 sb-posix:o-nonblock)
			   (cl:t sb-posix:o-sync)))
		    (flags (sb-posix:fcntl fd sb-posix:f-getfl)))
	     (sb-posix:fcntl fd sb-posix:f-setfl
			     (cl:if on? (cl:logior flags bit) (cl:logandc2 flags bit))))))
  0)

;;; The descriptor under a Handle (System.Posix.IO.handleToFd).  A
;;; standard handle is 0, 1 or 2; a file handle has its fd-stream's.
(cl:defun prim.handle-to-fd (h)
  (cl:let ((s (haskell-handle-stream h)))
    (cl:case s
      ((stdin) 0)
      ((stdout) 1)
      ((stderr) 2)
      (cl:t
       #+sbcl (cl:if (cl:typep s 'sb-sys:fd-stream)
		     (sb-sys:fd-stream-fd s)
		     (raise-io-error 'illegal-operation "handleToFd" "not a file" ""))
       #-sbcl (raise-io-error 'illegal-operation "handleToFd" "not supported" "")))))

;;; A Handle on descriptor FD (System.Posix.IO.fdToHandle): MODE 0 read,
;;; 1 write, 2 read-write, Latin-1 (binary), named NAME.
(cl:defun prim.fd-to-handle (fd mode name)
  #+sbcl
  (cl:let ((s (sb-sys:make-fd-stream fd :input (cl:/= mode 1) :output (cl:/= mode 0)
				     :buffering :full :external-format :latin-1
				     :name name)))
    (make-haskell-handle s name (cl:/= mode 1) (cl:/= mode 0) cl:nil))
  #-sbcl (raise-io-error 'illegal-operation "fdToHandle" "not supported" name))

;;; Signals.  The number of a signal by name ("INT", ...).
(cl:defun prim.signal-number (name)
  #+sbcl
  (cl:let ((sym (cl:find-symbol (cl:concatenate 'cl:string "SIG" name) "SB-POSIX")))
    (cl:if (cl:and sym (cl:boundp sym)) (cl:symbol-value sym) 0))
  #-sbcl 0)

;;; installHandler: KIND 0 default, 1 ignore, 2 catch (ACTION, an IO (),
;;; runs when the signal arrives).
(cl:defun prim.install-signal-handler (signum kind action)
  #+sbcl
  (cl:case kind
    (0 (sb-sys:enable-interrupt signum :default))
    (1 (sb-sys:enable-interrupt signum :ignore))
    (cl:t (sb-sys:enable-interrupt
	   signum (cl:lambda (signal info context)
		    (cl:declare (cl:ignore signal info context))
		    (run-io-action action)))))
  0)

(cl:defun prim.raise-signal (signum)
  #+sbcl (sb-posix:kill (sb-posix:getpid) signum)
  0)

(cl:defun prim.get-process-id ()
  #+sbcl (sb-posix:getpid) #-sbcl 0)

;;; The terminal's canonical mode (stty icanon), as getEcho and setEcho
;;; change echo (base-runtime.lisp).
(cl:defun prim.set-cooked (on?)
  (uiop:run-program (cl:list "/bin/sh" "-c"
			     (cl:if on? "stty icanon </dev/tty" "stty -icanon </dev/tty"))
		    :ignore-error-status cl:t)
  0)
