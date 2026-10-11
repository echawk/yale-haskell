-- RankNTypes with contexts: a polymorphic argument or field that takes
-- class dictionaries.
{-# LANGUAGE RankNTypes #-}
import Data.List (sort)

-- one class, used at two types
showBoth :: (forall a. Show a => a -> String) -> Int -> Bool -> String
showBoth f n b = f n ++ " " ++ f b

-- two classes on one variable, and a superclass (Ord gives Eq)
dedupe :: (forall a. (Ord a, Show a) => [a] -> String) -> String
dedupe f = f [3, 1, 2, 1 :: Int] ++ " " ++ f "banana"

uniqShow :: (Ord a, Show a) => [a] -> String
uniqShow xs = show (nub' (sort xs))
  where nub' (x:y:r) | x == y = nub' (y:r)
        nub' (x:r) = x : nub' r
        nub' [] = []

-- two type variables, one constrained; an outer type variable
pairWith :: (forall a b. Num a => a -> b -> (a, b)) -> c -> ((Int, c), (Double, c))
pairWith f c = (f 1 c, f 2.5 c)

-- the polymorphic argument passed on to another function
twice :: (forall a. Show a => a -> String) -> String
twice f = showBoth f 7 False ++ "; " ++ showBoth f 8 True

-- a field of a data type
data Shower = Shower (forall a. Show a => a -> String)

useShower :: Shower -> String
useShower (Shower g) = g 'x' ++ g [1, 2 :: Int]

-- a record field, used through its selector
newtype Fmt = Fmt { runFmt :: forall a. Show a => a -> String }

brackets :: Fmt
brackets = Fmt (\x -> "[" ++ show x ++ "]")

-- a Num-polymorphic function given as a lambda, used at Int and Double
sumBoth :: (forall n. Num n => n -> n -> n) -> (Int, Double)
sumBoth op = (op 2 3, op 0.5 0.25)

main :: IO ()
main = do
  putStrLn (showBoth show 42 True)
  putStrLn (showBoth (\x -> "<" ++ show x ++ ">") 1 False)
  putStrLn (dedupe uniqShow)
  print (pairWith (\a b -> (a * 2, b)) "c")
  putStrLn (twice (\x -> show x ++ "!"))
  putStrLn (useShower (Shower show))
  putStrLn (runFmt brackets (1 :: Int) ++ runFmt brackets "s")
  print (sumBoth (+), sumBoth (\a b -> a * b + 1))
  -- a local function with a polymorphic argument
  let local :: (forall a. Show a => a -> String) -> String
      local g = g (Just 'q') ++ g ()
  putStrLn (local show)
