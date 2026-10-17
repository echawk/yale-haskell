{-# LANGUAGE DeriveGeneric, TypeOperators #-}
import GHC.Generics (Generic, U1(..), (:*:)(..), (:.:)(..), Par1(..), Rec1(..), M1(..))
data T = T Int deriving (Show, Generic)
class Dist f where size :: f a -> Int
instance Dist U1 where size _ = 0
instance Dist Par1 where size _ = 1
instance (Dist f, Dist g) => Dist (f :*: g) where size (a :*: b) = size a + size b
main = do
  print (T 1)
  print (size (U1 :*: Par1 'x'), fmap (+1) (Par1 (2 :: Int) :*: Par1 3) `seq` "ok")
