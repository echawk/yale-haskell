{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
import Data.Array.Base
import Data.Array.ST
import Control.Monad.ST

-- An instance overriding getNumElements, as STMonadTrans's does.
newtype Counted s i e = Counted (STArray s i e)
instance MArray (Counted s) e (ST s) where
  getBounds (Counted a) = getBounds a
  getNumElements (Counted a) = fmap (* 10) (getNumElements a)
  newArray b e = fmap Counted (newArray b e)
  unsafeRead (Counted a) = unsafeRead a
  unsafeWrite (Counted a) = unsafeWrite a

main :: IO ()
main = print (runST (do
  a <- newArray (1, 5) 'x' :: ST s (STArray s Int Char)
  c <- newArray (0, 2) 'y' :: ST s (Counted s Int Char)
  writeArray c 1 'z'
  z <- readArray c 1
  (,,) <$> getNumElements a <*> getNumElements c <*> pure z))
