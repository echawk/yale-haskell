{-# LANGUAGE CPP #-}
-- C comments in an #if (GHC's StgCmmMonad: #if 0 /* def DEBUG */).
#if 0 /* def DEBUG */
x = 1
#elif 1 // always
x = 2
#endif
main = print x
