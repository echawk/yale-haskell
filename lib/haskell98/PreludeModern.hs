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
--   * Foldable and Traversable replace the Prelude's list functions
--     (length, elem, sum, mapM_, mapM, ...) in user modules: the implicit
--     Prelude import leaves them out (prelude-symbol-entry,
--     src/compiler/top/symbol-table.mumble).  toList, foldl' and foldr'
--     are Data.Foldable's, not the Prelude's (*not-in-ghc-prelude*).
module PreludeModern (
    Applicative(pure, (<*>), (*>), (<*)), Alternative(empty, (<|>), some, many),
    MonadFail(fail), (<$>), (<$), (<**>), liftA, liftA2, liftA3, optional,
    Semigroup((<>)), Monoid(mempty, mappend, mconcat),
    Foldable(foldMap, foldr, foldl, foldr', foldl', foldr1, foldl1, toList,
             null, length, elem, maximum, minimum, sum, product),
    Traversable(traverse, sequenceA, mapM, sequence),
    mapM_, sequence_, concat, concatMap, and, or, any, all, notElem,
    find, maximumBy, minimumBy, WrappedMonad(WrapMonad, unwrapMonad)
  ) where

import PreludeIO (catch)
import Prelude hiding (foldr, foldl, foldr1, foldl1, null, length, elem,
                       maximum, minimum, sum, product, mapM, sequence,
                       mapM_, sequence_, concat, concatMap, and, or, any,
                       all, notElem)
import qualified Prelude as L

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
  mconcat = L.foldr mappend mempty

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

instance (Semigroup a, Semigroup b) => Semigroup (a, b) where
  (a, b) <> (a', b') = (a <> a', b <> b')

instance (Monoid a, Monoid b) => Monoid (a, b) where
  mempty = (mempty, mempty)

instance Functor ((,) a) where
  fmap f (x, y) = (x, f y)

