-- Signatures on tuple pattern components.
{-# LANGUAGE ScopedTypeVariables #-}
main = do
  let ( a :: Int
        , b :: String
        ) = (1, "x")
      (c :: Bool) = True
  print (a, b, c)
  case (2, 3) of (x :: Int, y) -> print (x + y)
