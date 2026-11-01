{-# LANGUAGE DataKinds, TypeApplications #-}
import GHC.Records
data P = P { name :: String, age :: Int } deriving Show
data Q a = Q { item :: a, count :: Int }
main = do
  putStrLn (getField @"name" (P "ann" 3))
  print (getField @"age" (P "ann" 3) + 1)
  print (getField @"item" (Q 'x' 1), getField @"count" (Q 'x' 1))
