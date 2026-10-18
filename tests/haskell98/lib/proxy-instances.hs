import Data.Proxy
import Data.Functor.Contravariant
import Data.Functor.Product
main = do
  print (fmap (+1) (Proxy :: Proxy Int), length (Proxy :: Proxy Int), traverse Just (Proxy :: Proxy Int))
  print (Proxy <> (Proxy :: Proxy Char), (Proxy :: Proxy Int) >>= \_ -> Proxy :: Proxy Bool)
  case contramap length (Pair (Predicate even) (Predicate odd)) of
    Pair p q -> print (getPredicate p "ab", getPredicate q "ab")
