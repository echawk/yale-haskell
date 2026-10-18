-- Control.Monad.Signatures (transformers): the types of operations that
-- the transformers' lift* functions lift.
module Control.Monad.Signatures (CallCC, Catch, Listen, Pass) where

-- callCC
type CallCC m a b = ((a -> m b) -> m a) -> m a

-- catchE and the like
type Catch e m a = m a -> (e -> m a) -> m a

-- listen
type Listen w m a = m a -> m (a, w)

-- pass
type Pass w m a = m (a, w -> w) -> m a
