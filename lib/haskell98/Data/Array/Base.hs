-- Data.Array.Base (array): mutable arrays in ST and IO, over a primitive
-- vector (BasePrims.hi), and the MArray class.
--
-- The unboxed mutable types (STUArray, IOUArray) are element-strict
-- versions of the boxed ones: a value is evaluated when it is written, as
-- GHC's unboxed arrays hold evaluated values (a loop that accumulates in
-- one does not build thunks).  UArray is Array.  runSTArray's type is the
-- Haskell 98 one (see Control.Monad.ST's runST).
module Data.Array.Base (
    MArray(getBounds, newArray, newArray_, unsafeNewArray_, unsafeRead, unsafeWrite),
    getNumElements, readArray, writeArray, modifyArray, modifyArray',
    newListArray, newGenArray, getElems, getAssocs, mapArray,
    freeze, thaw, unsafeFreeze, unsafeThaw,
    STArray, STUArray, IOArray, IOUArray, UArray,
    runSTArray, runSTUArray, unsafeAt, numElements
  ) where

import Ix
import Array
import Monad (zipWithM_)
import BasePrims
import Control.Monad.ST (ST, runST, unsafeIOToST)

class Monad m => MArray a e m where
  getBounds       :: Ix i => a i e -> m (i, i)
  newArray        :: Ix i => (i, i) -> e -> m (a i e)
  newArray_       :: Ix i => (i, i) -> m (a i e)
  unsafeNewArray_ :: Ix i => (i, i) -> m (a i e)
  unsafeRead      :: Ix i => a i e -> Int -> m e
  unsafeWrite     :: Ix i => a i e -> Int -> e -> m ()
  -- the representation, for freeze and thaw (not exported)
  arrVector       :: a i e -> m (MutArr e)
  arrFromVector   :: (i, i) -> Int -> MutArr e -> m (a i e)
  arrIO           :: a i e -> IO x -> m x     -- the array: only its type

  newArray_ b = newArray b arrEleBottom
  unsafeNewArray_ b = newArray b arrEleBottom

arrEleBottom :: a
arrEleBottom = error "MArray: undefined array element"

data STArray s i e = STArray (i, i) Int (MutArr e)
data IOArray i e = IOArray (i, i) Int (MutArr e)
data STUArray s i e = STUArray (i, i) Int (MutArr e)
data IOUArray i e = IOUArray (i, i) Int (MutArr e)

type UArray = Array

instance Eq (STArray s i e) where
  STArray _ _ a == STArray _ _ b = primMutArrEq a b

instance Eq (IOArray i e) where
  IOArray _ _ a == IOArray _ _ b = primMutArrEq a b

instance MArray (STArray s) e (ST s) where
  {-# getBounds :: Inline #-}
  {-# unsafeRead :: Inline #-}
  {-# unsafeWrite :: Inline #-}
  arrVector (STArray _ _ v) = return v
  arrFromVector b n v = return (STArray b n v)
  arrIO _ = unsafeIOToST
  getBounds (STArray b _ _) = return b
  newArray b x = unsafeIOToST (let n = rangeSize b in
                               primNewMutArr n x >>= \v -> return (STArray b n v))
  unsafeRead (STArray _ _ v) i = unsafeIOToST (primReadMutArr v i)
  unsafeWrite (STArray _ _ v) i x = unsafeIOToST (primWriteMutArr v i x)

instance MArray (STUArray s) e (ST s) where
  {-# getBounds :: Inline #-}
  {-# unsafeRead :: Inline #-}
  {-# unsafeWrite :: Inline #-}
  arrVector (STUArray _ _ v) = return v
  arrFromVector b n v = return (STUArray b n v)
  arrIO _ = unsafeIOToST
  getBounds (STUArray b _ _) = return b
  newArray b x = x `seq` unsafeIOToST (let n = rangeSize b in
                                       primNewMutArr n x >>= \v -> return (STUArray b n v))
  newArray_ b = unsafeIOToST (let n = rangeSize b in
                              primNewMutArr n arrEleBottom >>= \v -> return (STUArray b n v))
  unsafeNewArray_ b = newArray_ b
  unsafeRead (STUArray _ _ v) i = unsafeIOToST (primReadMutArr v i)
  unsafeWrite (STUArray _ _ v) i x = x `seq` unsafeIOToST (primWriteMutArr v i x)

instance MArray IOUArray e IO where
  {-# getBounds :: Inline #-}
  {-# unsafeRead :: Inline #-}
  {-# unsafeWrite :: Inline #-}
  arrVector (IOUArray _ _ v) = return v
  arrFromVector b n v = return (IOUArray b n v)
  arrIO _ = id
  getBounds (IOUArray b _ _) = return b
  newArray b x = x `seq` (let n = rangeSize b in
                          primNewMutArr n x >>= \v -> return (IOUArray b n v))
  newArray_ b = let n = rangeSize b in
                primNewMutArr n arrEleBottom >>= \v -> return (IOUArray b n v)
  unsafeNewArray_ b = newArray_ b
  unsafeRead (IOUArray _ _ v) i = primReadMutArr v i
  unsafeWrite (IOUArray _ _ v) i x = x `seq` primWriteMutArr v i x

instance MArray IOArray e IO where
  {-# getBounds :: Inline #-}
  {-# unsafeRead :: Inline #-}
  {-# unsafeWrite :: Inline #-}
  arrVector (IOArray _ _ v) = return v
  arrFromVector b n v = return (IOArray b n v)
  arrIO _ = id
  getBounds (IOArray b _ _) = return b
  newArray b x = let n = rangeSize b in
                 primNewMutArr n x >>= \v -> return (IOArray b n v)
  unsafeRead (IOArray _ _ v) i = primReadMutArr v i
  unsafeWrite (IOArray _ _ v) i x = primWriteMutArr v i x

getNumElements :: (MArray a e m, Ix i) => a i e -> m Int
getNumElements a = getBounds a >>= \b -> return (rangeSize b)

readArray :: (MArray a e m, Ix i) => a i e -> i -> m e
readArray a i = getBounds a >>= \b -> unsafeRead a (index b i)
{-# readArray :: Inline #-}

writeArray :: (MArray a e m, Ix i) => a i e -> i -> e -> m ()
writeArray a i x = getBounds a >>= \b -> unsafeWrite a (index b i) x
{-# writeArray :: Inline #-}

modifyArray :: (MArray a e m, Ix i) => a i e -> i -> (e -> e) -> m ()
modifyArray a i f = readArray a i >>= \x -> writeArray a i (f x)

modifyArray' :: (MArray a e m, Ix i) => a i e -> i -> (e -> e) -> m ()
modifyArray' a i f = readArray a i >>= \x -> let x' = f x in x' `seq` writeArray a i x'

newListArray :: (MArray a e m, Ix i) => (i, i) -> [e] -> m (a i e)
newListArray b xs = newArray_ b >>= \a ->
                    zipWithM_ (unsafeWrite a) [0 .. rangeSize b - 1] xs >> return a

newGenArray :: (MArray a e m, Ix i) => (i, i) -> (i -> m e) -> m (a i e)
newGenArray b f = newArray_ b >>= \a ->
                  mapM_ (\(i, k) -> f i >>= unsafeWrite a k) (zip (range b) [0 ..]) >>
                  return a

getElems :: (MArray a e m, Ix i) => a i e -> m [e]
getElems a = getBounds a >>= \b -> mapM (unsafeRead a) [0 .. rangeSize b - 1]

getAssocs :: (MArray a e m, Ix i) => a i e -> m [(i, e)]
getAssocs a = getBounds a >>= \b -> getElems a >>= \xs -> return (zip (range b) xs)

mapArray :: (MArray a e' m, MArray a e m, Ix i) => (e' -> e) -> a i e' -> m (a i e)
mapArray f a = getBounds a >>= \b -> getElems a >>= \xs -> newListArray b (map f xs)

-- Array's vector holds the same values as a mutable array's (BasePrims):
-- freezing and thawing copy it, the unsafe versions share it
freeze :: (Ix i, MArray a e m) => a i e -> m (Array i e)
freeze a = getBounds a >>= \b -> arrVector a >>= \v -> arrIO a (primCopyMutArrToArray b v)

unsafeFreeze :: (Ix i, MArray a e m) => a i e -> m (Array i e)
unsafeFreeze a = getBounds a >>= \b -> arrVector a >>= \v -> return (primMutArrToArray b v)

thaw :: (Ix i, MArray a e m) => Array i e -> m (a i e)
thaw arr = result
  where b = bounds arr
        result = arrIO (resultArray result) (primCopyArrayToMutArr arr) >>= \v ->
                 arrFromVector b (rangeSize b) v

-- only its type is used (arrIO)
resultArray :: m x -> x
resultArray _ = error "resultArray"

unsafeThaw :: (Ix i, MArray a e m) => Array i e -> m (a i e)
unsafeThaw arr = let b = bounds arr in arrFromVector b (rangeSize b) (primArrayToMutArr arr)

runSTArray :: Ix i => ST s (STArray s i e) -> Array i e
runSTArray st = runST (st >>= unsafeFreeze)

runSTUArray :: Ix i => ST s (STUArray s i e) -> UArray i e
runSTUArray st = runST (st >>= unsafeFreeze)

-- The element at an offset (0 .. numElements - 1)
unsafeAt :: Ix i => Array i e -> Int -> e
unsafeAt arr k = primUnsafePerformIO (primReadMutArr (primArrayToMutArr arr) k)

numElements :: Ix i => Array i e -> Int
numElements arr = rangeSize (bounds arr)
