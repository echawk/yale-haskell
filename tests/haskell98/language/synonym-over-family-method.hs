{-# LANGUAGE TypeFamilies, DataKinds, PolyKinds, TypeOperators, KindSignatures, MultiParamTypeClasses, FlexibleInstances, ScopedTypeVariables #-}
-- A class method's synonym over a type family (Agda's Arrows as b, Foldr (->) b
-- as): at '[] it expands to b, which unify sees through
module Main (main) where
import Data.Kind (Type)
import Data.Proxy

type family Foldr (c :: k -> l -> l) (n :: l) (as :: [k]) :: l where
  Foldr c n '[]       = n
  Foldr c n (a ': as) = c a (Foldr c n as)

type Arrows   (as :: [Type]) (r :: Type) = Foldr (->) r as
type Products (as :: [Type])             = Foldr (,) () as

class Currying as b where
  uncurrys :: Proxy as -> Proxy b -> Arrows as b -> Products as -> b
  currys   :: Proxy as -> Proxy b -> (Products as -> b) -> Arrows as b

instance Currying '[] b where
  uncurrys _ _ f = \ () -> f
  currys   _ _ f = f ()

instance Currying as b => Currying (a ': as) b where
  uncurrys _ p f = uncurry $ uncurrys (Proxy :: Proxy as) p . f
  currys   _ p f = currys (Proxy :: Proxy as) p . curry f

main :: IO ()
main = print (uncurrys (Proxy :: Proxy '[Int, Int]) (Proxy :: Proxy Int) (+) (1, (2, ())))
