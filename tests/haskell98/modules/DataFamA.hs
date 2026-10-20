{-# LANGUAGE TypeFamilies #-}
module DataFamA (Vec(..)) where
data family Vec a
newtype instance Vec Int = VInt [Int]
data instance Vec Bool = VBool Int
