{-# LANGUAGE ScopedTypeVariables #-}
main = do
  x :: Int <- return 3
  (y, z) :: (Int, Bool) <- return (4, True)
  print (x + y, z)
