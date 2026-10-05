-- do notation in IO: binding results, let statements, if and case
-- inside do, a nested do block, and explicit braces and semicolons.
module Main where

greet :: String -> IO Int
greet name = do
  putStrLn ("hello " ++ name)
  return (length name)

main :: IO ()
main = do
  n <- greet "world"
  let doubled = n * 2
      msg     = "doubled: " ++ show doubled
  putStrLn msg
  if doubled > 5
    then putStrLn "big"
    else putStrLn "small"
  case n of
    5 -> do putStr "five"
            putStrLn "!"
    _ -> putStrLn "other"
  do { putStr "a"; putStr "b"; putStrLn "c" }
  mapM_ (\i -> putStrLn (show i ++ " squared is " ++ show (i * i))) [1, 2, 3]
