{-# LANGUAGE TypeFamilies #-}
import GHC.Exts (IsList (Item, fromList))
f :: [Int] -> [Item [Int]]
f = id
main = print (f (fromList [1, 2]))
