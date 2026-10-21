{-# LANGUAGE GADTs #-}
data E a where
  IntE :: Int -> E Int
  Pair :: E a -> E b -> E (a, b)

eval :: E a -> a
eval e
  | IntE n <- e = n
  | Pair x y <- e = (eval x, eval y)

main :: IO ()
main = print (eval (Pair (IntE 1) (Pair (IntE 2) (IntE 3))))
