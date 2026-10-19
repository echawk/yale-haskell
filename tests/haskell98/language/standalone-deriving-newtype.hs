-- Standalone and newtype deriving of a class defined in the same module.
{-# LANGUAGE StandaloneDeriving, GeneralizedNewtypeDeriving #-}
import Data.Ord (Down(..))
class Sz a where sz :: a -> Int
instance Sz Int where sz _ = 8
deriving instance Sz a => Sz (Down a)
newtype N = N Int
deriving instance Sz N
main = print (sz (Down (3::Int)), sz (N 1))
