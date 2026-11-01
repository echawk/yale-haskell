{-# LANGUAGE TypeFamilies #-}
module Main where
data family Vec a
class U a
data instance Vec Bool = VB Int
instance U Bool
instance U a => Eq (Vec a) where
  _ == _ = True
newtype P = P { unP :: Vec Bool } deriving (Eq)
main :: IO ()
main = print (P (VB 1) == P (VB 2))
