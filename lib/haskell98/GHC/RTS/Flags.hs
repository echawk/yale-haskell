-- GHC.RTS.Flags (base): the runtime's settings, as GHC's defaults (Yale
-- Haskell has no +RTS options): typed-process reads the context switch
-- time.
module GHC.RTS.Flags (
    RtsTime, ConcFlags(..), getConcFlags
  ) where

import Data.Word (Word64)

-- nanoseconds
type RtsTime = Word64

data ConcFlags = ConcFlags
  { ctxtSwitchTime  :: RtsTime
  , ctxtSwitchTicks :: Int
  } deriving Show

getConcFlags :: IO ConcFlags
getConcFlags = return (ConcFlags 20000000 2)
