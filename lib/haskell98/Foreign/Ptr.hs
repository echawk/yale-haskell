-- Foreign.Ptr: the Haskell 2010 library module (Report 2010, chapter 31),
-- for Yale Haskell's Haskell 98 dialect.  Ptr and FunPtr are CFFI
-- foreign pointers (ForeignPrims.hi, src/ffi/ffi-runtime.lisp).
-- FunPtrs made from Haskell functions ("wrapper" imports) are not
-- supported yet, so freeHaskellFunPtr does nothing.
module Foreign.Ptr (
    Ptr, nullPtr, castPtr, plusPtr, alignPtr, minusPtr,
    FunPtr, nullFunPtr, castFunPtr, castFunPtrToPtr, castPtrToFunPtr,
    freeHaskellFunPtr
  ) where

import ForeignPrims

nullPtr :: Ptr a
nullPtr = primNullPtr

castPtr :: Ptr a -> Ptr b
castPtr = primCastPtr

plusPtr :: Ptr a -> Int -> Ptr b
plusPtr = primPlusPtr

alignPtr :: Ptr a -> Int -> Ptr a
alignPtr p n = case primPtrToInteger p `rem` toInteger n of
                 0 -> p
                 r -> primPlusPtr p (n - fromInteger r)

minusPtr :: Ptr a -> Ptr b -> Int
minusPtr = primMinusPtr

nullFunPtr :: FunPtr a
nullFunPtr = primNullFunPtr

castFunPtr :: FunPtr a -> FunPtr b
castFunPtr = primCastFunPtr

castFunPtrToPtr :: FunPtr a -> Ptr b
castFunPtrToPtr = primCastFunPtrToPtr

castPtrToFunPtr :: Ptr a -> FunPtr b
castPtrToFunPtr = primCastPtrToFunPtr

freeHaskellFunPtr :: FunPtr a -> IO ()
freeHaskellFunPtr _ = return ()

instance Eq (Ptr a) where
  p == q = primPtrEq p q

instance Ord (Ptr a) where
  p <= q = primPtrLe p q
  compare p q | primPtrEq p q = EQ
              | primPtrLe p q = LT
              | otherwise     = GT

instance Show (Ptr a) where
  showsPrec _ p = showString (showAddress (primPtrToInteger p))

instance Eq (FunPtr a) where
  p == q = primFunPtrEq p q

instance Ord (FunPtr a) where
  p <= q = primFunPtrLe p q
  compare p q | primFunPtrEq p q = EQ
              | primFunPtrLe p q = LT
              | otherwise        = GT

instance Show (FunPtr a) where
  showsPrec _ p = showString (showAddress (primFunPtrToInteger p))

-- 0x followed by 16 hex digits, as GHC shows pointers
showAddress :: Integer -> String
showAddress n = "0x" ++ pad (hex n "")
  where pad s = replicate (16 - length s) '0' ++ s
        hex m rest | m < 16    = digit m : rest
                   | otherwise = hex (m `quot` 16) (digit (m `rem` 16) : rest)
        digit d = "0123456789abcdef" !! fromInteger d
