-- hlist.hs without its LANGUAGE pragma: --ghc2024 (.flags) turns on
-- what it needs.
import Data.Kind (Type)

-- 1. DataKinds: Promotes Nat to the type level
data Nat = Z | S Nat

-- 2. GADTs: A list that tracks the types of its elements in its own type
data HList (ts :: [Type]) where
  HNil  :: HList '[]
  HCons :: t -> HList ts -> HList (t ': ts)

-- 3. Type Families: A type-level function to find the type at index 'n'
type family Get (n :: Nat) (ts :: [Type]) :: Type where
  Get 'Z (t ': ts) = t
  Get ('S n) (t ': ts) = Get n ts

-- 4. MultiParamTypeClasses & FunctionalDependencies:
-- Tells GHC that if it knows the index 'n' and the list 'ts',
-- it can uniquely determine the result type 'r'.
class HGet (n :: Nat) (ts :: [Type]) r | n ts -> r where
  hget :: HList ts -> r

instance HGet 'Z (t ': ts) t where
  hget (HCons x _) = x

instance HGet n ts r => HGet ('S n) (t ': ts) r where
  hget (HCons _ xs) = hget @n @ts xs

-- 5. RankNTypes: A function that can process any element of the HList
-- regardless of its type (quantifying the polymorphism inside the argument).
sumH :: (forall t. t -> Int) -> HList ts -> Int
sumH _ HNil = 0
sumH f (HCons x xs) = f x + sumH f xs

main :: IO ()
main = do
  let list = HCons (10 :: Int) (HCons "Hello" (HCons True HNil))

  -- TypeApplications: Explicitly telling GHC which index to fetch
  let val1 = hget @'Z @'[Int, String, Bool] list
  let val2 = hget @('S 'Z) @'[Int, String, Bool] list

  putStrLn $ "First: " ++ show val1     -- 10
  putStrLn $ "Second: " ++ val2         -- "Hello"
  putStrLn $ "Length: " ++ show (sumH (\_ -> 1) list) -- 3
