-- GRIN speculation (doc/EVAL-APPLY-GRIN.md, P5): cheap suspended
-- arithmetic is computed early only when its inputs are evaluated, so
-- an undefined input is never forced and results are unchanged.

pick :: Bool -> Int -> Int
pick b x = let y = x + 1 in if b then y else 0

orbit :: Int -> Double -> Double -> (Double, Double)
orbit 0 x v = (x, v)
orbit n x v = orbit (n - 1) x' v'
  where v' = v - 0.01 * x
        x' = x + 0.01 * v'

sumTo :: Int -> Int -> Int
sumTo 0 acc = acc
sumTo n acc = sumTo (n - 1) (acc + n)

inf :: Double
inf = 1 / 0

main :: IO ()
main = do
  print (pick False undefined)
  print (pick True 41)
  print (orbit 1000 1 0)
  print (sumTo 100000 0)
  print (inf, let z = 0 :: Double in 1 / z)