-- Foldable and Traversable (base's Data.Foldable, Data.Traversable)

infix 4 `elem`, `notElem`

class Foldable t where
  foldMap :: Monoid m => (a -> m) -> t a -> m
  foldr   :: (a -> b -> b) -> b -> t a -> b
  foldl   :: (b -> a -> b) -> b -> t a -> b
  foldr'  :: (a -> b -> b) -> b -> t a -> b
  foldl'  :: (b -> a -> b) -> b -> t a -> b
  foldr1  :: (a -> a -> a) -> t a -> a
  foldl1  :: (a -> a -> a) -> t a -> a
  toList  :: t a -> [a]
  null    :: t a -> Bool
  length  :: t a -> Int
  elem    :: Eq a => a -> t a -> Bool
  maximum :: Ord a => t a -> a
  minimum :: Ord a => t a -> a
  sum     :: Num a => t a -> a
  product :: Num a => t a -> a

  -- foldMap or foldr is defined; the rest go through the list
  foldMap f = foldr (\x m -> f x `mappend` m) mempty
  foldr f z t = appEndoF (foldMap (\x -> EndoF (f x)) t) z
  foldl f z t = L.foldl f z (toList t)
  foldr' f z t = L.foldr f z (toList t)
  foldl' f z t = strictFoldl f z (toList t)
  foldr1 f t = L.foldr1 f (toList t)
  foldl1 f t = L.foldl1 f (toList t)
  toList t = foldr (:) [] t
  null t = L.null (toList t)
  length t = strictFoldl (\n _ -> n + 1) 0 (toList t)
  elem x t = L.elem x (toList t)
  maximum t = L.maximum (toList t)
  minimum t = L.minimum (toList t)
  sum t = strictFoldl (+) 0 (toList t)
  product t = strictFoldl (*) 1 (toList t)

newtype EndoF b = EndoF (b -> b)

appEndoF :: EndoF b -> b -> b
appEndoF (EndoF f) = f

instance Semigroup (EndoF b) where
  EndoF f <> EndoF g = EndoF (\x -> f (g x))

instance Monoid (EndoF b) where
  mempty = EndoF (\x -> x)

strictFoldl :: (b -> a -> b) -> b -> [a] -> b
strictFoldl f z []     = z
strictFoldl f z (x:xs) = let z' = f z x in z' `seq` strictFoldl f z' xs

instance Foldable [] where
  -- eta-expanded, so that each is a known function of its arity
  foldMap f xs  = mconcat (L.map f xs)
  foldr f z xs  = L.foldr f z xs
  foldl f z xs  = L.foldl f z xs
  foldl' f z xs = strictFoldl f z xs
  foldr1 f xs   = L.foldr1 f xs
  foldl1 f xs   = L.foldl1 f xs
  toList xs     = xs
  null xs       = L.null xs
  length xs     = L.length xs
  elem x xs     = L.elem x xs
  maximum xs    = L.maximum xs
  minimum xs    = L.minimum xs
  sum xs        = L.sum xs
  product xs    = L.product xs
  {-# foldr :: Inline #-}
  {-# foldl :: Inline #-}
  {-# foldl' :: Inline #-}
  {-# null :: Inline #-}
  {-# length :: Inline #-}
  {-# elem :: Inline #-}
  {-# maximum :: Inline #-}
  {-# minimum :: Inline #-}
  {-# sum :: Inline #-}
  {-# product :: Inline #-}

instance Foldable Maybe where
  foldr _ z Nothing  = z
  foldr f z (Just x) = f x z
  foldMap _ Nothing  = mempty
  foldMap f (Just x) = f x
  toList Nothing  = []
  toList (Just x) = [x]
  null Nothing = True
  null _       = False
  length Nothing = 0
  length _       = 1

instance Foldable (Either a) where
  foldr _ z (Left _)  = z
  foldr f z (Right y) = f y z
  foldMap _ (Left _)  = mempty
  foldMap f (Right y) = f y
  null (Left _) = True
  null _        = False
  length (Left _) = 0
  length _        = 1

instance Foldable ((,) a) where
  foldr f z (_, y) = f y z
  foldMap f (_, y) = f y
  null _   = False
  length _ = 1

-- Monad has no Applicative superclass here, so mapM goes through this
-- Applicative for any Monad (Control.Applicative's).
newtype WrappedMonad m a = WrapMonad { unwrapMonad :: m a }

instance Monad m => Functor (WrappedMonad m) where
  fmap f (WrapMonad m) = WrapMonad (m >>= \x -> return (f x))

instance Monad m => Applicative (WrappedMonad m) where
  pure x = WrapMonad (return x)
  WrapMonad f <*> WrapMonad a = WrapMonad (f >>= \g -> a >>= \x -> return (g x))

class (Functor t, Foldable t) => Traversable t where
  traverse  :: Applicative f => (a -> f b) -> t a -> f (t b)
  sequenceA :: Applicative f => t (f a) -> f (t a)
  mapM      :: Monad m => (a -> m b) -> t a -> m (t b)
  sequence  :: Monad m => t (m a) -> m (t a)

  traverse f t = sequenceA (fmap f t)
  sequenceA t = traverse (\x -> x) t
  mapM f t = unwrapMonad (traverse (\x -> WrapMonad (f x)) t)
  sequence t = mapM (\x -> x) t

instance Traversable [] where
  traverse f xs = L.foldr (\x ys -> liftA2 (:) (f x) ys) (pure []) xs
  mapM f xs   = L.mapM f xs
  sequence xs = L.sequence xs

instance Traversable Maybe where
  traverse _ Nothing  = pure Nothing
  traverse f (Just x) = fmap Just (f x)

instance Traversable (Either a) where
  traverse _ (Left e)  = pure (Left e)
  traverse f (Right y) = fmap Right (f y)

instance Traversable ((,) a) where
  traverse f (x, y) = fmap (\y' -> (x, y')) (f y)

-- The Prelude's list functions over any Foldable
-- (inlined, so that at a known type they become the list functions)
{-# mapM_ :: Inline #-}
{-# sequence_ :: Inline #-}
{-# concat :: Inline #-}
{-# concatMap :: Inline #-}
{-# and :: Inline #-}
{-# or :: Inline #-}
{-# any :: Inline #-}
{-# all :: Inline #-}
{-# notElem :: Inline #-}

mapM_ :: (Foldable t, Monad m) => (a -> m b) -> t a -> m ()
mapM_ f t = foldr (\x k -> f x >> k) (return ()) t

sequence_ :: (Foldable t, Monad m) => t (m a) -> m ()
sequence_ t = foldr (\m k -> m >> k) (return ()) t

concat :: Foldable t => t [a] -> [a]
concat t = foldr (++) [] t

concatMap :: Foldable t => (a -> [b]) -> t a -> [b]
concatMap f t = foldr (\x ys -> f x ++ ys) [] t

and :: Foldable t => t Bool -> Bool
and t = L.and (toList t)

or :: Foldable t => t Bool -> Bool
or t = L.or (toList t)

any :: Foldable t => (a -> Bool) -> t a -> Bool
any p t = L.any p (toList t)

all :: Foldable t => (a -> Bool) -> t a -> Bool
all p t = L.all p (toList t)

notElem :: (Foldable t, Eq a) => a -> t a -> Bool
notElem x t = not (elem x t)

-- Data.Foldable's, not the Prelude's (*not-in-ghc-prelude*)

find :: Foldable t => (a -> Bool) -> t a -> Maybe a
find p t = case L.filter p (toList t) of
             (x:_) -> Just x
             []    -> Nothing

maximumBy :: Foldable t => (a -> a -> Ordering) -> t a -> a
maximumBy cmp t = L.foldl1 (\x y -> case cmp x y of { GT -> x; _ -> y }) (toList t)

minimumBy :: Foldable t => (a -> a -> Ordering) -> t a -> a
minimumBy cmp t = L.foldl1 (\x y -> case cmp x y of { GT -> y; _ -> x }) (toList t)
