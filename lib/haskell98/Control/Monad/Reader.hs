-- Control.Monad.Reader (mtl)
module Control.Monad.Reader (
    MonadReader(ask, local, reader), asks,
    ReaderT(ReaderT, runReaderT), Reader, runReader, mapReaderT, withReaderT,
    MonadTrans(lift), MonadIO(liftIO), module Control.Monad,
    -- (mtl 2.2 re-exported it: JHC's MonadFix from Control.Monad.RWS)
    module Control.Monad.Fix
  ) where

import Control.Monad.Reader.Class
import Control.Monad.Trans.Reader (ReaderT(ReaderT, runReaderT), Reader,
    runReader, mapReaderT, withReaderT)
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Control.Monad
import Control.Monad.Fix
