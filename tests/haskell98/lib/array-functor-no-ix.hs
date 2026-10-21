import Data.Array
class Inv f where inv :: (a -> b) -> f a -> f b
invF :: Functor f => (a -> b) -> f a -> f b
invF = fmap
instance Inv (Array i) where inv = invF
main = print (inv (+1) (listArray (0,1) [1,2 :: Int]))
