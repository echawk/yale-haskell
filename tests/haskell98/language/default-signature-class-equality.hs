{-# LANGUAGE DefaultSignatures, MultiParamTypeClasses, FunctionalDependencies, FlexibleInstances, TypeFamilies #-}
class Traversable t => TWI i t | t -> i where
  itraverse :: Applicative f => (i -> a -> f b) -> t a -> f (t b)
  default itraverse :: (i ~ Int, Applicative f) => (i -> a -> f b) -> t a -> f (t b)
  itraverse f = traverse (f 0)

instance TWI Int Maybe

main :: IO ()
main = print (itraverse (\i x -> Just (i + x)) (Just (5 :: Int)))
