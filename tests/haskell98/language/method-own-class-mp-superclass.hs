-- A method constrained by its own class (Agda's assignTerm' ::
-- MonadMetaSolver m => ..), the class's superclass having a
-- multi-parameter superclass: the instance's method takes the
-- dictionaries the class method's type has, no superclass at a type
-- constructor's application more (Monad (State Int)).
{-# LANGUAGE ConstrainedClassMethods, FlexibleContexts, FlexibleInstances, MultiParamTypeClasses #-}
import Data.IORef
import Control.Monad.State
class MonadState Int m => C1 m
class (Monad m, C1 m) => MS m where
  act' :: MS m => Int -> m ()
  other :: m Int
instance C1 (State Int)
instance MS (State Int) where
  act' n = modify (+ n)
  other = return 1
act :: MS m => Int -> m ()
act n = act' n
main = print (execState (act 5 >> act' 2) 0)
