-- do notation in the Maybe monad: a Nothing anywhere short-circuits,
-- and a failed pattern match gives Nothing via fail.
module Main where

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv a b = Just (a `div` b)

calc :: Int -> Int -> Int -> Maybe Int
calc a b c = do
  x <- safeDiv a b
  y <- safeDiv x c
  return (x + y)

firstOf :: [Int] -> Maybe Int
firstOf xs = do
  (y : _) <- Just xs
  return y

showM :: Maybe Int -> String
showM Nothing  = "Nothing"
showM (Just n) = "Just " ++ show n

out :: String
out = unlines (map showM [calc 100 5 2, calc 1 0 2, calc 10 1 0, firstOf [7, 8], firstOf []])

main = appendChan stdout out abort done
