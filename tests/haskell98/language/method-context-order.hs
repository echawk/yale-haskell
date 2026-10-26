-- An instance method's own constraints on the class's variable (Eq k,
-- Show k, Agda's MemoisedCPS memoiseIfPrinting) keep their order, the
-- class method's.
{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
class Monad p => PC p k | p -> k where
  memo :: (Eq k, Show k) => k -> p r -> p r
newtype PW k a = PW (Maybe a)
instance Functor (PW k) where fmap f (PW m) = PW (fmap f m)
instance Applicative (PW k) where
  pure = PW . Just
  PW f <*> PW x = PW (f <*> x)
instance Monad (PW k) where
  PW m >>= f = PW (m >>= \x -> case f x of PW y -> y)
instance PC (PW k) k where
  memo key p = if key == key then p else p
main = case memo "k" (PW (Just 'x') :: PW String Char) of PW v -> print v
