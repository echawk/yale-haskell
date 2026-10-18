{-# LANGUAGE GeneralizedNewtypeDeriving, DerivingStrategies #-}
-- Foreign.C.Types: the Haskell 2010 library module (Report 2010, chapter
-- 30), on a 64-bit C ABI (LP64).  As the Report and base have them, each
-- is a newtype over the Data.Int, Data.Word or Prelude type of the same
-- representation, its instances that type's (shown as the number), so a
-- program may give instances for CInt and Int32 both.  The FFI passes
-- them as the underlying type (backend/interface-codegen.mumble).
module Foreign.C.Types (
    CChar, CSChar, CUChar, CShort, CUShort, CInt, CUInt, CLong, CULong, CPtrdiff, CSize, CWchar, CSigAtomic, CLLong, CULLong, CBool, CIntPtr, CUIntPtr, CIntMax, CUIntMax, CClock, CTime, CUSeconds, CSUSeconds, CFloat, CDouble,
    CFile, CFpos, CJmpBuf
  ) where

import Data.Int
import Data.Word
import Data.Bits (Bits, FiniteBits)
import Foreign.Storable (Storable)

newtype CChar = CChar Int8 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CSChar = CSChar Int8 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CUChar = CUChar Word8 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CShort = CShort Int16 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CUShort = CUShort Word16 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CInt = CInt Int32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CUInt = CUInt Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CLong = CLong Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CULong = CULong Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CPtrdiff = CPtrdiff Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CSize = CSize Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CWchar = CWchar Int32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CSigAtomic = CSigAtomic Int32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CLLong = CLLong Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CULLong = CULLong Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CBool = CBool Word8 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CIntPtr = CIntPtr Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CUIntPtr = CUIntPtr Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CIntMax = CIntMax Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CUIntMax = CUIntMax Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CClock = CClock Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Storable, Show, Read)
newtype CTime = CTime Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Storable, Show, Read)
newtype CUSeconds = CUSeconds Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Storable, Show, Read)
newtype CSUSeconds = CSUSeconds Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Storable, Show, Read)
newtype CFloat = CFloat Float deriving newtype (Eq, Ord, Num, Enum, Real, Fractional, Floating, RealFrac, RealFloat, Storable, Show, Read)
newtype CDouble = CDouble Double deriving newtype (Eq, Ord, Num, Enum, Real, Fractional, Floating, RealFrac, RealFloat, Storable, Show, Read)

-- C's FILE, fpos_t and jmp_buf, only ever used through pointers.
data CFile   = CFile
data CFpos   = CFpos
data CJmpBuf = CJmpBuf
