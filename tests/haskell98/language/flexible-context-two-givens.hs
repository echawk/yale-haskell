{-# LANGUAGE FlexibleContexts #-}
-- Two given constraints of one class on applications (Show (f a), Show (g a)):
-- each use gets its own dictionary
data Two f g a = Two (f a) (g a)
instance (Show (f a), Show (g a)) => Show (Two f g a) where
  showsPrec d (Two x y) = showParen (d > 10) (showString "Two " . showsPrec 11 x . showString " " . showsPrec 11 y)
main :: IO ()
main = print (Two [True] (Just False))
