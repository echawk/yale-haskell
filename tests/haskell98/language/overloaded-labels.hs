-- OverloadedLabels: #x is fromLabel @"x"; x# is still a MagicHash name.
{-# LANGUAGE OverloadedLabels, DataKinds, FlexibleInstances, MultiParamTypeClasses, MagicHash #-}
import GHC.OverloadedLabels
import GHC.Exts
newtype L = L String deriving Show
instance IsLabel "foo" L where fromLabel = L "foo!"
instance IsLabel "bar_2" (Int -> Int) where fromLabel = (* 2)
main = do
  print (#foo :: L)
  print ((#bar_2 :: Int -> Int) 21)
  print (I# 3#)
