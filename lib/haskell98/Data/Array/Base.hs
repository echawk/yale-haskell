-- Data.Array.Base (array): mutable arrays in ST and IO, over a primitive
-- vector (BasePrims.hi), and the MArray class.
--
-- The unboxed mutable types (STUArray, IOUArray) are element-strict
-- versions of the boxed ones: a value is evaluated when it is written, as
-- GHC's unboxed arrays hold evaluated values (a loop that accumulates in
-- one does not build thunks).  An unboxed array of Bool made by newArray
-- is a bit vector, one bit per element (primNewUMutArr; frozen, the
-- Array's vector is that bit vector).  UArray is Array.  runSTArray's type is the
-- Haskell 98 one (see Control.Monad.ST's runST).
module Data.Array.Base (
    MArray(getBounds, getNumElements, newArray, newArray_, unsafeNewArray_, unsafeRead, unsafeWrite),
    readArray, writeArray, modifyArray, modifyArray',
    newListArray, newGenArray, getElems, getAssocs, mapArray,
    freeze, thaw, unsafeFreeze, unsafeThaw,
    STArray, STUArray, IOArray, IOUArray, UArray,
    runSTArray, runSTUArray, IA.IArray(..),
    boundsSTArray, numElementsSTArray, unsafeReadSTArray, unsafeWriteSTArray,
    freezeSTArray, unsafeFreezeSTArray, thawSTArray, unsafeThawSTArray
  ) where

import Ix
import Array
import Monad (zipWithM_)
import BasePrims
import qualified DataArrayIArrayBase as IA
import Control.Monad.ST (ST, runST, unsafeIOToST)

class Monad m => MArray a e m where
  getBounds       :: Ix i => a i e -> m (i, i)
  getNumElements  :: Ix i => a i e -> m Int
  newArray        :: Ix i => (i, i) -> e -> m (a i e)
  newArray_       :: Ix i => (i, i) -> m (a i e)
  unsafeNewArray_ :: Ix i => (i, i) -> m (a i e)
  unsafeRead      :: Ix i => a i e -> Int -> m e
  unsafeWrite     :: Ix i => a i e -> Int -> e -> m ()
  -- the representation, for freeze and thaw (not exported): an array
  -- type of this module's is a vector; another's (STMonadTrans's
  -- STArray over STT) is frozen and thawed element by element
  arrNative       :: a i e -> m Bool          -- the array: only its type
  arrVector       :: a i e -> m (MutArr e)
  arrFromVector   :: (i, i) -> Int -> MutArr e -> m (a i e)
  arrIO           :: a i e -> IO x -> m x     -- the array: only its type

  getNumElements a = getBounds a >>= \b -> return (rangeSize b)
  arrNative _ = return False
  arrVector _ = error "MArray: arrVector"
  arrFromVector _ _ _ = error "MArray: arrFromVector"
  arrIO _ = error "MArray: arrIO"
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
  arrNative _ = return True
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
  arrNative _ = return True
  getBounds (STUArray b _ _) = return b
  newArray b x = x `seq` unsafeIOToST (let n = rangeSize b in
                                       primNewUMutArr n x >>= \v -> return (STUArray b n v))
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
  arrNative _ = return True
  getBounds (IOUArray b _ _) = return b
  newArray b x = x `seq` (let n = rangeSize b in
                          primNewUMutArr n x >>= \v -> return (IOUArray b n v))
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
  arrNative _ = return True
  getBounds (IOArray b _ _) = return b
  newArray b x = let n = rangeSize b in
                 primNewMutArr n x >>= \v -> return (IOArray b n v)
  unsafeRead (IOArray _ _ v) i = primReadMutArr v i
  unsafeWrite (IOArray _ _ v) i x = primWriteMutArr v i x


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
freeze a = arrNative a >>= \native ->
  if native
    then getBounds a >>= \b -> arrVector a >>= \v -> arrIO a (primCopyMutArrToArray b v)
    else getBounds a >>= \b -> getElems a >>= \xs -> return (listArray b xs)

unsafeFreeze :: (Ix i, MArray a e m) => a i e -> m (Array i e)
unsafeFreeze a = arrNative a >>= \native ->
  if native
    then getBounds a >>= \b -> arrVector a >>= \v -> return (primMutArrToArray b v)
    else freeze a

thaw :: (Ix i, MArray a e m) => Array i e -> m (a i e)
thaw arr = result
  where b = bounds arr
        result = arrNative (resultArray result) >>= \native ->
          if native
            then arrIO (resultArray result) (primCopyArrayToMutArr arr) >>= \v ->
                 arrFromVector b (rangeSize b) v
            else newListArray b (elems arr)

-- only its type is used (arrIO)
resultArray :: m x -> x
resultArray _ = error "resultArray"

unsafeThaw :: (Ix i, MArray a e m) => Array i e -> m (a i e)
unsafeThaw arr = result
  where b = bounds arr
        result = arrNative (resultArray result) >>= \native ->
          if native
            then arrFromVector b (rangeSize b) (primArrayToMutArr arr)
            else thaw arr

runSTArray :: Ix i => ST s (STArray s i e) -> Array i e
runSTArray st = runST (st >>= unsafeFreeze)

runSTUArray :: Ix i => ST s (STUArray s i e) -> UArray i e
runSTUArray st = runST (st >>= unsafeFreeze)

-- GHC.Arr's STArray operations
boundsSTArray :: STArray s i e -> (i, i)
boundsSTArray (STArray b _ _) = b

numElementsSTArray :: STArray s i e -> Int
numElementsSTArray (STArray _ n _) = n

unsafeReadSTArray :: STArray s i e -> Int -> ST s e
unsafeReadSTArray (STArray _ _ v) i = unsafeIOToST (primReadMutArr v i)

unsafeWriteSTArray :: STArray s i e -> Int -> e -> ST s ()
unsafeWriteSTArray (STArray _ _ v) i e = unsafeIOToST (primWriteMutArr v i e)

freezeSTArray, unsafeFreezeSTArray :: Ix i => STArray s i e -> ST s (Array i e)
freezeSTArray = freeze
unsafeFreezeSTArray = unsafeFreeze

thawSTArray, unsafeThawSTArray :: Ix i => Array i e -> ST s (STArray s i e)
thawSTArray = thaw
unsafeThawSTArray = unsafeThaw
