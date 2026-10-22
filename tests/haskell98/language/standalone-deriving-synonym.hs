{-# LANGUAGE StandaloneDeriving #-}
-- deriving instance C S, S a synonym for T t
module Main (main) where
data B e = B e [e]
type BI = B Int
deriving instance Show BI
main :: IO ()
main = print (B (1 :: Int) [2])
