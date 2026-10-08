-- Tail calls in Haskell are tail calls in the generated Lisp
-- (doc/EVAL-APPLY-GRIN.md, invariant 4): these loops would exhaust the
-- control stack otherwise.

data Op = Inc | Dec | Twice | Skip

-- strict accumulators via seq, dispatching through a case
step :: Int -> Int -> Int
step 0 acc = acc
step n acc =
  acc `seq`
  case op n of
    Inc   -> step (n - 1) (acc + 1)
    Dec   -> step (n - 1) (acc - 1)
    Twice -> step (n - 1) (acc + 2)
    Skip  -> step (n - 1) acc

op :: Int -> Op
op n = case n `mod` 4 of
         0 -> Inc
         1 -> Dec
         2 -> Twice
         _ -> Skip

count :: Int -> Int -> Int
count n acc = if n == 0 then acc else count (n - 1) $! (acc + 1)

main :: IO ()
main = do
  print (step 4000000 0)
  print (count 4000000 0)
  mapM_ (\_ -> return ()) [1 .. 1000000 :: Int]
  putStrLn "done"
