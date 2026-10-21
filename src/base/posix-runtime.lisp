;;; posix-runtime.lisp -- primitives for the System.Posix subset
;;; (lib/haskell98/PosixPrims.hi, System/Posix*.hs): file status, modes and
;;; times, links, file descriptors, signals.  Plain CL in the MUMBLE-USER
;;; package, over SBCL's sb-posix (on another Lisp each raises an IOError),
;;; loaded into the image like base-runtime.lisp.  Platform constants
;;; (open flags, S_IF* bits, signal numbers) come from sb-posix, not from
;;; the Haskell side.

(cl:in-package "MUMBLE-USER")

#+sbcl (cl:require :sb-posix)

;;; Elsewhere a stand-in SB-POSIX package exporting the names used here,
;;; so that this file reads (ECL failed on it since 59a1ecb); the bodies
;;; that call them are never run there.
#-sbcl
(cl:eval-when (:compile-toplevel :load-toplevel :execute)
  (cl:unless (cl:find-package "SB-POSIX")
    (cl:make-package "SB-POSIX" :use '()))
  (cl:export (cl:mapcar (cl:lambda (n) (cl:intern n "SB-POSIX"))
			'("CHMOD" "CLOSE" "DUP" "DUP2" "F-GETFD" "F-GETFL" "F-SETFD" "F-SETFL" "FCNTL" "FSTAT" "GETPID" "KILL" "LINK" "LSTAT" "O-APPEND" "O-CREAT" "O-EXCL" "O-NOCTTY" "O-NONBLOCK" "O-RDONLY" "O-RDWR" "O-SYNC" "O-TRUNC" "O-WRONLY" "OPEN" "S-IFDIR" "S-IFIFO" "S-IFLNK" "S-IFMT" "S-IFREG" "STAT" "STAT-ATIME" "STAT-MODE" "STAT-MTIME" "STAT-SIZE" "SYMLINK" "SYSCALL-ERRNO" "SYSCALL-ERROR" "UTIMES"
			  "STAT-DEV" "STAT-INO" "STAT-NLINK" "STAT-UID" "STAT-GID" "STAT-RDEV" "STAT-CTIME" "S-IFBLK" "S-IFCHR" "S-IFSOCK" "READLINK" "RENAME" "UNLINK" "MKFIFO" "CHOWN" "LCHOWN" "FCHOWN" "FCHMOD" "TRUNCATE" "FTRUNCATE" "UMASK" "ACCESS" "R-OK" "W-OK" "X-OK" "MKSTEMP" "TIME"))
	     "SB-POSIX"))

(cl:defmacro with-posix-errors ((location cl:&optional path) cl:&body body)
  #+sbcl
  `(cl:handler-case (cl:progn ,@body)
     (sb-posix:syscall-error (c)
       (raise-errno-error (sb-posix:syscall-errno c) ,location ,path)))
  #-sbcl
  (cl:progn
    body
    `(raise-io-error 'other ,location "not supported on this Lisp" ,path)))

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

;;; The other fields: 0 device, 1 inode, 2 link count, 3 owner, 4 group,
;;; 5 special device, 6 status change time.
(cl:defun prim.stat-field (st i)
  #+sbcl
  (cl:case i
    (0 (sb-posix:stat-dev st))
    (1 (sb-posix:stat-ino st))
    (2 (sb-posix:stat-nlink st))
    (3 (sb-posix:stat-uid st))
    (4 (sb-posix:stat-gid st))
    (5 (sb-posix:stat-rdev st))
    (cl:t (sb-posix:stat-ctime st)))
  #-sbcl 0)

;;; The file type of a mode: 0 regular, 1 directory, 2 symbolic link,
;;; 3 named pipe, 4 other, 5 block device, 6 character device, 7 socket.
(cl:defun prim.mode-file-type (mode)
  #+sbcl
  (cl:let ((ty (cl:logand mode sb-posix:s-ifmt)))
    (cl:cond ((cl:= ty sb-posix:s-ifreg) 0)
	     ((cl:= ty sb-posix:s-ifdir) 1)
	     ((cl:= ty sb-posix:s-iflnk) 2)
	     ((cl:= ty sb-posix:s-ififo) 3)
	     ((cl:= ty sb-posix:s-ifblk) 5)
	     ((cl:= ty sb-posix:s-ifchr) 6)
	     ((cl:= ty sb-posix:s-ifsock) 7)
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

(cl:defun prim.posix-readlink (path)
  (with-posix-errors ("readSymbolicLink" path) (sb-posix:readlink path)))

(cl:defun prim.posix-rename (old new)
  (with-posix-errors ("rename" old) (sb-posix:rename old new)) 0)

(cl:defun prim.posix-unlink (path)
  (with-posix-errors ("removeLink" path) (sb-posix:unlink path)) 0)

(cl:defun prim.posix-mkfifo (path mode)
  (with-posix-errors ("createNamedPipe" path) (sb-posix:mkfifo path mode)) 0)

;;; (sb-posix has no mknod)
(cl:defun prim.posix-mknod (path mode dev)
  #+sbcl
  (cl:when (cl:= (sb-alien:alien-funcall
		  (sb-alien:extern-alien "mknod"
					 (cl:function sb-alien:int sb-alien:c-string
						      sb-alien:unsigned-int sb-alien:int))
		  path mode dev)
		 -1)
    (raise-errno-error (sb-alien:get-errno) "createDevice" path))
  #-sbcl (raise-io-error 'other "createDevice" "not supported on this Lisp" path)
  0)

;;; chown, or lchown when not FOLLOW? (a symbolic link's own owner)
(cl:defun prim.posix-chown (path uid gid follow?)
  (with-posix-errors ("setOwnerAndGroup" path)
    (cl:if follow? (sb-posix:chown path uid gid) (sb-posix:lchown path uid gid)))
  0)

(cl:defun prim.posix-fchown (fd uid gid)
  (with-posix-errors ("setFdOwnerAndGroup") (sb-posix:fchown fd uid gid)) 0)

(cl:defun prim.posix-fchmod (fd mode)
  (with-posix-errors ("setFdMode") (sb-posix:fchmod fd mode)) 0)

(cl:defun prim.posix-truncate (path size)
  (with-posix-errors ("setFileSize" path) (sb-posix:truncate path size)) 0)

(cl:defun prim.posix-ftruncate (fd size)
  (with-posix-errors ("setFdSize") (sb-posix:ftruncate fd size)) 0)

(cl:defun prim.posix-umask (mask)
  #+sbcl (sb-posix:umask mask) #-sbcl 0)

;;; access(2): whether the file allows the access asked for (R, W, X).
(cl:defun prim.posix-access (path r? w? x?)
  #+sbcl
  (cl:handler-case
      (cl:progn
	(sb-posix:access path (cl:logior (cl:if r? sb-posix:r-ok 0)
					 (cl:if w? sb-posix:w-ok 0)
					 (cl:if x? sb-posix:x-ok 0)))
	cl:t)
    (sb-posix:syscall-error () cl:nil))
  #-sbcl cl:nil)

;;; pathconf(2) and fpathconf: the POSIX variables 0 LINK_MAX, 1 MAX_CANON,
;;; 2 MAX_INPUT, 3 NAME_MAX, 4 PATH_MAX, 5 PIPE_BUF, 6 CHOWN_RESTRICTED,
;;; 7 NO_TRUNC, 8 VDISABLE (_PC_ numbers are these on Linux, one more on
;;; macOS and the BSDs).
(cl:defun pathconf-name (var)
  #+linux var #-linux (cl:1+ var))

(cl:defun prim.posix-pathconf (path var)
  #+sbcl
  (cl:let ((r (sb-alien:alien-funcall
	       (sb-alien:extern-alien "pathconf"
				      (cl:function sb-alien:long sb-alien:c-string sb-alien:int))
	       path (pathconf-name var))))
    (cl:if (cl:= r -1)
	   (raise-errno-error (sb-alien:get-errno) "getPathVar" path)
	   r))
  #-sbcl (raise-io-error 'other "getPathVar" "not supported on this Lisp" path))

(cl:defun prim.posix-fpathconf (fd var)
  #+sbcl
  (cl:let ((r (sb-alien:alien-funcall
	       (sb-alien:extern-alien "fpathconf"
				      (cl:function sb-alien:long sb-alien:int sb-alien:int))
	       fd (pathconf-name var))))
    (cl:if (cl:= r -1)
	   (raise-errno-error (sb-alien:get-errno) "getFdPathVar" "")
	   r))
  #-sbcl (raise-io-error 'other "getFdPathVar" "not supported on this Lisp" ""))

;;; mkstemp(3): the descriptor and the file's name, a cons read by the
;;; two accessors.
(cl:defun prim.posix-mkstemp (template)
  (with-posix-errors ("mkstemp" template)
    (cl:multiple-value-bind (fd name) (sb-posix:mkstemp (cl:concatenate 'cl:string template "XXXXXX"))
      (cl:cons fd name))))

(cl:defun prim.mkstemp-fd (r) (cl:car r))
(cl:defun prim.mkstemp-name (r) (cl:cdr r))

;;; time(2): the seconds since the epoch.
(cl:defun prim.posix-time ()
  #+sbcl (sb-posix:time) #-sbcl (cl:- (cl:get-universal-time) 2208988800))

;;; uname(2)'s fields, from the Lisp's own: 0 the system ("Darwin"), 1 the
;;; node, 2 the release, 3 the version, 4 the machine ("arm64", "x86_64").
(cl:defun prim.posix-uname (i)
  (cl:case i
    (0 (cl:software-type))
    (1 (cl:or (cl:machine-instance) ""))
    ((2 3) (cl:or (cl:software-version) ""))
    (cl:t (cl:let ((m (cl:string-downcase (cl:machine-type))))
	    (cl:cond ((cl:string= m "x86-64") "x86_64")
		     (cl:t m))))))

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
