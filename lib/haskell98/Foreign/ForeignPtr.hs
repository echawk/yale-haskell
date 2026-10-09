-- Foreign.ForeignPtr: the Haskell 2010 library module (Report 2010,
-- chapter 32), for Yale Haskell's Haskell 98 dialect.  A ForeignPtr is a
-- Ptr with finalizers (C functions) that run once it is unreachable, as
-- the host Lisp's garbage collector finds, or when finalizeForeignPtr
-- runs them (src/ffi/ffi-runtime.lisp).  Finalizers run newest first.
-- mallocForeignPtr allocates with malloc, freed by finalizerFree.
module Foreign.ForeignPtr (
    ForeignPtr, FinalizerPtr, FinalizerEnvPtr,
    newForeignPtr, newForeignPtr_, addForeignPtrFinalizer,
    newForeignPtrEnv, addForeignPtrFinalizerEnv,
    withForeignPtr, finalizeForeignPtr, unsafeForeignPtrToPtr,
    touchForeignPtr, castForeignPtr,
    mallocForeignPtr, mallocForeignPtrBytes,
    mallocForeignPtrArray, mallocForeignPtrArray0
  ) where

import ForeignPrims
import Foreign.Ptr
import Foreign.Storable
import Foreign.Marshal.Alloc (malloc, mallocBytes, finalizerFree)
import Foreign.Marshal.Array (mallocArray, mallocArray0)

data ForeignPtr a = ForeignPtr (Ptr a) FPState

type FinalizerPtr a        = FunPtr (Ptr a -> IO ())
type FinalizerEnvPtr env a = FunPtr (Ptr env -> Ptr a -> IO ())

instance Eq (ForeignPtr a) where
  ForeignPtr p _ == ForeignPtr q _ = p == q

instance Ord (ForeignPtr a) where
  compare (ForeignPtr p _) (ForeignPtr q _) = compare p q

instance Show (ForeignPtr a) where
  showsPrec d (ForeignPtr p _) = showsPrec d p

newForeignPtr_ :: Ptr a -> IO (ForeignPtr a)
newForeignPtr_ p = do
  st <- primNewFPState p
  return (ForeignPtr p st)

newForeignPtr :: FinalizerPtr a -> Ptr a -> IO (ForeignPtr a)
newForeignPtr fin p = do
  fp <- newForeignPtr_ p
  addForeignPtrFinalizer fin fp
  return fp

newForeignPtrEnv :: FinalizerEnvPtr env a -> Ptr env -> Ptr a -> IO (ForeignPtr a)
newForeignPtrEnv fin env p = do
  fp <- newForeignPtr_ p
  addForeignPtrFinalizerEnv fin env fp
  return fp

addForeignPtrFinalizer :: FinalizerPtr a -> ForeignPtr a -> IO ()
addForeignPtrFinalizer fin (ForeignPtr _ st) = primAddFPFinalizer st fin

addForeignPtrFinalizerEnv :: FinalizerEnvPtr env a -> Ptr env -> ForeignPtr a -> IO ()
addForeignPtrFinalizerEnv fin env (ForeignPtr _ st) = primAddFPFinalizerEnv st fin env

withForeignPtr :: ForeignPtr a -> (Ptr a -> IO b) -> IO b
withForeignPtr fp@(ForeignPtr p _) act = do
  r <- act p
  touchForeignPtr fp
  return r

finalizeForeignPtr :: ForeignPtr a -> IO ()
finalizeForeignPtr (ForeignPtr _ st) = primFinalizeFP st

unsafeForeignPtrToPtr :: ForeignPtr a -> Ptr a
unsafeForeignPtrToPtr (ForeignPtr p _) = p

touchForeignPtr :: ForeignPtr a -> IO ()
touchForeignPtr (ForeignPtr _ st) = primTouchFP st

castForeignPtr :: ForeignPtr a -> ForeignPtr b
castForeignPtr (ForeignPtr p st) = ForeignPtr (castPtr p) st

mallocForeignPtr :: Storable a => IO (ForeignPtr a)
mallocForeignPtr = malloc >>= newForeignPtr finalizerFree

mallocForeignPtrBytes :: Int -> IO (ForeignPtr a)
mallocForeignPtrBytes n = mallocBytes n >>= newForeignPtr finalizerFree

mallocForeignPtrArray :: Storable a => Int -> IO (ForeignPtr a)
mallocForeignPtrArray n = mallocArray n >>= newForeignPtr finalizerFree

mallocForeignPtrArray0 :: Storable a => Int -> IO (ForeignPtr a)
mallocForeignPtrArray0 n = mallocArray0 n >>= newForeignPtr finalizerFree
