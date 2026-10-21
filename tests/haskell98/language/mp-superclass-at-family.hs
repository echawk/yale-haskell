{-# LANGUAGE TypeFamilies, MultiParamTypeClasses, FunctionalDependencies, FlexibleContexts, FlexibleInstances #-}
import Data.Kind (Type)
class (Functor f) => Sieve p f | p -> f where
  sieve :: p a b -> a -> f b
class Sieve p (Rep p) => Representable p where
  type Rep p :: Type -> Type
  tabulate :: (d -> Rep p c) -> p d c

newtype Star f a b = Star (a -> f b)
instance Functor f => Sieve (Star f) f where sieve (Star g) = g
instance Functor f => Representable (Star f) where
  type Rep (Star f) = f
  tabulate = Star

foo :: Representable p => p a b -> a -> Rep p (b, ())
foo p a = fmap (\b -> (b, ())) (sieve p a)

bar :: Sieve p (Rep p) => p a b -> a -> Rep p (b, ())
bar p a = fmap (\b -> (b, ())) (sieve p a)

main :: IO ()
main = print (foo (Star (\x -> Just (x + 1))) (1 :: Int), bar (Star (\x -> [x])) 'c')
