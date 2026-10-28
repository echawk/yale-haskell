-- Re-exports Data.Graph's SCC(..): with the pattern synonym CyclicSCC that
-- containers bundles with it (GHC's Digraph).
module ReexportBundleA (SCC(..), f) where
import Data.Graph
f :: Int
f = 1
