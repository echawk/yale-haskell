{-# LANGUAGE TypeFamilies #-}
-- GHC.IsList (base): OverloadedLists' class (parser/exp-parser.mumble).
-- Item is an associated type family, as in base.
module GHC.IsList (IsList(..), Item) where

import qualified Data.Map as M
import qualified Data.Set as S
import qualified Data.IntMap as IM
import qualified Data.List.NonEmpty as NE
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import qualified Data.Sequence as Seq
import qualified Data.Foldable as F
import Data.Word (Word8)

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

-- text's and bytestring's (ListLike's instances use them)
instance IsList T.Text where
  type Item T.Text = Char
  fromList = T.pack
  toList = T.unpack
  fromListN _ = T.pack

instance IsList TL.Text where
  type Item TL.Text = Char
  fromList = TL.pack
  toList = TL.unpack
  fromListN _ = TL.pack

instance IsList B.ByteString where
  type Item B.ByteString = Word8
  fromList = B.pack
  toList = B.unpack
  fromListN _ = B.pack

instance IsList BL.ByteString where
  type Item BL.ByteString = Word8
  fromList = BL.pack
  toList = BL.unpack
  fromListN _ = BL.pack

instance IsList (Seq.Seq a) where
  type Item (Seq.Seq a) = a
  fromList = Seq.fromList
  toList = F.toList
  fromListN _ = Seq.fromList
