-- Pattern type signatures (GHC ScopedTypeVariables, without scoping):
-- (pat :: type) in function arguments, lambdas, case, do and nested.
import Control.Exception

f :: Int -> Int
f (x :: Int) = x + 1

g :: [a] -> Int
g (xs :: [b]) = length xs

pairSum :: (Int, Int) -> Int
pairSum ((a :: Int), b) = a + b

main :: IO ()
main = do
  print (f 1, g "abc", pairSum (3, 4))
  r <- (evaluate (1 `div` (0 :: Int)) >> return "no") `catch` (\ (_ :: SomeException) -> return "caught")
  putStrLn r
  let h = \(n :: Integer) -> n * 2
  print (h 21)
  case Just 'x' of
    Just (c :: Char) -> print c
    Nothing -> return ()
  (k :: Int) <- return 5
  print k
