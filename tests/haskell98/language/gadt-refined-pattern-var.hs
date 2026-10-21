{-# LANGUAGE GADTs, KindSignatures, MultiParamTypeClasses, FlexibleInstances #-}
import Data.Kind (Type)

data Equal (f :: Type -> Type) a b where
  Refl :: Equal f (f b) b

newtype Rec1 t a = Rec1 (t a) deriving Show

class GTraverse arr t where
  gtraverse_ :: Applicative f => arr f a b -> t a -> f (t b)

instance Traversable t => GTraverse Equal (Rec1 t) where
  gtraverse_ Refl (Rec1 x) = Rec1 <$> sequenceA x

main :: IO ()
main = print (gtraverse_ Refl (Rec1 [Just 1, Just (2 :: Int)]))
