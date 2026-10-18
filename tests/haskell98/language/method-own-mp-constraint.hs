{-# LANGUAGE ScopedTypeVariables, RankNTypes, MultiParamTypeClasses #-}
-- A class method with its own multi-parameter constraint (profunctors'
-- (#.) :: Coercible c b => ...): the class's type variable stays the carrier
import Data.Coerce
class P p where
  rmap :: (b -> c) -> p a b -> p a c
  (#.) :: forall a b c q. Coercible c b => q b c -> p a b -> p a c
  (#.) = \_ -> \p -> p `seq` rmap (coerce (id :: c -> c) :: b -> c) p
newtype F a b = F (a -> b)
instance P F where
  rmap g (F f) = F (g . f)
data Pr p q a b = Pr (p a b) (q a b)
instance (P p, P q) => P (Pr p q) where
  rmap g (Pr p q) = Pr (rmap g p) (rmap g q)
  (#.) f (Pr p q) = Pr (f #. p) (f #. q)
newtype N = N Int deriving Show
main :: IO ()
main = case (N #. Pr (F (+1)) (F (*2))) of Pr (F a) (F b) -> print (a 3, b (4 :: Int))
