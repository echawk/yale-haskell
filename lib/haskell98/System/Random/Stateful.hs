{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, FlexibleContexts #-}
-- System.Random.Stateful (random 1.2): monadic generators and the
-- Uniform and UniformRange classes.  A pure generator (the Haskell 98
-- Random library's RandomGen) is used through StateGenM in a StateT;
-- its 64-bit words are made from several calls of next.
module System.Random.Stateful (
    StatefulGen(..), Uniform(..), UniformRange(..),
    StateGenM(..), runStateGen, runStateGen_, runStateGenT, runStateGenT_,
    genWord64, genWord32, uniformDouble01M, uniformFloat01M,
    RandomGen(..), StdGen, mkStdGen
  ) where

import Random (RandomGen(..), StdGen, mkStdGen)
import Data.Word (Word, Word8, Word16, Word32, Word64)
import Data.Int (Int8, Int16, Int32, Int64)
import Data.Char (chr, ord)
import Control.Monad.Trans.State.Strict (StateT(StateT), State, runState, runStateT)
import Data.Functor.Identity (Identity)

-- | 64 random bits from a pure generator: next's results in base
-- (hi - lo + 1), enough of them for 64 bits.
genWord64 :: RandomGen g => g -> (Word64, g)
genWord64 g0 = go (4 :: Int) 0 g0
  where
    (lo, hi) = genRange g0
    base = toInteger hi - toInteger lo + 1
    go 0 acc g = (fromInteger (acc `mod` 18446744073709551616), g)
    go k acc g = case next g of
                   (v, g') -> go (k - 1) (acc * base + (toInteger v - toInteger lo)) g'

genWord32 :: RandomGen g => g -> (Word32, g)
genWord32 g = case genWord64 g of (w, g') -> (fromIntegral w, g')

class Monad m => StatefulGen g m where
  uniformWord64 :: g -> m Word64
  uniformWord32 :: g -> m Word32
  uniformWord32 g = fmap fromIntegral (uniformWord64 g)
  uniformWord16 :: g -> m Word16
  uniformWord16 g = fmap fromIntegral (uniformWord64 g)
  uniformWord8 :: g -> m Word8
  uniformWord8 g = fmap fromIntegral (uniformWord64 g)

-- | The pure generator in the state of a StateT.
data StateGenM g = StateGenM

instance (RandomGen g, Monad m) => StatefulGen (StateGenM g) (StateT g m) where
  uniformWord64 _ = StateT (\g -> return (genWord64 g))

runStateGen :: RandomGen g => g -> (StateGenM g -> State g a) -> (a, g)
runStateGen g f = runState (f StateGenM) g

runStateGen_ :: RandomGen g => g -> (StateGenM g -> State g a) -> a
runStateGen_ g f = fst (runStateGen g f)

runStateGenT :: (RandomGen g, Monad m) => g -> (StateGenM g -> StateT g m a) -> m (a, g)
runStateGenT g f = runStateT (f StateGenM) g

runStateGenT_ :: (RandomGen g, Monad m) => g -> (StateGenM g -> StateT g m a) -> m a
runStateGenT_ g f = fmap fst (runStateGenT g f)

-- | A uniformly distributed value of the whole type.
class Uniform a where
  uniformM :: StatefulGen g m => g -> m a

-- | A uniformly distributed value in a closed range (in either order).
class UniformRange a where
  uniformRM :: StatefulGen g m => (a, a) -> g -> m a

-- A value in [0, n) from enough 64-bit words.
uniformBelow :: StatefulGen g m => Integer -> g -> m Integer
uniformBelow n g
  | n <= 1 = return 0
  | otherwise = go (words64 n) 0
  where
    words64 k = if k <= 18446744073709551616 then 2 else 1 + words64 (k `div` 18446744073709551616)
    go (0 :: Int) acc = return (acc `mod` n)
    go k acc = do w <- uniformWord64 g
                  go (k - 1) (acc * 18446744073709551616 + toInteger w)

integralRM :: (StatefulGen g m, Integral a) => (a, a) -> g -> m a
integralRM (a, b) g = do
  let lo = min (toInteger a) (toInteger b)
      hi = max (toInteger a) (toInteger b)
  r <- uniformBelow (hi - lo + 1) g
  return (fromInteger (lo + r))

boundedM :: (StatefulGen g m, Integral a, Bounded a) => g -> m a
boundedM = integralRM (minBound, maxBound)

instance Uniform Word64 where uniformM = uniformWord64
instance Uniform Word32 where uniformM = uniformWord32
instance Uniform Word16 where uniformM = uniformWord16
instance Uniform Word8 where uniformM = uniformWord8
instance Uniform Word where uniformM = boundedM
instance Uniform Int where uniformM = boundedM
instance Uniform Int8 where uniformM = boundedM
instance Uniform Int16 where uniformM = boundedM
instance Uniform Int32 where uniformM = boundedM
instance Uniform Int64 where uniformM = boundedM
instance Uniform Bool where uniformM g = fmap odd (uniformWord8 g)
instance Uniform () where uniformM _ = return ()
instance Uniform Char where uniformM = uniformRM (minBound, maxBound)
instance (Uniform a, Uniform b) => Uniform (a, b) where
  uniformM g = do { a <- uniformM g; b <- uniformM g; return (a, b) }

instance UniformRange Integer where uniformRM = integralRM
instance UniformRange Int where uniformRM = integralRM
instance UniformRange Int8 where uniformRM = integralRM
instance UniformRange Int16 where uniformRM = integralRM
instance UniformRange Int32 where uniformRM = integralRM
instance UniformRange Int64 where uniformRM = integralRM
instance UniformRange Word where uniformRM = integralRM
instance UniformRange Word8 where uniformRM = integralRM
instance UniformRange Word16 where uniformRM = integralRM
instance UniformRange Word32 where uniformRM = integralRM
instance UniformRange Word64 where uniformRM = integralRM
instance UniformRange Bool where
  uniformRM (a, b) g = fmap toEnum (integralRM (fromEnum a, fromEnum b) g)
-- | Not a surrogate (as random's).
instance UniformRange Char where
  uniformRM (a, b) g = do
    i <- integralRM (ord a, ord b) g
    return (chr (if i >= 0xD800 && i <= 0xDFFF then i - 0x800 else i))
instance UniformRange Double where
  uniformRM (a, b) g = do { d <- uniformDouble01M g; return (a + d * (b - a)) }
instance UniformRange Float where
  uniformRM (a, b) g = do { d <- uniformFloat01M g; return (a + d * (b - a)) }

-- | In [0, 1].
uniformDouble01M :: StatefulGen g m => g -> m Double
uniformDouble01M g = do
  w <- uniformWord64 g
  return (fromIntegral (w `div` 2048) / 9007199254740991)

uniformFloat01M :: StatefulGen g m => g -> m Float
uniformFloat01M g = fmap realToFrac (uniformDouble01M g)
