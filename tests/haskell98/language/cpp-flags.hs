-- --cpp (from cpp-flags.flags) and -D: a file without the pragma.
#ifdef GREETING
main = putStrLn GREETING
#else
main = putStrLn "no GREETING"
#endif
