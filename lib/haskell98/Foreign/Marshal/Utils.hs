-- Foreign.Marshal.Utils: the Haskell 2010 library module (Report 2010,
-- chapter 36), for Yale Haskell's Haskell 98 dialect.
module Foreign.Marshal.Utils (
    with, new, fromBool, toBool, maybeNew, maybeWith, maybePeek,
    withMany, copyBytes, moveBytes, fillBytes
  ) where

import Data.Word
import ForeignPrims
import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Alloc

with :: Storable a => a -> (Ptr a -> IO b) -> IO b
with val f = alloca (\ptr -> poke ptr val >> f ptr)

new :: Storable a => a -> IO (Ptr a)
new val = malloc >>= \ptr -> poke ptr val >> return ptr

fromBool :: Num a => Bool -> a
fromBool False = 0
fromBool True  = 1

toBool :: Num a => a -> Bool
toBool = (/= 0)

maybeNew :: (a -> IO (Ptr b)) -> (Maybe a -> IO (Ptr b))
maybeNew = maybe (return nullPtr)

maybeWith :: (a -> (Ptr b -> IO c) -> IO c) -> (Maybe a -> (Ptr b -> IO c) -> IO c)
maybeWith = maybe ($ nullPtr)

maybePeek :: (Ptr a -> IO b) -> Ptr a -> IO (Maybe b)
maybePeek pk ptr | ptr == nullPtr = return Nothing
                 | otherwise      = pk ptr >>= return . Just

withMany :: (a -> (b -> res) -> res) -> [a] -> ([b] -> res) -> res
withMany _ []     f = f []
withMany withFoo (x:xs) f = withFoo x (\x' -> withMany withFoo xs (\xs' -> f (x':xs')))

copyBytes :: Ptr a -> Ptr a -> Int -> IO ()
copyBytes = primCopyBytes

moveBytes :: Ptr a -> Ptr a -> Int -> IO ()
moveBytes = primMoveBytes

fillBytes :: Ptr a -> Word8 -> Int -> IO ()
fillBytes p w n = primFillBytes p (fromIntegral w) n
