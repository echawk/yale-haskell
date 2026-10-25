-- An MArray instance of another module (STMonadTrans's STArray over STT):
-- freeze and thaw go element by element, as GHC's defaults do.
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
import Control.Monad.ST
import Data.Array
import Data.Array.ST
import Data.Array.MArray
newtype M s a = M { unM :: ST s a }
instance Functor (M s) where fmap f (M m) = M (fmap f m)
instance Applicative (M s) where pure = M . pure; M f <*> M a = M (f <*> a)
instance Monad (M s) where M m >>= f = M (m >>= unM . f)
newtype A s i e = A (STArray s i e)
instance MArray (A s) e (M s) where
  getBounds (A a) = M (getBounds a)
  newArray b x = M (fmap A (newArray b x))
  unsafeRead (A a) i = M (readArray a =<< fmap (\b -> range b !! i) (getBounds a))
  unsafeWrite (A a) i x = M (getBounds a >>= \b -> writeArray a (range b !! i) x)
main :: IO ()
main = do
  print (runST (unM (do a <- newArray (1, 3) 'x' :: M s (A s Int Char)
                        writeArray a 2 'y'
                        freeze a)))
  print (runST (unM (do a <- thaw (listArray (0, 2) [10, 20, 30]) :: M s (A s Int Int)
                        writeArray a 0 5
                        getElems a)))
