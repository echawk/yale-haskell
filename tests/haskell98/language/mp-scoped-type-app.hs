{-# LANGUAGE DataKinds, KindSignatures, MultiParamTypeClasses, FunctionalDependencies,
             FlexibleInstances, FlexibleContexts, UndecidableInstances,
             ScopedTypeVariables, TypeApplications, AllowAmbiguousTypes #-}
-- Multi-parameter instances: the head's type variables scope over the
-- methods (also when named like the class's), type applications to
-- their methods, and methods whose type mentions no class variable.
data Nat = Z | S Nat
data P (n :: Nat) = P

class Count (n :: Nat) where
  count :: P n -> Int
instance Count 'Z where
  count _ = 0
instance Count n => Count ('S n) where
  count _ = 1 + count (P :: P n)

class Get n l r | n l -> r where
  get :: P n -> l -> r
instance Get 'Z (a, b) a where
  get _ (a, _) = a
instance Get n b r => Get ('S n) (a, b) r where
  get _ (_, b) = get (P :: P n) b

class At (n :: Nat) l r | n l -> r where
  at :: l -> r
instance At 'Z (a, b) a where
  at (a, _) = a
instance At n b r => At ('S n) (a, b) r where
  at (_, b) = at @n @b b

atFn :: forall n b r. At n b r => b -> r
atFn = at @n @b

class Name a b where
  name :: String
instance Name Int Bool where name = "Int Bool"
instance Name Bool Int where name = "Bool Int"

main :: IO ()
main = do
  print (count (P :: P ('S ('S 'Z))))
  putStrLn (get (P :: P ('S 'Z)) (1 :: Int, ("x", True)))
  putStrLn (at @('S 'Z) (1 :: Int, ("y", True)))
  print (atFn @'Z (2 :: Int, True))
  putStrLn (name @Int @Bool)
  putStrLn (name @Bool @Int)
