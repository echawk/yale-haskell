-- Data.Unique (base): values distinct from every other made by
-- newUnique, from a global counter.
module Data.Unique (Unique, newUnique, hashUnique) where

import Data.IORef
import System.IO.Unsafe (unsafePerformIO)

newtype Unique = Unique Integer deriving (Eq, Ord)

counter :: IORef Integer
counter = unsafePerformIO (newIORef 0)
{-# NOINLINE counter #-}

newUnique :: IO Unique
newUnique = atomicModifyIORef counter (\n -> (n + 1, Unique (n + 1)))

hashUnique :: Unique -> Int
hashUnique (Unique n) = fromInteger n
