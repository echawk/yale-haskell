-- Arity raising (src/compiler/backend/optimize.mumble's
-- optimize-binding-value): recursive functions that return a function
-- -- loops in State, in a Reader-like newtype, in continuation-passing
-- style -- take that function's argument too, so a step allocates no
-- closure and no thunk.  `--optimizers -arity` turns it off.
{-# LANGUAGE BangPatterns #-}
import Control.Monad.State.Strict

-- State, with >>
count :: Int -> State Int ()
count 0 = return ()
count n = modify' (+ n) >> count (n - 1)

-- State over a list
total :: [Int] -> State Int ()
total [] = return ()
total (x : xs) = modify' (+ x) >> total xs

-- a Reader-like newtype
newtype Env a = Env { runEnv :: Int -> a }

depth :: Int -> Env Int
depth 0 = Env id
depth n = let rest = depth (n - 1) in Env (\e -> runEnv rest (e + n `mod` 7))

-- continuation-passing style
sumCPS :: Int -> Int -> Int
sumCPS 0 = \acc -> acc
sumCPS n = let k = sumCPS (n - 1) in \ !acc -> k (acc + n)

main :: IO ()
main = do
  print (execState (count 3000000) 0)
  print (execState (total [1 .. 1000000]) 0)
  print (runEnv (depth 3000000) 0)
  print (sumCPS 3000000 0)
