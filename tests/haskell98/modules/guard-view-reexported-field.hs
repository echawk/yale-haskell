{-# LANGUAGE OverloadedStrings #-}
module Main where
import ReexpFieldA
import ReexpFieldB
import qualified Data.Map as M
import qualified Data.List as M (sortOn)
import Data.Text (Text)

data B = L | O Text

isMain :: B -> Bool
isMain b | O "GHCNoMain" <- b = False
         | otherwise = True

main :: IO ()
main = do
  print (nonFatal (WE [1] [2]))
  print (isMain (O "GHCNoMain"), isMain L)
  print (M.size (M.fromList [(1 :: Int, True)]), M.sortOn negate [1, 3, 2 :: Int])
