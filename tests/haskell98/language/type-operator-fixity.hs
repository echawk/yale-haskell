{-# LANGUAGE TypeOperators #-}
module Main (main) where
data a :* b = a :* b deriving Show
infixr 1 :*

f :: Int :* Bool :* Char -> Char
f (_ :* _ :* c) = c

g :: Either Int Bool :* [Char] -> String
g (Right b :* s) = show b ++ s
g (Left n :* s) = show n ++ s

h :: (Int :* Bool) :* Char -> Int
h ((n :* _) :* _) = n

main :: IO ()
main = print (f (1 :* True :* 'x'), g (Right False :* "!"), h ((7 :* True) :* 'q'))
