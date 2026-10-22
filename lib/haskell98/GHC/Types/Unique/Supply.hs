-- GHC.Types.Unique.Supply (the ghc package): an infinite tree of unique
-- keys, built lazily from a global counter.
module GHC.Types.Unique.Supply (
    UniqSupply, mkSplitUniqSupply, splitUniqSupply, uniqFromSupply,
    uniqsFromSupply, takeUniqFromSupply, listSplitUniqSupply
  ) where

import Data.IORef
import System.IO.Unsafe (unsafePerformIO, unsafeInterleaveIO)
import GHC.Types.Unique

data UniqSupply = MkSplitUniqSupply Unique UniqSupply UniqSupply

counter :: IORef Int
counter = unsafePerformIO (newIORef 0)
{-# NOINLINE counter #-}

mkSplitUniqSupply :: Char -> IO UniqSupply
mkSplitUniqSupply c = mk
  where
    mk = unsafeInterleaveIO $ do
      n <- atomicModifyIORef' counter (\k -> (k + 1, k + 1))
      l <- mk
      r <- mk
      return (MkSplitUniqSupply (mkUnique c n) l r)

splitUniqSupply :: UniqSupply -> (UniqSupply, UniqSupply)
splitUniqSupply (MkSplitUniqSupply _ l r) = (l, r)

listSplitUniqSupply :: UniqSupply -> [UniqSupply]
listSplitUniqSupply (MkSplitUniqSupply _ l r) = l : listSplitUniqSupply r

uniqFromSupply :: UniqSupply -> Unique
uniqFromSupply (MkSplitUniqSupply u _ _) = u

uniqsFromSupply :: UniqSupply -> [Unique]
uniqsFromSupply (MkSplitUniqSupply u _ r) = u : uniqsFromSupply r

takeUniqFromSupply :: UniqSupply -> (Unique, UniqSupply)
takeUniqFromSupply (MkSplitUniqSupply u _ r) = (u, r)
