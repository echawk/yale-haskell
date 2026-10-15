-- Data.Graph (containers), checked against GHC 9.14's output.
import Data.Graph
import Data.Array
import Data.Tree (flatten)

main :: IO ()
main = do
  let es = [("a", 1, [2, 3]), ("b", 2, [1]), ("c", 3, [4]), ("d", 4, []), ("e", 5, [5])]
  print (stronglyConnComp es)
  print (map flattenSCC (stronglyConnCompR es))
  let g = buildG (0, 5) [(0,1),(1,2),(2,0),(3,4),(4,5),(1,3)]
  print (topSort (buildG (0,4) [(0,1),(1,2),(3,2),(4,0)]))
  print (reverseTopSort (buildG (0,4) [(0,1),(1,2),(3,2),(4,0)]))
  print (map flatten (scc g))
  print (map flatten (components g))
  print (map flatten (dff g))
  print (reachable g 3, path g 0 5, path g 5 0)
  print (edges g, vertices g)
  print (indegree g, outdegree g)
  print (transposeG g)
  print (map flatten (bcc (buildG (0,4) [(0,1),(1,0),(1,2),(2,1),(2,0),(0,2),(2,3),(3,2),(3,4),(4,3)])))
  let (gr, nodeFrom, vertexFrom) = graphFromEdges es
  print (map (\v -> let (n, _, _) = nodeFrom v in n) (topSort gr), fmap (+1) (vertexFrom 3))
  print (fmap (*2) (CyclicSCC [1,2]), sum (CyclicSCC [1,2,3]), AcyclicSCC 'x' == AcyclicSCC 'x')
