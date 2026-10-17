import Data.Complex
polarF :: Floating a => a -> a -> (a, a)
polarF r t = let (x :+ y) = mkPolar r t in (x, y)
main = do
  print (polarF 2 (pi / 2 :: Double))
  print (conjugate (1 :+ 2 :: Complex Int), realPart (3 :+ 4 :: Complex Integer), cis (0 :: Double))
  print (magnitude (3 :+ 4 :: Complex Double), (1 :+ 1) * (2 :+ 3 :: Complex Double))
