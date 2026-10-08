-- Random.hs -- the Haskell 98 Random library
--
-- Ported from Hugs's packages/base/System/Random.hs, which carries:
--
--   Module      :  System.Random
--   Copyright   :  (c) The University of Glasgow 2001
--   License     :  BSD-style (see the file libraries/base/LICENSE)
--
--   The Glasgow Haskell Compiler License
--
--   Copyright 2004, The University Court of the University of Glasgow.
--   All rights reserved.
--
--   Redistribution and use in source and binary forms, with or without
--   modification, are permitted provided that the following conditions
--   are met:
--
--   - Redistributions of source code must retain the above copyright
--   notice, this list of conditions and the following disclaimer.
--
--   - Redistributions in binary form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
--   - Neither name of the University nor the names of its contributors
--   may be used to endorse or promote products derived from this
--   software without specific prior written permission.
--
--   THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY COURT OF THE UNIVERSITY
--   OF GLASGOW AND THE CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
--   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
--   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
--   IN NO EVENT SHALL THE UNIVERSITY COURT OF THE UNIVERSITY OF GLASGOW
--   OR THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- This implementation uses the Portable Combined Generator of L'Ecuyer
-- for 32-bit computers, transliterated by Lennart Augustsson.  It has a
-- period of roughly 2.30584e18.  (P. L'Ecuyer, "Efficient and portable
-- combined random number generators", Comm ACM 31(6), Jun 1988.)
--
-- Changes for Yale Haskell:
--   * do-notation rewritten with thenIO; IORef/unsafePerformIO replaced
--     by a named global cell (RandomPrims.hi).
--   * Int has the Lisp fixnum range, so random :: Int covers more than
--     32 bits.

module Random (
        RandomGen(next, split, genRange),
        StdGen, mkStdGen,
        Random(random, randomR, randoms, randomRs, randomIO, randomRIO),
        getStdRandom, getStdGen, setStdGen, newStdGen
  ) where

import PreludeIO (thenIO, thenIO_, returnIO)
import Char (ord, chr, isDigit, isSpace)
import CPUTime (getCPUTime)
import TimePrims (primGetClockTime)
import RandomPrims

class RandomGen g where
   next     :: g -> (Int, g)
   split    :: g -> (g, g)
   genRange :: g -> (Int, Int)
   genRange g = (minBound, maxBound)

data StdGen = StdGen Int Int

instance RandomGen StdGen where
  next  = stdNext
  split = stdSplit
  genRange _ = stdRange

instance  Show StdGen  where
  showsPrec p (StdGen s1 s2) =
     showsPrec p s1 .
     showChar ' ' .
     showsPrec p s2

instance  Read StdGen  where
  readsPrec _ r =
     case try_read r of
       r@[_] -> r
       _     -> [stdFromString r] -- because it shouldn't ever fail.
    where
      try_read r = [ (StdGen s1 s2, r2) | (s1, r1) <- readDec r,
                                          (s2, r2) <- readDec r1 ]
      readDec s = case dropWhile isSpace s of
                    cs@(c:_) | isDigit c ->
                      let (ds, rest) = span isDigit cs
                      in  [(foldl (\a d -> 10 * a + ord d - ord '0') 0 ds, rest)]
                    _ -> []

{-
 If we cannot unravel the StdGen from a string, create
 one based on the string given.
-}
stdFromString         :: String -> (StdGen, String)
stdFromString s        = (mkStdGen num, rest)
        where (cs, rest) = splitAt 6 s
              num        = foldl (\a x -> x + 3 * a) 1 (map ord cs)

mkStdGen :: Int -> StdGen -- why not Integer ?
mkStdGen s
 | s < 0     = mkStdGen (-s)
 | otherwise = StdGen (s1+1) (s2+1)
      where
        (q, s1) = s `divMod` 2147483562
        s2      = q `mod` 2147483398

createStdGen :: Integer -> StdGen
createStdGen s
 | s < 0     = createStdGen (-s)
 | otherwise = StdGen (fromInteger (s1+1)) (fromInteger (s2+1))
      where
        (q, s1) = s `divMod` 2147483562
        s2      = q `mod` 2147483398

class Random a where
  randomR :: RandomGen g => (a,a) -> g -> (a,g)
  random  :: RandomGen g => g -> (a, g)

  randomRs :: RandomGen g => (a,a) -> g -> [a]
  randomRs ival g = x : randomRs ival g' where (x,g') = randomR ival g

  randoms  :: RandomGen g => g -> [a]
  randoms  g      = (\(x,g') -> x : randoms g') (random g)

  randomRIO :: (a,a) -> IO a
  randomRIO range  = getStdRandom (randomR range)

  randomIO  :: IO a
  randomIO         = getStdRandom random

instance Random Int where
  randomR (a,b) g = randomIvalInteger (toInteger a, toInteger b) g
  random g        = randomR (minBound, maxBound) g

instance Random Char where
  randomR (a,b) g =
      case (randomIvalInteger (toInteger (ord a), toInteger (ord b)) g) of
        (x,g) -> (chr x, g)
  random g        = randomR (minBound,maxBound) g

instance Random Bool where
  randomR (a,b) g =
      case (randomIvalInteger (toInteger (bool2Int a), toInteger (bool2Int b)) g) of
        (x, g) -> (int2Bool x, g)
       where
         bool2Int False = 0
         bool2Int True  = 1

         int2Bool 0     = False
         int2Bool _     = True

  random g        = randomR (False,True) g

instance Random Integer where
  randomR ival g = randomIvalInteger ival g
  random g       = randomR (toInteger (minBound :: Int), toInteger (maxBound :: Int)) g

instance Random Double where
  randomR ival g = randomIvalDouble ival id g
  random g       = randomR (0::Double,1) g

-- hah, so you thought you were saving cycles by using Float?
instance Random Float where
  random g        = randomIvalDouble (0::Double,1) realToFrac g
  randomR (a,b) g = randomIvalDouble (realToFrac a, realToFrac b) realToFrac g

mkStdRNG :: Integer -> IO StdGen
mkStdRNG o =
    getCPUTime `thenIO` \ct ->
    primGetClockTime `thenIO` \(sec, _) ->
    returnIO (createStdGen (sec * 12345 + ct + o))

randomIvalInteger :: (RandomGen g, Num a) => (Integer, Integer) -> g -> (a, g)
randomIvalInteger (l,h) rng
 | l > h     = randomIvalInteger (h,l) rng
 | otherwise = case (f n 1 rng) of (v, rng') -> (fromInteger (l + v `mod` k), rng')
     where
       k = h - l + 1
       b = 2147483561
       n = iLogBase b k

       f 0 acc g = (acc, g)
       f n acc g =
          let
           (x,g')   = next g
          in
          f (n-1) (fromIntegral x + acc * b) g'

randomIvalDouble :: (RandomGen g, Fractional a) => (Double, Double) -> (Double -> a) -> g -> (a, g)
randomIvalDouble (l,h) fromDouble rng
  | l > h     = randomIvalDouble (h,l) fromDouble rng
  | otherwise =
       case (randomIvalInteger (toInteger (minBound :: Int), toInteger (maxBound :: Int)) rng) of
         (x, rng') ->
            let
             scaled_x =
                fromDouble ((l+h)/2) +
                fromDouble ((h-l) / fromIntegral intRange) *
                fromIntegral (x::Int)
            in
            (scaled_x, rng')

intRange :: Integer
intRange  = toInteger (maxBound :: Int) - toInteger (minBound :: Int)

iLogBase :: Integer -> Integer -> Integer
iLogBase b i = if i < b then 1 else 1 + iLogBase b (i `div` b)

stdRange :: (Int,Int)
stdRange = (0, 2147483562)

stdNext :: StdGen -> (Int, StdGen)
-- Returns values in the range stdRange
stdNext (StdGen s1 s2) = (z', StdGen s1'' s2'')
        where   z'   = if z < 1 then z + 2147483562 else z
                z    = s1'' - s2''

                k    = s1 `quot` 53668
                s1'  = 40014 * (s1 - k * 53668) - k * 12211
                s1'' = if s1' < 0 then s1' + 2147483563 else s1'

                k'   = s2 `quot` 52774
                s2'  = 40692 * (s2 - k' * 52774) - k' * 3791
                s2'' = if s2' < 0 then s2' + 2147483399 else s2'

stdSplit            :: StdGen -> (StdGen, StdGen)
stdSplit std@(StdGen s1 s2)
                     = (left, right)
                       where
                        -- no statistical foundation for this!
                        left    = StdGen new_s1 t2
                        right   = StdGen t1 new_s2

                        new_s1 | s1 == 2147483562 = 1
                               | otherwise        = s1 + 1

                        new_s2 | s2 == 1          = 2147483398
                               | otherwise        = s2 - 1

                        StdGen t1 t2 = snd (next std)

-- The global random number generator, initialised from the clock on
-- first use.

theStdGen :: Ref StdGen
theStdGen  = primNamedRef "Random.theStdGen"

setStdGen :: StdGen -> IO ()
setStdGen sgen = primWriteRef theStdGen sgen

getStdGen :: IO StdGen
getStdGen  = primRefIsEmpty theStdGen `thenIO` \empty ->
             if empty
               then mkStdRNG 0 `thenIO` \rng ->
                    setStdGen rng `thenIO_`
                    returnIO rng
               else primReadRef theStdGen

newStdGen :: IO StdGen
newStdGen =
  getStdGen `thenIO` \rng ->
  let (a,b) = split rng in
  setStdGen a `thenIO_`
  returnIO b

getStdRandom :: (StdGen -> (a,StdGen)) -> IO a
getStdRandom f =
   getStdGen `thenIO` \rng ->
   let (v, new_rng) = f rng in
   setStdGen new_rng `thenIO_`
   returnIO v
