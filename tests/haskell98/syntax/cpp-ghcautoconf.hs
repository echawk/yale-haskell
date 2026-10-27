{-# LANGUAGE CPP #-}
-- GHC's ghcautoconf.h (os-string's): a little-endian target.
#include <ghcautoconf.h>
main = print
#ifdef WORDS_BIGENDIAN
  "big"
#else
  "little"
#endif
