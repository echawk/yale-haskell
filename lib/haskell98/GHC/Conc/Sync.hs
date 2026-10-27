-- GHC.Conc.Sync (base): GHC.Conc's threads and STM.
module GHC.Conc.Sync (module GHC.Conc, ThreadId(..), myThreadId) where

import GHC.Conc
import ConcurrentBase (ThreadId(..), myThreadId)
