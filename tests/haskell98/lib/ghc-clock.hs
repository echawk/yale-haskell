import GHC.Clock
main = do
  t0 <- getMonotonicTimeNSec
  a <- getMonotonicTime
  print (sum [1 .. 200000 :: Integer])
  t1 <- getMonotonicTimeNSec
  b <- getMonotonicTime
  print (t1 >= t0, b >= a, a > 0)
