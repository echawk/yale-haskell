{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances #-}
-- A functional dependency improves its `to' positions only: source is
-- not determined by regex (regex-base's RegexMaker), so an instance at
-- one source may use the instance at another
module Main (main) where

newtype Regex = Regex String deriving Show
newtype Opt = Opt Int

class Maker regex opt source | regex -> opt, opt -> regex where
  makeWith :: opt -> source -> regex

instance Maker Regex Opt String where
  makeWith (Opt n) s = Regex (take n s)

newtype Bytes = Bytes [Char]

instance Maker Regex Opt Bytes where
  makeWith o (Bytes cs) = makeWith o cs

main :: IO ()
main = print (makeWith (Opt 3) (Bytes "abcdef") :: Regex)
