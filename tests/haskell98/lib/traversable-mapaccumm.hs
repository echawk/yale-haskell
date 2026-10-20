import Data.Traversable (mapAccumM, forAccumM)
main = do
  r <- mapAccumM (\acc x -> do { print x; return (acc + x, show x) }) 0 [1, 2, 3 :: Int]
  print r
  r2 <- forAccumM 'a' (Just True) (\c b -> return (succ c, (c, b)))
  print r2
