{-# LANGUAGE TypeFamilies, RankNTypes #-}
import Control.Monad.ST
import Data.STRef
class Monad m => PM m where
  type PS m
  newV :: a -> m (STRef (PS m) a)
instance PM (ST s) where
  type PS (ST s) = s
  newV = newSTRef
mk :: a -> ST s (STRef s a)
mk x = newV x
run :: (forall s. ST s (STRef s Int)) -> Int
run m = runST (m >>= readSTRef)
main = print (run (mk 41) + 1)
