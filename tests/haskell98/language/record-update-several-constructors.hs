{-# LANGUAGE OverloadedLists, TypeFamilies #-}
-- A record update of a field several constructors have: the new value
-- is type checked once (Agda's core { lhsPats = lhsPats core ++ toList ps })
module Main (main) where
import qualified Data.List.NonEmpty as NE

data Core = Head { pats :: [Int], name :: String } | Tail { pats :: [Int] }
  deriving Show

append :: Core -> NE.NonEmpty Int -> Core
append core ps = core { pats = pats core ++ NE.toList ps }

main :: IO ()
main = print (append (Head [1] "f") (2 NE.:| [3]), append (Tail []) (4 NE.:| []))
