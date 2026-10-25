-- Syntax from the Hackage survey: an implicit parameter as an argument
-- and ?callStack under HasCallStack (safe-exceptions), hiding () (base-
-- compat), a class's default type instance, parsed (barbies; the
-- default is not used yet), a bang pattern
-- beginning a case alternative (unicode-data).
{-# LANGUAGE ImplicitParams, BangPatterns, TypeFamilies #-}
import Prelude hiding ()
import GHC.Stack
class C a where
  type family R a
  type instance R a = Int
  r :: a -> R a
instance C Bool where
  type R Bool = Int
  r _ = 3
f :: (?x :: Int) => Int -> (Int, Int)
f y = (y, max 3 ?x)
stack :: HasCallStack => String
stack = show ?callStack
g :: Int -> Int
g d = case d of
  !x -> x + 1
main :: IO ()
main = do
  let ?x = 5 in print (f 1)
  putStrLn stack
  print (r True, g 1)
