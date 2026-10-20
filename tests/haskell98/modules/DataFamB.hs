{-# LANGUAGE TypeFamilies #-}
module DataFamB (Vec(VInt), sizeOf) where
import DataFamA
sizeOf :: Vec Int -> Int
sizeOf (VInt xs) = length xs
