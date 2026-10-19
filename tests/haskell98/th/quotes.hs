{-# LANGUAGE TemplateHaskell #-}
-- Quotes printed: binders get new names, an outer local is lifted, a
-- pattern quote has mkName's variables, a nested splice is run with the quote.
import Language.Haskell.TH
main :: IO ()
main = do
  e1 <- runQ [| \x -> (x + 1, map negate [x, 2 * x]) |]
  putStrLn (pprint e1)
  e2 <- runQ [| let f y = y * 3 in if f 2 > 5 then "big" else "small" |]
  putStrLn (pprint e2)
  let n = 42 :: Int
  e3 <- runQ [| n + 1 |]
  putStrLn (pprint e3)
  p <- runQ [p| (x, Just y) |]
  putStrLn (pprint p)
  t <- runQ [t| Maybe Int -> [Bool] |]
  putStrLn (pprint t)
  e4 <- runQ [| case Just 'c' of { Just c -> [c]; Nothing -> "" } |]
  putStrLn (pprint e4)
  e5 <- runQ [| [ (i, j) | i <- [1 .. 3], let j = i * i, odd i ] |]
  putStrLn (pprint e5)
  e6 <- runQ [| 1 + $(litE (integerL 2)) |]
  putStrLn (pprint e6)
