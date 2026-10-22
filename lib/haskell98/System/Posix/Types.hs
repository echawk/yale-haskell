-- System.Posix.Types (base): the POSIX types, as the type synonyms the
-- Foreign.C.Types types are here (doc/FFI.md), except Fd, a newtype over
-- CInt as in base.
module System.Posix.Types (
    Fd(Fd), CMode, CDev, CIno, COff, CPid, CSsize, CUid, CGid, CNlink,
    FileMode, FileOffset, EpochTime, ProcessID, ByteCount, DeviceID,
    FileID, UserID, GroupID, LinkCount, Limit,
    CClockId, CBlkSize, CBlkCnt, CFsBlkCnt, CFsFilCnt, CRLim, CSpeed,
    CTcflag, CCc, CId, CKey, CSocklen, CNfds
  ) where

import Data.Int (Int32, Int64)
import Data.Word (Word8, Word16, Word32, Word64)
import Foreign.C.Types (CInt)

newtype Fd = Fd CInt deriving (Eq, Ord)

instance Show Fd where
  showsPrec d (Fd n) = showsPrec d n

instance Num Fd where
  Fd a + Fd b = Fd (a + b)
  Fd a - Fd b = Fd (a - b)
  Fd a * Fd b = Fd (a * b)
  abs (Fd a) = Fd (abs a)
  signum (Fd a) = Fd (signum a)
  fromInteger n = Fd (fromInteger n)

instance Real Fd where
  toRational (Fd a) = toRational a

instance Enum Fd where
  toEnum n = Fd (toEnum n)
  fromEnum (Fd a) = fromEnum a

instance Integral Fd where
  quotRem (Fd a) (Fd b) = let (q, r) = quotRem a b in (Fd q, Fd r)
  toInteger (Fd a) = toInteger a

type CMode = Word32
type CDev = Int32
type CIno = Word64
type COff = Int64
type CPid = Int32
type CSsize = Int64
type CUid = Word32
type CGid = Word32
type CNlink = Word16
-- (the sizes of macOS/arm64's C types)
type CClockId = Word32
type CBlkSize = Int32
type CBlkCnt = Int64
type CFsBlkCnt = Word32
type CFsFilCnt = Word32
type CRLim = Word64
type CSpeed = Word64
type CTcflag = Word64
type CCc = Word8
type CId = Word32
type CKey = Int32
type CSocklen = Word32
type CNfds = Word32
type FileMode = CMode
type FileOffset = COff
type EpochTime = Int64
type ProcessID = CPid
type ByteCount = Word64
type DeviceID = CDev
type FileID = CIno
type UserID = CUid
type GroupID = CGid
type LinkCount = CNlink
-- pathconf's result (unix: CLong)
type Limit = Int64
