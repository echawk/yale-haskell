{-# LANGUAGE TypeFamilies #-}
module Main (main) where
import qualified GHC.Exts as Exts (IsList(..))

newtype Bag a = Bag [a] deriving Show

instance Exts.IsList (Bag a) where
  type Item (Bag a) = a
  fromList = Bag
  toList (Bag xs) = xs

main :: IO ()
main = print (Exts.fromList "abc" :: Bag Char) >> print (Exts.toList (Bag [True]))
