{-# LANGUAGE KindSignatures, GADTs #-}
import Data.Kind (Type)
data Tag :: Type
data Box :: Type -> Type where
  Box :: a -> Box a
unbox :: Box a -> a
unbox (Box x) = x
main = print (unbox (Box (3 :: Int)))
