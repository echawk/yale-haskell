{-# LANGUAGE TypeFamilies, ScopedTypeVariables #-}
module Main (main) where
import Data.Typeable
data family Vec a
newtype instance Vec Int = VInt [Int]

name :: Typeable a => Vec a -> String
name v = show (typeOf v)

main :: IO ()
main = putStrLn (name (VInt [1]))
