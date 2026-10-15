-- Arrows' proc notation: -<, -<<, do with binds, let and commands, if.
{-# LANGUAGE Arrows #-}
import Control.Arrow
addA :: Arrow a => a b Int -> a b Int -> a b Int
addA f g = proc x -> do
  y <- f -< x
  z <- g -< x
  returnA -< y + z

classify :: ArrowChoice a => a Int String
classify = proc n -> do
  let m = n * 2
      k = m + 1
  if even n then returnA -< "even " ++ show (m, k) else do
    s <- arr show -< n
    returnA -< "odd " ++ s

applyA :: ArrowApply a => a (a Int Int, Int) Int
applyA = proc (f, x) -> f -<< x + 1

counter :: Kleisli IO Int Int
counter = proc n -> do
  Kleisli print -< n
  (_, b) <- arr (\v -> (v, v * 3)) -< n
  returnA -< b

main = do
  print (addA (+ 1) (* 2) 5)
  mapM_ (putStrLn . classify) [3, 4]
  print (applyA ((* 10), 4))
  runKleisli counter 7 >>= print
