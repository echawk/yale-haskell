-- The layout rule's parse-error(t) (Report 9.3): a token that cannot
-- continue an implicit block closes it.

main :: IO ()
main = do
  print (f 3)
  print xs
  print (do x <- [1, 2]; [x, x * 10])
  print [ y | y <- (do z <- [1, 2, 3]; return (z * 2)), y > 2 ]
  r <- if x > 0 then do return "pos" else do return "neg"
  putStrLn r
  print (let a = 1; b = 2 in a + b)
  where f n = n + 1
        xs = case x of 1 -> "one"; _ -> "other"
        x = 1 :: Int
