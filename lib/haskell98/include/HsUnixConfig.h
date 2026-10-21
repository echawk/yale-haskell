/* HsUnixConfig.h -- Yale Haskell's stand-in for unix's configuration
   header (unix-compat's System.PosixCompat.Files): the functions
   System.Posix here has. */

#ifndef HSUNIXCONFIG_H
#define HSUNIXCONFIG_H
#define HAVE_LCHOWN 1
#define HAVE_MKSTEMP 1
#define HAVE_READLINK 1
#define HAVE_SYMLINK 1
#endif
