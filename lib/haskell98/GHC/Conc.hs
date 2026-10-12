-- GHC.Conc (base): one capability (Control.Concurrent).
module GHC.Conc (numCapabilities, getNumCapabilities, setNumCapabilities,
                 getNumProcessors, pseq, par, module Control.Concurrent) where

import Control.Concurrent

numCapabilities :: Int
numCapabilities = 1

getNumProcessors :: IO Int
getNumProcessors = return 1

pseq :: a -> b -> b
pseq = seq

par :: a -> b -> b
par _ b = b
