-- System.Random (random): Haskell 98's Random (the Report's generator,
-- not random-1.2's SplitMix, so the numbers differ from GHC's).
module System.Random (module Random, uniform, uniformR) where

import Random

uniform :: (RandomGen g, Random a) => g -> (a, g)
uniform = random

uniformR :: (RandomGen g, Random a) => (a, a) -> g -> (a, g)
uniformR = randomR
