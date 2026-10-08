-- Higher-kinded type parameters without any classes: kind inference
-- must find f :: * -> * in App and Fix (Haskell 98 section 4.6).
module Main where
import Dialogue (stdout, appendChan, done, abort)

data App f a  = App (f a)
data Fix f    = In (f (Fix f))
data ListF a r = NilF | ConsF a r

unApp :: App f a -> f a
unApp (App x) = x

fromList :: [a] -> Fix (ListF a)
fromList []       = In NilF
fromList (x : xs) = In (ConsF x (fromList xs))

total :: Fix (ListF Int) -> Int
total (In NilF)        = 0
total (In (ConsF x r)) = x + total r

out :: String
out = unlines [ show (length (unApp (App "abc")))
              , show (total (fromList [1 .. 10])) ]

main = appendChan stdout out abort done
