;;; mumble-user.lisp -- the package mumble programs are read in.

(in-package "MUMBLE-IMPLEMENTATION")

(unless (find-package "MUMBLE-USER")
  (make-package "MUMBLE-USER" :use '("MUMBLE")))
