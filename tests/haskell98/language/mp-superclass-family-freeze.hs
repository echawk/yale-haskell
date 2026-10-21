{-# LANGUAGE TypeFamilies, MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
module Main (main) where
import Data.Kind (Type)

type family Mutable (v :: Type -> Type) :: Type -> Type -> Type

class MVec v a where
  mlen :: v s a -> Int
class MVec (Mutable v) a => Vec v a where
  vlen :: v a -> Int
  vfreeze :: Mutable v s a -> v a

data family MVector s a
data family Vector a
type instance Mutable Vector = MVector

class (Vec Vector a, MVec MVector a) => Unbox a

newtype instance MVector s Int = MV_Int [Int]
newtype instance Vector Int = V_Int [Int]
instance MVec MVector Int where mlen (MV_Int xs) = length xs
instance Vec Vector Int where
  vlen (V_Int xs) = length xs
  vfreeze (MV_Int xs) = V_Int xs
instance Unbox Int

newtype Min a = Min a
newtype instance MVector s (Min a) = MV_Min (MVector s a)
newtype instance Vector (Min a) = V_Min (Vector a)
instance Unbox a => Unbox (Min a)
instance Unbox a => MVec MVector (Min a) where
  mlen (MV_Min v) = mlen v
instance Unbox a => Vec Vector (Min a) where
  vlen (V_Min v) = vlen v
  vfreeze (MV_Min v) = V_Min (vfreeze v)

mclone :: MVec v a => v s a -> v s a
mclone v = v

freeze1 :: Vec v a => Mutable v s a -> v a
freeze1 mv = vfreeze (mclone mv)

main :: IO ()
main = print (vlen (V_Min (V_Int [1, 2])), vlen (freeze1 (MV_Min (MV_Int [3])) :: Vector (Min Int)))
