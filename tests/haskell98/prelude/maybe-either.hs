-- Maybe, Either, maybe, either and their Show/Read/Eq/Ord instances.
module Main where

safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv x y = Just (x `div` y)

parse :: String -> Either String Int
parse s = case reads s of
            [(n, "")] -> Right n
            _         -> Left ("bad: " ++ s)

main = appendChan stdout (unlines [
  show (safeDiv 7 2, safeDiv 1 0),
  show (map (maybe 0 (* 10)) [Just 4, Nothing]),
  show (map parse ["12", "x1", "-5"]),
  show (map (either length negate) [Left "abc", Right 4]),
  show (Just (Just Nothing :: Maybe (Maybe Int))),
  show (Just (-3) :: Maybe Int, Left (Just 2) :: Either (Maybe Int) Char),
  show (Nothing < Just (1::Int), Just 1 < Just (2::Int), Left 5 < (Right 1 :: Either Int Int)),
  show (Just 'x' == Just 'x', Right 1 /= (Left 1 :: Either Int Int)),
  show (read "Just (-2)" :: Maybe Int, read " [ Nothing , Just 3 ] " :: [Maybe Int]),
  show (read "(Right True)" :: Either Int Bool, read "Left 3" :: Either Int Bool),
  show (lookup "b" [("a", 1), ("b", 2 :: Int)], lookup 'z' (zip "ab" [1, 2 :: Int]))
  ]) abort done
