-- The Haskell 98 Monad library (Report chapter 13).
import Monad
main :: IO ()
main = do
  r <- foldM (\a b -> return (a + b)) 0 [1..10]
  print r
  when (r > 50) (putStrLn "big")
  unless (r > 50) (putStrLn "small")
  print (liftM2 (+) (Just 1) (Just 2), join [[1],[2,3]], msum [Nothing, Just 3, Just 4])
  print (guard True :: Maybe (), (guard False :: [()]), mzero `mplus` [5])
  print =<< filterM (\x -> return (even x)) [1..10]
  xs <- zipWithM (\a b -> return (a * b)) [1,2,3] [4,5,6]
  print (xs, ap [(+1)] [10, 20], liftM5 (\a b c d e -> a+b+c+d+e) (Just 1) (Just 2) (Just 3) (Just 4) (Just 5))
  (as, bs) <- mapAndUnzipM (\x -> return (x, x * x)) [1, 2, 3]
  print (as, bs)
  zipWithM_ (\a b -> print (a, b)) "ab" [True, False]
