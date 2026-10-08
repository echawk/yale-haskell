-- A class method whose type has its own context on a type variable
-- other than the class variable (Haskell 98 section 4.3.1), and a
-- method that is itself polymorphic.
module Main where
import Dialogue (stdout, appendChan, done, abort)

class Store s where
  holds  :: (Eq a) => s -> (s -> [a]) -> a -> Bool
  mapAll :: s -> (Int -> b) -> [b]

data Bag = Bag [Int]

instance Store Bag where
  holds s get x = x `elem` get s
  mapAll (Bag xs) f = map f xs

contents :: Bag -> [Int]
contents (Bag xs) = xs

names :: Bag -> [String]
names (Bag xs) = map show xs

out :: String
out = unlines [ show (holds (Bag [1, 2, 3]) contents 2, holds (Bag [1]) names "5")
              , unwords (mapAll (Bag [1, 2]) show)
              , show (sum (mapAll (Bag [1, 2, 3]) (* 2))) ]

main = appendChan stdout out abort done
