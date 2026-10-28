-- NoMonoLocalBinds after TypeFamilies (which implies MonoLocalBinds): local
-- bindings generalized (JHC's thops, used at [HsType] and HsType).
{-# LANGUAGE RecordWildCards, TypeFamilies, NoMonoLocalBinds #-}
module Main where

class Monad m => MonadLoc m where
  withLoc :: Int -> m a -> m a

data Ops m = Ops { opInt :: Int -> m Int, opStr :: String -> m String }

class Trav a where
  trav :: (Applicative m, MonadLoc m) => Ops m -> a -> m a
  appl :: (Applicative m, MonadLoc m) => Ops m -> a -> m a
  appl os x = trav os x

instance Trav Int where trav Ops { .. } x = opInt x
instance Trav Char where trav _ c = pure c
instance Trav a => Trav [a] where trav os xs = traverse (appl os) xs

data D = D [Int] Char

instance Trav D where
  trav hops@Ops { .. } x = g x where
    th y = appl hops y
    g x = withLoc 0 $ f x
    f (D is c) = D <$> th is <*> th c

newtype I a = I { runI :: a }
instance Functor I where fmap f (I a) = I (f a)
instance Applicative I where pure = I; I f <*> I a = I (f a)
instance Monad I where I a >>= k = k a
instance MonadLoc I where withLoc _ m = m

main = case runI (trav (Ops (pure . (+1)) pure) (D [1,2] 'c')) of D is c -> print (is, c)
