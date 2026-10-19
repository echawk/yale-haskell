{-# LANGUAGE MagicHash, UnboxedTuples, PatternSynonyms, ViewPatterns, RankNTypes #-}
-- GHC.ST (base): ST's representation, a function of the State# token
-- (GHC.PrimOps), over Yale Haskell's ST (an IO action, Control.Monad.ST).
module GHC.ST (
    ST(ST), STRep, STret(..), runST, fixST, unsafeInterleaveST,
    unsafeDupableInterleaveST, liftST, stToIO, unsafeIOToST, unsafeSTToIO
  ) where

import GHC.PrimOps (State#, RealWorld)
import qualified GHC.IO as GIO
import Unsafe.Coerce (unsafeCoerce)
import Control.Monad.ST (ST, runST, fixST, stToIO, unsafeIOToST, unsafeSTToIO)
import System.IO.Unsafe (unsafeInterleaveIO)

type STRep s a = State# s -> (# State# s, a #)

data STret s a = STret (State# s) a

stRep :: ST s a -> STRep s a
stRep st = unsafeCoerce (GIO.unIO (unsafeSTToIO st))

fromRep :: STRep s a -> ST s a
fromRep f = unsafeIOToST (GIO.IO (unsafeCoerce f))

pattern ST :: STRep s a -> ST s a
pattern ST f <- (stRep -> f)
  where ST f = fromRep f

liftST :: ST s a -> State# s -> STret s a
liftST m s = case stRep m s of (# s', r #) -> STret s' r

unsafeInterleaveST :: ST s a -> ST s a
unsafeInterleaveST m = unsafeIOToST (unsafeInterleaveIO (unsafeSTToIO m))

unsafeDupableInterleaveST :: ST s a -> ST s a
unsafeDupableInterleaveST = unsafeInterleaveST
