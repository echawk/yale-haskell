-- TypeApplications: f @T for variables, methods and constructors.
{-# LANGUAGE TypeApplications, ScopedTypeVariables #-}
main :: IO ()
main = do
  print (read @Int "42", read @[Bool] "[True]", show @Double 1.5)
  print (map (fromIntegral @Int @Double) [1, 2, 3])
  print (maxBound @Char > 'z', minBound @Int < 0)
  print (either (const 0) (+ 1) (Right @String @Int 4))
  print (const @Int @String 7 "x")
