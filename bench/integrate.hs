module Main where

-- Simpson-rule integration of sin(x)*exp(-x/4) plus an Euler orbit loop.
f :: Double -> Double
f x = sin x * exp (negate x / 4)

simpson :: Int -> Double -> Double -> Double
simpson n a b = (h / 3) * go 0 0
  where
    h = (b - a) / fromIntegral n
    go :: Int -> Double -> Double
    go i acc
      | i > n = acc
      | otherwise = go (i + 1) (acc + w i * f (a + fromIntegral i * h))
    w i | i == 0 || i == n = 1
        | odd i = 4
        | otherwise = 2

orbit :: Int -> Double -> Double -> Double -> Double -> (Double, Double)
orbit 0 x y _ _ = (x, y)
orbit n x y vx vy = orbit (n - 1) x' y' vx' vy'
  where
    dt = 0.001
    r = sqrt (x * x + y * y)
    r3 = r * r * r
    vx' = vx - dt * x / r3
    vy' = vy - dt * y / r3
    x' = x + dt * vx'
    y' = y + dt * vy'

round6 :: Double -> Integer
round6 d = round (d * 1000000)

main :: IO ()
main = do
  print (round6 (simpson 400000 0 20))
  case orbit 400000 1 0 0 1 of
    (x, y) -> print (round6 x, round6 y)
