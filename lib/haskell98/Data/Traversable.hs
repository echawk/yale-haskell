-- Data.Traversable (base): the class is PreludeModern's.
module Data.Traversable (
    Traversable(traverse, sequenceA, mapM, sequence),
    for, forM, mapAccumL, mapAccumR, mapAccumM, forAccumM, fmapDefault, foldMapDefault
  ) where

import Prelude hiding (foldr, foldl, foldr1, foldl1, null, length, elem, notElem, maximum, minimum, sum, product, concat, concatMap, and, or, any, all, mapM_, sequence_, mapM, sequence)
import PreludeModern

for :: (Traversable t, Applicative f) => t a -> (a -> f b) -> f (t b)
for t f = traverse f t

forM :: (Traversable t, Monad m) => t a -> (a -> m b) -> m (t b)
forM t f = mapM f t
{-# forM :: Inline #-}

-- The state applicatives of mapAccumL and mapAccumR
newtype StateL s a = StateL (s -> (s, a))
newtype StateR s a = StateR (s -> (s, a))

runStateL :: StateL s a -> s -> (s, a)
runStateL (StateL f) = f

runStateR :: StateR s a -> s -> (s, a)
runStateR (StateR f) = f

instance Functor (StateL s) where
  fmap f (StateL k) = StateL (\s -> let (s', v) = k s in (s', f v))

instance Applicative (StateL s) where
  pure x = StateL (\s -> (s, x))
  StateL kf <*> StateL kv = StateL (\s ->
    let (s', f) = kf s
        (s'', v) = kv s'
    in (s'', f v))

instance Functor (StateR s) where
  fmap f (StateR k) = StateR (\s -> let (s', v) = k s in (s', f v))

instance Applicative (StateR s) where
  pure x = StateR (\s -> (s, x))
  StateR kf <*> StateR kv = StateR (\s ->
    let (s', v) = kv s
        (s'', f) = kf s'
    in (s'', f v))

-- The state transformer of mapAccumM (base 4.18)
newtype StateM m s a = StateM (s -> m (s, a))

runStateM :: StateM m s a -> s -> m (s, a)
runStateM (StateM f) = f

instance Monad m => Functor (StateM m s) where
  fmap f (StateM k) = StateM (\s -> k s >>= \(s', v) -> return (s', f v))

instance Monad m => Applicative (StateM m s) where
  pure x = StateM (\s -> return (s, x))
  StateM kf <*> StateM kv = StateM (\s ->
    kf s >>= \(s', f) -> kv s' >>= \(s'', v) -> return (s'', f v))

mapAccumM :: (Monad m, Traversable t) => (s -> a -> m (s, b)) -> s -> t a -> m (s, t b)
mapAccumM f s t = runStateM (traverse (\x -> StateM (\acc -> f acc x)) t) s

forAccumM :: (Monad m, Traversable t) => s -> t a -> (s -> a -> m (s, b)) -> m (s, t b)
forAccumM s t f = mapAccumM f s t

mapAccumL :: Traversable t => (a -> b -> (a, c)) -> a -> t b -> (a, t c)
mapAccumL f s t = runStateL (traverse (\x -> StateL (\acc -> f acc x)) t) s

mapAccumR :: Traversable t => (a -> b -> (a, c)) -> a -> t b -> (a, t c)
mapAccumR f s t = runStateR (traverse (\x -> StateR (\acc -> f acc x)) t) s

newtype Id a = Id a

runId :: Id a -> a
runId (Id x) = x

instance Functor Id where
  fmap f (Id x) = Id (f x)

instance Applicative Id where
  pure = Id
  Id f <*> Id x = Id (f x)

fmapDefault :: Traversable t => (a -> b) -> t a -> t b
fmapDefault f t = runId (traverse (\x -> Id (f x)) t)

newtype Const m a = Const m

getConst :: Const m a -> m
getConst (Const m) = m

instance Functor (Const m) where
  fmap _ (Const m) = Const m

instance Monoid m => Applicative (Const m) where
  pure _ = Const mempty
  Const a <*> Const b = Const (a `mappend` b)

foldMapDefault :: (Traversable t, Monoid m) => (a -> m) -> t a -> m
foldMapDefault f t = getConst (traverse (\x -> Const (f x)) t)
