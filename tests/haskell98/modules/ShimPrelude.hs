-- Helper for prelude-shim.hs: containers' Utils.Containers.Internal.Prelude,
-- a module re-exporting the Prelude and a class imported with some methods.
module ShimPrelude (module Prelude, Foldable (..)) where
import Prelude hiding (Foldable(..))
import Data.Foldable (Foldable(elem, foldMap, foldr, foldl, null, length, sum))
