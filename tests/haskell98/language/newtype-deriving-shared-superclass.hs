{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Main where
import Data.Word (Word32)
class Enum i => HasFresh i where
  freshLens :: i -> i
  freshLens = succ
newtype MutualId = MutualId Word32 deriving (Eq, Ord, Show, Enum, Num)
instance HasFresh MutualId
main = print (freshLens (MutualId 4), [MutualId 1 .. MutualId 3])
