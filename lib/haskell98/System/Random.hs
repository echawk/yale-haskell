-- System.Random (random 1.2): the Haskell 98 Random library, and
-- uniform and uniformR by the Uniform classes (System.Random.Stateful).
module System.Random (
    module Random, Uniform, UniformRange, uniform, uniformR, genWord64, genWord32
  ) where

import Random
import System.Random.Stateful (Uniform(uniformM), UniformRange(uniformRM),
                               runStateGen, genWord64, genWord32)

uniform :: (RandomGen g, Uniform a) => g -> (a, g)
uniform g = runStateGen g uniformM

uniformR :: (RandomGen g, UniformRange a) => (a, a) -> g -> (a, g)
uniformR r g = runStateGen g (uniformRM r)
