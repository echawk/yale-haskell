-- Control.Monad.Trans.Identity (transformers): the identity transformer.
module Control.Monad.Trans.Identity (
    IdentityT(IdentityT, runIdentityT), mapIdentityT
  ) where

import Prelude hiding (foldr)
import PreludeModern
import Monad (MonadPlus(mzero, mplus))
import Control.Monad.Trans.Class
import Control.Monad.IO.Class

newtype IdentityT f a = IdentityT { runIdentityT :: f a }

mapIdentityT :: (m a -> n b) -> IdentityT m a -> IdentityT n b
mapIdentityT f = IdentityT . f . runIdentityT

instance Functor m => Functor (IdentityT m) where
  fmap f (IdentityT m) = IdentityT (fmap f m)

instance Applicative m => Applicative (IdentityT m) where
  pure = IdentityT . pure
  IdentityT f <*> IdentityT x = IdentityT (f <*> x)

instance Alternative m => Alternative (IdentityT m) where
  empty = IdentityT empty
  IdentityT m <|> IdentityT n = IdentityT (m <|> n)

instance Monad m => Monad (IdentityT m) where
  return = IdentityT . return
  IdentityT m >>= k = IdentityT (m >>= runIdentityT . k)

instance MonadFail m => MonadFail (IdentityT m) where
  fail = IdentityT . fail

instance MonadPlus m => MonadPlus (IdentityT m) where
  mzero = IdentityT mzero
  IdentityT m `mplus` IdentityT n = IdentityT (m `mplus` n)

instance Foldable f => Foldable (IdentityT f) where
  foldMap f (IdentityT t) = foldMap f t
  foldr f z (IdentityT t) = foldr f z t

instance Traversable f => Traversable (IdentityT f) where
  traverse f (IdentityT t) = IdentityT <$> traverse f t

instance MonadTrans IdentityT where
  lift = IdentityT

instance MonadIO m => MonadIO (IdentityT m) where
  liftIO = IdentityT . liftIO
