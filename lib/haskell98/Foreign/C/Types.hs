-- Foreign.C.Types: the Haskell 2010 library module (Report 2010, chapter
-- 30), for Yale Haskell's Haskell 98 dialect, on a 64-bit C ABI
-- (LP64).  The Report makes these newtypes; here they are synonyms for
-- the Data.Int, Data.Word and Prelude types of the same representation,
-- which have all the required instances (and Bits for the integral ones).
-- So CInt and Int32 are the same type, which programs written for the
-- Report cannot tell apart except by giving instances for both.
module Foreign.C.Types (
    CChar, CSChar, CUChar, CShort, CUShort, CInt, CUInt, CLong, CULong,
    CPtrdiff, CSize, CWchar, CSigAtomic, CLLong, CULLong, CIntPtr,
    CUIntPtr, CIntMax, CUIntMax, CClock, CTime, CFloat, CDouble,
    CFile, CFpos, CJmpBuf
  ) where

import Data.Int
import Data.Word

type CChar      = Int8
type CSChar     = Int8
type CUChar     = Word8
type CShort     = Int16
type CUShort    = Word16
type CInt       = Int32
type CUInt      = Word32
type CLong      = Int64
type CULong     = Word64
type CPtrdiff   = Int64
type CSize      = Word64
type CWchar     = Int32
type CSigAtomic = Int32
type CLLong     = Int64
type CULLong    = Word64
type CIntPtr    = Int64
type CUIntPtr   = Word64
type CIntMax    = Int64
type CUIntMax   = Word64
type CClock     = Int64
type CTime      = Int64
type CFloat     = Float
type CDouble    = Double

-- C's FILE, fpos_t and jmp_buf, only ever used through pointers.
data CFile   = CFile
data CFpos   = CFpos
data CJmpBuf = CJmpBuf
