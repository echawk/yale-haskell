-- A field shared by several constructors, update through a shared
-- field, and C {} patterns, which work for any constructor, record or
-- not (Haskell 98 section 3.17.1).
module Main where
import Dialogue (stdout, appendChan, done, abort)

data Shape = Circle { label :: String, radius :: Int }
           | Rect   { label :: String, width :: Int, height :: Int }
           | Dot Int

isCircle, isDot :: Shape -> Bool
isCircle Circle {} = True
isCircle _         = False
isDot Dot {} = True
isDot _      = False

shapes :: [Shape]
shapes = [Circle "c" 2, Rect { label = "r", height = 3, width = 4 }]

out :: String
out = unlines [ unwords (map label shapes)
              , unwords (map (label . (\s -> s { label = label s ++ "!" })) shapes)
              , unwords (map (show . isCircle) shapes)
              , show (isDot (Dot 1), isCircle (Dot 1))
              , show (width (shapes !! 1) * height (shapes !! 1)) ]

main = appendChan stdout out abort done
