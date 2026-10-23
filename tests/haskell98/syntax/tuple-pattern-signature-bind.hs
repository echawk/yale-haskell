{-# LANGUAGE ScopedTypeVariables #-}
module Main where
main :: IO ()
main = do
  let m = Just 3 :: Maybe Int
  case m of
    Just n | n > 5 ->
      print n

    -- Otherwise:
    _ -> do
     (a, bs :: [Int]) <- case m of
       Just k -> return (k, [k, k])
       Nothing -> return (0, [])
     print (a, bs)
