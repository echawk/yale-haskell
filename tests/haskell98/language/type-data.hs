-- TypeData: type data declares constructors for types.
{-# LANGUAGE TypeData, DataKinds, KindSignatures, GADTs #-}
type data Nat = Z | S Nat
data V (n :: Nat) a where { Nil :: V Z a; Cons :: a -> V n a -> V (S n) a }
len :: V n a -> Int
len Nil = 0
len (Cons _ v) = 1 + len v
main = print (len (Cons 'a' (Cons 'b' Nil)))
