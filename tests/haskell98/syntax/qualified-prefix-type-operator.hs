{-# LANGUAGE GADTs #-}
module Main (main) where
import qualified Data.Type.Equality as Eq

class Cat k where
  idc :: k a a
instance Cat (Eq.:~:) where
  idc = Eq.Refl

main :: IO ()
main = print (case (idc :: (Eq.:~:) Int Int) of Eq.Refl -> "refl")
