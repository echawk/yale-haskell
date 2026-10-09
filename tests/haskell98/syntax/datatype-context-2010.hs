-- Datatype contexts are not Haskell 2010.
data Eq a => Set a = Set [a]
main :: IO ()
main = case Set [1,2,3::Int] of Set xs -> print xs
