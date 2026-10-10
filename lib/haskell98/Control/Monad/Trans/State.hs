-- Control.Monad.Trans.State (transformers): the lazy state monad.
module Control.Monad.Trans.State (
    StateT(StateT, runStateT), State, runState, evalState, execState,
    mapState, withState, evalStateT, execStateT, mapStateT, withStateT,
    state, get, put, modify, modify', gets
  ) where

import Control.Monad.Trans.State.Lazy
