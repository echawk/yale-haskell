{-# LANGUAGE DeriveGeneric #-}
module Main (main) where
import GHC.Generics
newtype Biff p f g a b = Biff (p (f a) (g b)) deriving Generic1
main :: IO ()
main = case to1 (fmap (+1) (from1 (Biff ([1], Just 2)) :: Rep1 (Biff (,) [] Maybe Int) Int)) of Biff (x, y) -> print (x, y)
