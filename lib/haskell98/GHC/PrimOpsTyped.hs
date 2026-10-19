{-# LANGUAGE MagicHash #-}
-- GHC.PrimOpsTyped: the primops of GHC.PrimOps whose types have Word,
-- at that type (an interface cannot name Data.Word's Word; the
-- primitives are declared there at any type, yale_NAME).
module GHC.PrimOpsTyped (
    indexWordArray#, readWordArray#, writeWordArray#, indexWordOffAddr#, readWordOffAddr#, writeWordOffAddr#, primSetWordArray#, primSetWordOffAddr#, indexWord8Array#, readWord8Array#, writeWord8Array#, indexWord8OffAddr#, readWord8OffAddr#, writeWord8OffAddr#, primSetWord8Array#, primSetWord8OffAddr#, indexWord16Array#, readWord16Array#, writeWord16Array#, indexWord16OffAddr#, readWord16OffAddr#, writeWord16OffAddr#, primSetWord16Array#, primSetWord16OffAddr#, indexWord32Array#, readWord32Array#, writeWord32Array#, indexWord32OffAddr#, readWord32OffAddr#, writeWord32OffAddr#, primSetWord32Array#, primSetWord32OffAddr#, indexWord64Array#, readWord64Array#, writeWord64Array#, indexWord64OffAddr#, readWord64OffAddr#, writeWord64OffAddr#, primSetWord64Array#, primSetWord64OffAddr#
  ) where

import Data.Word (Word)
import GHC.PrimOps

indexWordArray# :: ByteArray# -> Int -> Word
indexWordArray# = yale_indexWordArray#
readWordArray# :: MutableByteArray# s -> Int -> State# s -> (State# s, Word)
readWordArray# = yale_readWordArray#
writeWordArray# :: MutableByteArray# s -> Int -> Word -> State# s -> State# s
writeWordArray# = yale_writeWordArray#
indexWordOffAddr# :: Addr# -> Int -> Word
indexWordOffAddr# = yale_indexWordOffAddr#
readWordOffAddr# :: Addr# -> Int -> State# s -> (State# s, Word)
readWordOffAddr# = yale_readWordOffAddr#
writeWordOffAddr# :: Addr# -> Int -> Word -> State# s -> State# s
writeWordOffAddr# = yale_writeWordOffAddr#
primSetWordArray# :: MutableByteArray# s -> Int -> Int -> Word -> State# s -> State# s
primSetWordArray# = yale_primSetWordArray#
primSetWordOffAddr# :: Addr# -> Int -> Int -> Word -> State# s -> State# s
primSetWordOffAddr# = yale_primSetWordOffAddr#
indexWord8Array# :: ByteArray# -> Int -> Word
indexWord8Array# = yale_indexWord8Array#
readWord8Array# :: MutableByteArray# s -> Int -> State# s -> (State# s, Word)
readWord8Array# = yale_readWord8Array#
writeWord8Array# :: MutableByteArray# s -> Int -> Word -> State# s -> State# s
writeWord8Array# = yale_writeWord8Array#
indexWord8OffAddr# :: Addr# -> Int -> Word
indexWord8OffAddr# = yale_indexWord8OffAddr#
readWord8OffAddr# :: Addr# -> Int -> State# s -> (State# s, Word)
readWord8OffAddr# = yale_readWord8OffAddr#
writeWord8OffAddr# :: Addr# -> Int -> Word -> State# s -> State# s
writeWord8OffAddr# = yale_writeWord8OffAddr#
primSetWord8Array# :: MutableByteArray# s -> Int -> Int -> Word -> State# s -> State# s
primSetWord8Array# = yale_primSetWord8Array#
primSetWord8OffAddr# :: Addr# -> Int -> Int -> Word -> State# s -> State# s
primSetWord8OffAddr# = yale_primSetWord8OffAddr#
indexWord16Array# :: ByteArray# -> Int -> Word
indexWord16Array# = yale_indexWord16Array#
readWord16Array# :: MutableByteArray# s -> Int -> State# s -> (State# s, Word)
readWord16Array# = yale_readWord16Array#
writeWord16Array# :: MutableByteArray# s -> Int -> Word -> State# s -> State# s
writeWord16Array# = yale_writeWord16Array#
indexWord16OffAddr# :: Addr# -> Int -> Word
indexWord16OffAddr# = yale_indexWord16OffAddr#
readWord16OffAddr# :: Addr# -> Int -> State# s -> (State# s, Word)
readWord16OffAddr# = yale_readWord16OffAddr#
writeWord16OffAddr# :: Addr# -> Int -> Word -> State# s -> State# s
writeWord16OffAddr# = yale_writeWord16OffAddr#
primSetWord16Array# :: MutableByteArray# s -> Int -> Int -> Word -> State# s -> State# s
primSetWord16Array# = yale_primSetWord16Array#
primSetWord16OffAddr# :: Addr# -> Int -> Int -> Word -> State# s -> State# s
primSetWord16OffAddr# = yale_primSetWord16OffAddr#
indexWord32Array# :: ByteArray# -> Int -> Word
indexWord32Array# = yale_indexWord32Array#
readWord32Array# :: MutableByteArray# s -> Int -> State# s -> (State# s, Word)
readWord32Array# = yale_readWord32Array#
writeWord32Array# :: MutableByteArray# s -> Int -> Word -> State# s -> State# s
writeWord32Array# = yale_writeWord32Array#
indexWord32OffAddr# :: Addr# -> Int -> Word
indexWord32OffAddr# = yale_indexWord32OffAddr#
readWord32OffAddr# :: Addr# -> Int -> State# s -> (State# s, Word)
readWord32OffAddr# = yale_readWord32OffAddr#
writeWord32OffAddr# :: Addr# -> Int -> Word -> State# s -> State# s
writeWord32OffAddr# = yale_writeWord32OffAddr#
primSetWord32Array# :: MutableByteArray# s -> Int -> Int -> Word -> State# s -> State# s
primSetWord32Array# = yale_primSetWord32Array#
primSetWord32OffAddr# :: Addr# -> Int -> Int -> Word -> State# s -> State# s
primSetWord32OffAddr# = yale_primSetWord32OffAddr#
indexWord64Array# :: ByteArray# -> Int -> Word
indexWord64Array# = yale_indexWord64Array#
readWord64Array# :: MutableByteArray# s -> Int -> State# s -> (State# s, Word)
readWord64Array# = yale_readWord64Array#
writeWord64Array# :: MutableByteArray# s -> Int -> Word -> State# s -> State# s
writeWord64Array# = yale_writeWord64Array#
indexWord64OffAddr# :: Addr# -> Int -> Word
indexWord64OffAddr# = yale_indexWord64OffAddr#
readWord64OffAddr# :: Addr# -> Int -> State# s -> (State# s, Word)
readWord64OffAddr# = yale_readWord64OffAddr#
writeWord64OffAddr# :: Addr# -> Int -> Word -> State# s -> State# s
writeWord64OffAddr# = yale_writeWord64OffAddr#
primSetWord64Array# :: MutableByteArray# s -> Int -> Int -> Word -> State# s -> State# s
primSetWord64Array# = yale_primSetWord64Array#
primSetWord64OffAddr# :: Addr# -> Int -> Int -> Word -> State# s -> State# s
primSetWord64OffAddr# = yale_primSetWord64OffAddr#
