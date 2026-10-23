module Main where
main :: IO ()
main = do
  maybe mempty putStrLn (Nothing :: Maybe String)
  putStrLn "a" <> putStrLn "b"
  s <- return "x" <> return "y"
  print s
  mconcat [putStr "1", putStr "2", putStrLn "3"]
