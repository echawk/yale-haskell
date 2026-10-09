-- PreludeModern: the names GHC's base Prelude exports beyond the Haskell
-- 2010 Prelude, for yale-haskell --modern-prelude (which imports this
-- module implicitly, next to the Prelude; doc/plans/MICROCABAL.md step 2).
--
-- Differences from base, still to do (plan step 2b):
--   * Monad has no Applicative superclass: a type needs Functor,
--     Applicative and Monad instances given separately, and a Monad
--     instance must define return (base defaults it to pure).
--   * fail is MonadFail's (the Prelude's Monad fail is hidden), but a
--     refutable pattern in do still calls the Haskell 98 Monad fail.
--   * No Foldable/Traversable: length, elem, mapM_ ... are the list ones.
module PreludeModern (
    Applicative(pure, (<*>), (*>), (<*)), Alternative(empty, (<|>), some, many),
    MonadFail(fail), (<$>), (<$), (<**>), liftA, liftA2, liftA3, optional,
    Semigroup((<>)), Monoid(mempty, mappend, mconcat)
  ) where

import PreludeIO (catch)

infixl 4 <*>, <*, *>, <**>, <$>, <$
infixl 3 <|>
infixr 6 <>

class Functor f => Applicative f where
  pure  :: a -> f a
  (<*>) :: f (a -> b) -> f a -> f b
  (*>)  :: f a -> f b -> f b
  (<*)  :: f a -> f b -> f a

  a *> b = (id <$ a) <*> b
  a <* b = liftA2 const a b

liftA :: Applicative f => (a -> b) -> f a -> f b
liftA f a = pure f <*> a

liftA2 :: Applicative f => (a -> b -> c) -> f a -> f b -> f c
liftA2 f a b = fmap f a <*> b

liftA3 :: Applicative f => (a -> b -> c -> d) -> f a -> f b -> f c -> f d
liftA3 f a b c = fmap f a <*> b <*> c

(<$>) :: Functor f => (a -> b) -> f a -> f b
(<$>) = fmap

(<$) :: Functor f => a -> f b -> f a
(<$) = fmap . const

(<**>) :: Applicative f => f a -> f (a -> b) -> f b
(<**>) = liftA2 (\a f -> f a)

class Applicative f => Alternative f where
  empty :: f a
  (<|>) :: f a -> f a -> f a
  some  :: f a -> f [a]
  many  :: f a -> f [a]

  some v = (:) <$> v <*> many v
  many v = some v <|> pure []

optional :: Alternative f => f a -> f (Maybe a)
optional v = Just <$> v <|> pure Nothing

class Monad m => MonadFail m where
  fail :: String -> m a

-- Instances for the Prelude's types

instance Applicative Maybe where
  pure = Just
  Just f <*> m = fmap f m
  Nothing <*> _ = Nothing

instance Alternative Maybe where
  empty = Nothing
  Nothing <|> r = r
  l       <|> _ = l

instance MonadFail Maybe where
  fail _ = Nothing

instance Applicative [] where
  pure x = [x]
  fs <*> xs = [f x | f <- fs, x <- xs]

instance Alternative [] where
  empty = []
  (<|>) = (++)

instance MonadFail [] where
  fail _ = []

instance Applicative IO where
  pure = return
  f <*> a = f >>= \g -> a >>= \x -> return (g x)
  a *> b = a >> b

instance Alternative IO where
  empty = ioError (userError "mzero")
  a <|> b = a `catch` \_ -> b

instance MonadFail IO where
  fail s = ioError (userError s)

instance Functor (Either e) where
  fmap _ (Left e)  = Left e
  fmap f (Right a) = Right (f a)

instance Applicative (Either e) where
  pure = Right
  Left e  <*> _ = Left e
  Right f <*> r = fmap f r

instance Monad (Either e) where
  return = Right
  Left e  >>= _ = Left e
  Right a >>= k = k a

-- Functions (the reader monad), as in base.
instance Functor ((->) r) where
  fmap = (.)

instance Applicative ((->) r) where
  pure = const
  f <*> g = \x -> f x (g x)

instance Monad ((->) r) where
  return = const
  f >>= k = \x -> k (f x) x

instance Semigroup b => Semigroup (a -> b) where
  f <> g = \x -> f x <> g x

instance Monoid b => Monoid (a -> b) where
  mempty = \_ -> mempty

class Semigroup a where
  (<>) :: a -> a -> a

class Semigroup a => Monoid a where
  mempty  :: a
  mappend :: a -> a -> a
  mconcat :: [a] -> a

  mappend = (<>)
  mconcat = foldr mappend mempty

instance Semigroup [a] where
  (<>) = (++)

instance Monoid [a] where
  mempty = []

instance Semigroup Ordering where
  LT <> _ = LT
  EQ <> y = y
  GT <> _ = GT

instance Monoid Ordering where
  mempty = EQ

instance Semigroup () where
  _ <> _ = ()

instance Monoid () where
  mempty = ()

instance Semigroup a => Semigroup (Maybe a) where
  Nothing <> b       = b
  a       <> Nothing = a
  Just a  <> Just b  = Just (a <> b)

instance Semigroup a => Monoid (Maybe a) where
  mempty = Nothing
