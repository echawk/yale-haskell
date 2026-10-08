-- let- and where-bound functions without signatures are generalised
-- and can be used at several types in the body.
module Main where
import Dialogue (stdout, appendChan, done, abort)

pairUp :: (Int, Char)
pairUp = let ident x = x in (ident 3, ident 'c')

twiceBoth :: (Int, String)
twiceBoth = (twice (+1) 5, twice ('a':) "b")
  where twice f = f . f

lengths :: (Int, Int)
lengths = (len [True, False], len "hello")
  where len []     = 0
        len (_:xs) = 1 + len xs

compose :: String
compose = let k x y = x
              s f g x = f x (g x)
          in s k k 'z' : s k (k 'q') 'w' : []

out :: String
out = unlines [ show pairUp, show twiceBoth, show lengths, compose ]

main = appendChan stdout out abort done
