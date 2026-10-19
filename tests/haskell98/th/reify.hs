{-# LANGUAGE TemplateHaskell #-}
-- reify of this module's types (from their declarations) and of imported
-- types, constructors and variables (milestone 4).
import ReifyGen
data Color = Red | Green | Blue deriving Show
data P a = P { px :: Int, py :: Maybe a }
newtype Age = Age Int
main :: IO ()
main = do
  print $(conNames ''Color)
  print $(conNames ''Maybe)
  print $(conNames ''Age)
  putStrLn $(describe ''P)
  putStrLn $(describe ''Either)
  putStrLn $(describe 'Just)
  putStrLn $(describe 'map)
