{-# LANGUAGE NoMonoLocalBinds, FlexibleContexts, UndecidableInstances #-}
-- A local binding whose multi-parameter constraint an instance matches
-- without deciding (JHC's localJumps: FreeVars [t] b by FreeVars [a] b):
-- kept monomorphic, the use deciding it.
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module Main where
import qualified Data.Set as Set

class Monoid b => FreeVars a b where
  freeVars :: a -> b

data E = V Int | A E E
instance FreeVars E (Set.Set Int) where
  freeVars (V i) = Set.singleton i
  freeVars (A a b) = freeVars a `mappend` freeVars b
instance FreeVars E [Int] where
  freeVars e = Set.toList (freeVars e)

scope xs = let fvs = freeVars xs in (sum (Set.toList fvs) :: Int, length (freeVars xs :: [Int]))

main = print (scope (A (V 1) (V 2)), body (A (V 1) (V 2)), body2 [V 3, V 4])

scope2 xs k = let fvs = freeVars xs in k (sum (Set.toList fvs) :: Int)

body :: E -> Int
body e@(A a b) = scope2 e (\n -> n + body a)
body (V i) = scope2 [i] (\n -> n)

instance {-# OVERLAPPING #-} FreeVars [Int] (Set.Set Int) where
  freeVars = Set.fromList

body2 :: [E] -> Int
body2 es = let jumps xs k = scope2 (map fst xs) k in jumps (zip es es) (\n -> n * 10)

instance FreeVars a b => FreeVars [a] b where
  freeVars = mconcat . map freeVars
