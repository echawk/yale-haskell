-- A class's instance at an application (MonadLoc m => WithLoc (m a)) used at
-- a type constructor's application with no instance of its own (JHC's Ki ()).
{-# LANGUAGE FlexibleInstances #-}
module Main where
class Monad m => MonadLoc m where withLoc' :: Int -> m a -> m a
class WithLoc a where withLoc :: Int -> a -> a
instance MonadLoc m => WithLoc (m a) where withLoc = withLoc'

newtype Ki a = Ki (Maybe a)
instance Functor Ki where fmap f (Ki m) = Ki (fmap f m)
instance Applicative Ki where pure = Ki . Just; Ki f <*> Ki a = Ki (f <*> a)
instance Monad Ki where Ki m >>= k = Ki (m >>= \a -> case k a of Ki r -> r)
instance MonadLoc Ki where withLoc' _ m = m

run :: Ki () -> Maybe ()
run (Ki m) = m

main = print (run (withLoc 3 (return ())))
