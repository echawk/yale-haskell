-- Control.Monad.State.Lazy (mtl)
module Control.Monad.State.Lazy (
    MonadState(get, put, state), modify, modify', gets,
    StateT(StateT, runStateT), State, runState, evalState, execState,
    mapState, withState, evalStateT, execStateT, mapStateT, withStateT,
    MonadTrans(lift), MonadIO(liftIO), module Control.Monad,
    -- (mtl 2.2 re-exported it: JHC's MonadFix from Control.Monad.RWS)
    module Control.Monad.Fix
  ) where

import Control.Monad.State.Class
import Control.Monad.Trans.State.Lazy (StateT(StateT, runStateT), State,
    runState, evalState, execState, mapState, withState, evalStateT,
    execStateT, mapStateT, withStateT)
import Control.Monad.Trans.Class
import Control.Monad.IO.Class
import Control.Monad
import Control.Monad.Fix
