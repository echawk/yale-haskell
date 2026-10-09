-- Foreign.Storable: the Haskell 2010 library module (Report 2010, chapter
-- 37), for Yale Haskell's Haskell 98 dialect.  Sizes are those of a
-- 64-bit C ABI: Int is stored as a C long (8 bytes), Char and Bool as 4.
module Foreign.Storable (
    Storable(sizeOf, alignment, peekElemOff, pokeElemOff,
             peekByteOff, pokeByteOff, peek, poke)
  ) where

import Data.Int
import Data.Word
import ForeignPrims
import Foreign.Ptr

class Storable a where
  sizeOf      :: a -> Int
  alignment   :: a -> Int
  peekElemOff :: Ptr a -> Int -> IO a
  pokeElemOff :: Ptr a -> Int -> a -> IO ()
  peekByteOff :: Ptr b -> Int -> IO a
  pokeByteOff :: Ptr b -> Int -> a -> IO ()
  peek        :: Ptr a -> IO a
  poke        :: Ptr a -> a -> IO ()

  peekElemOff p i   = peekByteOff p (i * sizeOf (elementOf p))
  pokeElemOff p i x = pokeByteOff p (i * sizeOf x) x
  peekByteOff p off = peek (plusPtr p off)
  pokeByteOff p off = poke (plusPtr p off)
  peek p            = peekElemOff p 0
  poke p            = pokeElemOff p 0

elementOf :: Ptr a -> a
elementOf _ = undefined

instance Storable Int where
  sizeOf _ = 8
  alignment _ = 8
  peekByteOff = primPeekInt
  pokeByteOff = primPokeInt

instance Storable Int8 where
  sizeOf _ = 1
  alignment _ = 1
  peekByteOff = primPeekInt8
  pokeByteOff = primPokeInt8

instance Storable Int16 where
  sizeOf _ = 2
  alignment _ = 2
  peekByteOff = primPeekInt16
  pokeByteOff = primPokeInt16

instance Storable Int32 where
  sizeOf _ = 4
  alignment _ = 4
  peekByteOff = primPeekInt32
  pokeByteOff = primPokeInt32

instance Storable Int64 where
  sizeOf _ = 8
  alignment _ = 8
  peekByteOff = primPeekInt64
  pokeByteOff = primPokeInt64

instance Storable Word where
  sizeOf _ = 8
  alignment _ = 8
  peekByteOff = primPeekWord
  pokeByteOff = primPokeWord

instance Storable Word8 where
  sizeOf _ = 1
  alignment _ = 1
  peekByteOff = primPeekWord8
  pokeByteOff = primPokeWord8

instance Storable Word16 where
  sizeOf _ = 2
  alignment _ = 2
  peekByteOff = primPeekWord16
  pokeByteOff = primPokeWord16

instance Storable Word32 where
  sizeOf _ = 4
  alignment _ = 4
  peekByteOff = primPeekWord32
  pokeByteOff = primPokeWord32

instance Storable Word64 where
  sizeOf _ = 8
  alignment _ = 8
  peekByteOff = primPeekWord64
  pokeByteOff = primPokeWord64

instance Storable Double where
  sizeOf _ = 8
  alignment _ = 8
  peekByteOff = primPeekDouble
  pokeByteOff = primPokeDouble

instance Storable Float where
  sizeOf _ = 4
  alignment _ = 4
  peekByteOff = primPeekFloat
  pokeByteOff = primPokeFloat

instance Storable Char where
  sizeOf _ = 4
  alignment _ = 4
  peekByteOff = primPeekChar
  pokeByteOff = primPokeChar

instance Storable Bool where
  sizeOf _ = 4
  alignment _ = 4
  peekByteOff p off = primPeekCInt p off >>= \n -> return (n /= 0)
  pokeByteOff p off b = primPokeCInt p off (if b then 1 else 0)

instance Storable (Ptr a) where
  sizeOf _ = 8
  alignment _ = 8
  peekByteOff = primPeekPtr
  pokeByteOff = primPokePtr

instance Storable (FunPtr a) where
  sizeOf _ = 8
  alignment _ = 8
  peekByteOff = primPeekFunPtr
  pokeByteOff = primPokeFunPtr
