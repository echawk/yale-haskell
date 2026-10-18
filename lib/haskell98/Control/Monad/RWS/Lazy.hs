-- Control.Monad.RWS.Lazy (mtl): the lazy RWST with the mtl classes.
module Control.Monad.RWS.Lazy (
    RWST(RWST, runRWST), RWS, rws, runRWS, evalRWS, execRWS, evalRWST,
    execRWST, mapRWST, withRWST,
    MonadReader(ask, local, reader), asks, MonadWriter(writer, tell, listen, pass),
    listens, censor, MonadState(get, put, state), modify, modify', gets,
    MonadTrans(lift), MonadIO(liftIO), module Control.Monad, module Data.Monoid,
    MonadRWS
  ) where

import Control.Monad.Trans.RWS.Lazy (RWST(RWST, runRWST), RWS, rws, runRWS,
    evalRWS, execRWS, evalRWST, execRWST, mapRWST, withRWST)
import Control.Monad.Reader.Class
import Control.Monad.RWS.Class (MonadRWS)
import Control.Monad.Writer.Class
import Control.Monad.State.Class
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Control.Monad
import Data.Monoid
