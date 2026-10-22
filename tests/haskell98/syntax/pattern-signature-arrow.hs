{-# LANGUAGE ViewPatterns, ScopedTypeVariables #-}
module Main (main) where
applyTwice :: (Int -> Int) -> Int -> Int
applyTwice (f :: Int -> Int) x = f (f x)
len :: [a] -> Int
len (length -> n) = n
main :: IO ()
main = print (applyTwice (* 3) 2, len "abc")
