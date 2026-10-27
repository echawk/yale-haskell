-- An INLINE method that calls itself at its own instance through
-- the instance's dictionary applied to its context's (free's FreeT
-- f m <*>): a loop breaker, not unrolled forever.
module Main where

data FreeF f a b = Pure a | Free (f b)
newtype FreeT f m a = FreeT { runFreeT :: m (FreeF f a (FreeT f m a)) }

instance (Functor f, Functor m) => Functor (FreeT f m) where
  fmap f (FreeT m) = FreeT (fmap f' m) where
    f' (Pure a) = Pure (f a)
    f' (Free as) = Free (fmap (fmap f) as)

instance (Applicative f, Applicative m) => Applicative (FreeT f m) where
  pure a = FreeT (pure (Pure a))
  {-# INLINE pure #-}
  FreeT f <*> FreeT a = FreeT $ g <$> f <*> a where
    g (Pure f') (Pure a') = Pure (f' a')
    g (Pure f') (Free as) = Free $ fmap f' <$> as
    g (Free fs) (Pure a') = Free $ fmap ($ a') <$> fs
    g (Free fs) (Free as) = Free $ (<*>) <$> fs <*> as
  {-# INLINE (<*>) #-}

main = do
  Pure x <- runFreeT (pure (+1) <*> (pure 2 :: FreeT Maybe IO Int))
  print x
