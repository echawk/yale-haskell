-- (Name, t Type), t not known yet, may still match the instance at
-- (Name, Dom Type) (Agda's addContext . distributeF).
{-# LANGUAGE FlexibleInstances #-}
module Main where

data Dom' t e = Dom { domInfo :: t, unDom :: e } deriving Show
type Dom = Dom' Int
type Name = String
newtype KeepNames a = KeepNames a

class Functor t => Decoration t where
  distributeF :: (Functor m, Foldable m) => m (t a) -> t (m a)

instance Decoration ((,) a) where
  distributeF dp = (fst (head (foldr (:) [] dp)), fmap snd dp)

instance Functor (Dom' t) where fmap f (Dom i e) = Dom i (f e)
instance Foldable (Dom' t) where foldr f z (Dom _ e) = f e z

class AddContext a where
  addContext :: a -> [String] -> [String]

instance AddContext (Name, Dom Bool) where
  addContext (x, d) ctx = (x ++ ":" ++ show (unDom d)) : ctx
instance AddContext (KeepNames String, Dom' Int Bool) where
  addContext (KeepNames x, _) ctx = x : ctx
instance AddContext ([Name], Dom Bool) where
  addContext (xs, _) ctx = xs ++ ctx

instance AddContext (Dom (Name, Bool)) where
  addContext = addContext . distributeF

main :: IO ()
main = print (addContext (Dom 0 ("x", True) :: Dom (Name, Bool)) [])
