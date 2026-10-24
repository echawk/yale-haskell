-- A local function is generalized over a flexible constraint whose
-- instance its variable chooses (ReportS [a]; Agda's impossibleSort).
{-# LANGUAGE FlexibleInstances, FlexibleContexts, OverloadedStrings #-}
module Main where

import Data.String (IsString(..))

newtype Doc = Doc String
instance IsString Doc where fromString = Doc

class ReportS a where
  reportS :: String -> a -> IO ()

instance ReportS [String] where reportS k xs = putStrLn (k ++ ": " ++ unwords xs)
instance ReportS [Doc] where reportS k ds = putStrLn (k ++ ": " ++ unwords [s | Doc s <- ds])

check :: Int -> IO ()
check n = do
  impossibleSort (show n)
  impossibleDoc (Doc "d")
  where
    impossibleSort s = reportS "impossible" [ "found sort:", s ]
    impossibleDoc d = reportS "doc" [ "found doc:", d ]

main :: IO ()
main = check 3
