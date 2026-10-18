{-# LANGUAGE RankNTypes, TypeOperators #-}
-- A synonym for a polytype as an argument's type: (p :-> q) -> ...
type p :-> q = forall a b. p a b -> q a b
newtype Flip p a b = Flip (p b a)
swapF :: (,) :-> Flip (,)
swapF (a, b) = Flip (b, a)
applyNat :: (p :-> q) -> p Int Char -> q Int Char
applyNat f x = f x
unF :: Flip p a b -> p b a
unF (Flip x) = x
main :: IO ()
main = print (unF (applyNat swapF (1, 'c')))
