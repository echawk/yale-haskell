-- An existential type variable is rigid: it cannot be Int.
{-# LANGUAGE ExistentialQuantification #-}
data B = forall a. Show a => B a
f :: B -> Int
f (B x) = x
main = print (f (B (3::Int)))
