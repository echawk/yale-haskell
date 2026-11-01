-- Arity raising (backend/optimize.mumble's optimize-binding-value):
-- functions returning a lambda in every branch take its argument too;
-- one returning something else in a branch is left alone, so a shared
-- partial application keeps its work shared.
import Debug.Trace (trace)

f :: Int -> Int -> Int
f 0 = \x -> x
f n = let g = f (n - 1) in \x -> g (x + 1)

-- a branch returns a variable: not raised (the table is built once)
table :: Int -> Int
table = let t = trace "table built" (sum [1 .. 1000]) in \x -> t + x

h :: Int -> Int -> Int
h 0 = table
h n = let k = h (n - 1) in \x -> k (x * 2)

main :: IO ()
main = do
  print (f 100000 1)
  let p = h 3
  print (map p [1, 2, 3])
