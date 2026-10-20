{-# LANGUAGE TypeFamilies #-}
module Main (main) where

data family MV s a
newtype instance MV s Int = MVInt [Int]

type IOV = MV ()
type STV s = MV s

size :: STV s Int -> Int
size (MVInt xs) = length xs

main :: IO ()
main = print (size (MVInt [1, 2, 3] :: IOV Int))
