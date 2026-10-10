-- ScopedTypeVariables: a forall's type variables in inner signatures and annotations.
{-# LANGUAGE ScopedTypeVariables #-}
import Data.List (sortBy)

parseAll :: forall a. Read a => [String] -> [a]
parseAll = map (\s -> read s :: a)

rev :: forall a. [a] -> [a]
rev [] = []
rev (x:xs) = go xs [x]
  where go :: [a] -> [a] -> [a]
        go [] acc = acc
        go (y:ys) acc = go ys (y : acc)

count :: forall a. Eq a => a -> [a] -> Int
count x = length . filter same
  where same :: a -> Bool
        same y = y == x

pairUp :: forall a b. (Show a, Show b) => a -> [b] -> [String]
pairUp a bs = [ shown b | b <- bs ]
  where shown :: b -> String
        shown b = show a ++ "/" ++ show b

h98 :: [a] -> Int
h98 xs = inner xs + inner "abc"
  where inner :: [b] -> Int
        inner = length

main :: IO ()
main = do
  print (parseAll ["1", "2", "3"] :: [Int])
  print (rev "hello", count 'l' "hello")
  mapM_ putStrLn (pairUp True [1, 2 :: Int])
  print (h98 [(), ()])
  print ((\(x :: Int) -> x + 1) 41)
