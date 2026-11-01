{-# LANGUAGE QuantifiedConstraints, RankNTypes, KindSignatures #-}
import Data.Kind (Type)

class (forall m. Monad m => Monad (t m)) => Trans (t :: (Type -> Type) -> Type -> Type) where
  lift' :: Monad m => m a -> t m a
  liftTwice :: Monad m => m a -> t m (a, a)
  liftTwice m = do { a <- lift' m; b <- lift' m; return (a, b) }

newtype StT s m a = StT { runStT :: s -> m (a, s) }
instance Monad m => Functor (StT s m) where fmap f m = m >>= return . f
instance Monad m => Applicative (StT s m) where
  pure a = StT (\s -> return (a, s))
  mf <*> mx = mf >>= \f -> fmap f mx
instance Monad m => Monad (StT s m) where
  StT m >>= k = StT (\s -> m s >>= \(a, s') -> runStT (k a) s')
instance Trans (StT s) where
  lift' m = StT (\s -> m >>= \a -> return (a, s))

tick :: Monad m => StT Int m ()
tick = StT (\s -> return ((), s + 1))

prog :: (Trans t, Monad (t IO)) => t IO Int
prog = do { (a, b) <- liftTwice (return 20); return (a + b + 2) }

count :: Trans t => t Maybe Int
count = lift' (Just 7) >>= \x -> return (x * 6)

main = do
  r <- runStT (tick >> prog >>= \x -> tick >> return x) 0
  print r
  print (fmap fst (runStT count 'c'))
