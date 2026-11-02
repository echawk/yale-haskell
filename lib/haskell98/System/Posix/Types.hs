{-# LANGUAGE GeneralizedNewtypeDeriving, DerivingStrategies #-}
-- System.Posix.Types (base): the POSIX types, newtypes over the sized
-- integers as the Foreign.C.Types types are (doc/FFI.md); Fd is a newtype
-- over CInt as in base.
module System.Posix.Types (
    Fd(Fd), CMode(..), CDev(..), CIno(..), COff(..), CPid(..), CSsize(..), CUid(..), CGid(..), CNlink(..),
    FileMode, FileOffset, EpochTime, ProcessID, ProcessGroupID, ByteCount, DeviceID,
    FileID, UserID, GroupID, LinkCount, Limit,
    CClockId(..), CBlkSize(..), CBlkCnt(..), CFsBlkCnt(..), CFsFilCnt(..), CRLim(..), CSpeed(..),
    CTcflag(..), CCc(..), CId(..), CKey(..), CSocklen(..), CNfds(..)
  ) where

import Data.Int (Int32, Int64)
import Data.Word (Word8, Word16, Word32, Word64)
import Foreign.C.Types (CInt, CTime, CSize, CLong)
import Data.Bits (Bits, FiniteBits)
import Foreign.Storable (Storable(..))
import Foreign.Ptr (castPtr)

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

-- as its CInt (network's control messages hold descriptors)
instance Storable Fd where
  sizeOf (Fd a) = sizeOf a
  alignment (Fd a) = alignment a
  peek p = fmap Fd (peek (castPtr p))
  poke p (Fd a) = poke (castPtr p) a

instance Bounded Fd where
  minBound = Fd minBound
  maxBound = Fd maxBound

newtype CMode = CMode Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CDev = CDev Int32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CIno = CIno Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype COff = COff Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CPid = CPid Int32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CSsize = CSsize Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CUid = CUid Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CGid = CGid Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CNlink = CNlink Word16 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
-- (the sizes of macOS/arm64's C types)
newtype CClockId = CClockId Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CBlkSize = CBlkSize Int32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CBlkCnt = CBlkCnt Int64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CFsBlkCnt = CFsBlkCnt Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CFsFilCnt = CFsFilCnt Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CRLim = CRLim Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CSpeed = CSpeed Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CTcflag = CTcflag Word64 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CCc = CCc Word8 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CId = CId Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CKey = CKey Int32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CSocklen = CSocklen Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
newtype CNfds = CNfds Word32 deriving newtype (Eq, Ord, Num, Enum, Real, Integral, Bits, FiniteBits, Bounded, Storable, Show, Read)
type FileMode = CMode
type FileOffset = COff
type EpochTime = CTime
type ProcessID = CPid
type ProcessGroupID = CPid
type ByteCount = CSize
type DeviceID = CDev
type FileID = CIno
type UserID = CUid
type GroupID = CGid
type LinkCount = CNlink
-- pathconf's result (unix: CLong)
type Limit = CLong
