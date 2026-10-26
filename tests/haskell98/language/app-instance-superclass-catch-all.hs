-- A superclass of an instance at an application (IsInline (f a)), not
-- in its context but from the class's instance at applications
-- (Rangeable (f a)): commonmark's.
{-# LANGUAGE FlexibleInstances, FlexibleContexts, UndecidableInstances #-}
class Rangeable a where
  ranged :: Int -> a -> a

instance {-# OVERLAPPABLE #-} (Functor f, Rangeable a) => Rangeable (f a) where
  ranged r = fmap (ranged r)

class (Monoid a, Show a, Rangeable a) => IsInline a where
  str :: String -> a

instance {-# OVERLAPPABLE #-} (Applicative f, IsInline a, Monoid (f a), Show (f a)) => IsInline (f a) where
  str = pure . str

newtype H = H String deriving Show
instance Semigroup H where H a <> H b = H (a ++ b)
instance Monoid H where mempty = H ""
instance Rangeable H where ranged n (H s) = H (show n ++ s)
instance IsInline H where str = H

f :: IsInline a => a -> a
f x = ranged 1 x <> str "!"

main = do
  print (f (H "a"))
  print (f [H "b"])
