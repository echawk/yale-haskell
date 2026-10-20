{-# LANGUAGE OverloadedStrings #-}
module Main (main) where
import qualified Data.Text as T
f :: T.Text -> Int
f "one" = 1
f "two" = 2
f _ = 0
g :: T.Text -> Int
g t = case T.toLower t of
  "three" -> 3
  _ -> 0
main :: IO ()
main = print (f "two", f "x", g "THREE")
