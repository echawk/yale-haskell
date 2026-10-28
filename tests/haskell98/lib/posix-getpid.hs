-- System.Posix.Internals' c_getpid (GHC's SysTools).
import System.Posix.Internals (c_getpid)
main = c_getpid >>= \p -> print (p > 0)
