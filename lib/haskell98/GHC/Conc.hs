-- GHC.Conc (base): the capabilities are +RTS -N's; par and pseq are
-- Control.Parallel's.
module GHC.Conc (numCapabilities, getNumCapabilities, setNumCapabilities,
                 getNumProcessors, pseq, par, labelThread,
                 module Control.Concurrent) where

import Control.Concurrent
import Control.Parallel (par, pseq)
import System.IO.Unsafe (unsafePerformIO)

numCapabilities :: Int
numCapabilities = unsafePerformIO getNumCapabilities

getNumProcessors :: IO Int
getNumProcessors = return 1


-- | A name for the thread in GHC's debugging output; none here.
labelThread :: ThreadId -> String -> IO ()
labelThread _ _ = return ()
