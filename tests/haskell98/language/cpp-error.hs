{-# LANGUAGE CPP #-}
-- #error ends the compilation with its message.
#if !defined(__YALE_HASKELL__)
main = print 0
#else
#error unsupported here
#endif
