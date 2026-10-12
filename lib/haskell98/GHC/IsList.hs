{-# LANGUAGE TypeFamilies #-}
-- GHC.IsList (base): OverloadedLists' class (parser/exp-parser.mumble).
-- Item is an associated type family, as in base.
module GHC.IsList (IsList(fromList, toList, fromListN), Item) where

import qualified Data.Map as M
import qualified Data.Set as S
import qualified Data.IntMap as IM
import qualified Data.List.NonEmpty as NE

class IsList l where
  type Item l
  fromList :: [Item l] -> l
  toList :: l -> [Item l]
  fromListN :: Int -> [Item l] -> l
  fromListN _ = fromList

instance IsList [a] where
  type Item [a] = a
  fromList xs = xs
  toList xs = xs

instance Ord k => IsList (M.Map k v) where
  type Item (M.Map k v) = (k, v)
  fromList = M.fromList
  toList = M.toList

instance Ord a => IsList (S.Set a) where
  type Item (S.Set a) = a
  fromList = S.fromList
  toList = S.toList

instance IsList (IM.IntMap v) where
  type Item (IM.IntMap v) = (Int, v)
  fromList = IM.fromList
  toList = IM.toList

instance IsList (NE.NonEmpty a) where
  type Item (NE.NonEmpty a) = a
  fromList = NE.fromList
  toList = NE.toList
