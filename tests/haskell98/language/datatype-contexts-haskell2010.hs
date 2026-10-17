{-# LANGUAGE Haskell2010, CPP #-}
-- GHC's Haskell2010 language includes DatatypeContexts (alex's RangedSet),
-- and GHC's MachDeps.h has a stand-in ($HASKELL_LIBRARY/include).
#include "MachDeps.h"
newtype Ord v => RSet v = RSet [v] deriving Show

wordBits :: Int
wordBits = WORD_SIZE_IN_BITS

main :: IO ()
main = print (RSet "ab") >> print wordBits
