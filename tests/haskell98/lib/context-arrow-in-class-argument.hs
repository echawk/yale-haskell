{-# LANGUAGE DefaultSignatures, FlexibleContexts, TypeFamilies #-}
module Main where
import Control.Monad.Reader

class MetasToVars a where
  metasToVars
    :: (MonadReader (Int -> Maybe Int) m , Monad m)
    => a -> m a

  default metasToVars
    :: ( MetasToVars a', Traversable f, a ~ f a'
       , MonadReader (Int -> Maybe Int) m , Monad m)
    => a -> m a
  metasToVars = traverse metasToVars

instance MetasToVars Int where
  metasToVars n = asks (\f -> maybe n id (f n))

instance MetasToVars a => MetasToVars [a]

main :: IO ()
main = print (runReader (metasToVars [1, 2, 3 :: Int]) (\n -> if n == 2 then Just 20 else Nothing))
