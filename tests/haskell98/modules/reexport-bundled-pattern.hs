-- A re-exported T(..) brings the pattern synonyms bundled with T.
import ReexportBundleA (SCC(..))

main :: IO ()
main = case CyclicSCC [1, 2 :: Int] of
  CyclicSCC xs -> print xs
  AcyclicSCC _ -> print 0
