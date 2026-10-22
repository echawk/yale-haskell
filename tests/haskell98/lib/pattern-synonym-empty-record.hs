module Main (main) where
import qualified Data.Graph as Graph
cyclic :: Graph.SCC Int -> Bool
cyclic Graph.AcyclicSCC{} = False
cyclic Graph.CyclicSCC{} = True
main :: IO ()
main = print (map cyclic (Graph.stronglyConnComp [(1, 1, [2]), (2, 2, [1]), (3, 3, [])]))
