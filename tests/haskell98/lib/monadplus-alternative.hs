-- base: MonadPlus implies Alternative; replicateM, when, filterM, zipWithM_
-- are over Applicative.
import Control.Applicative
import Control.Monad

pairs :: MonadPlus m => m a -> m b -> m (a, b)
pairs a b = liftA2 (,) a b <|> empty

alts :: MonadPlus m => [m a] -> m a
alts = foldr (<|>) empty

main :: IO ()
main = do
  print (pairs [1, 2] "ab", pairs (Just 1) (Nothing :: Maybe Char))
  print (alts [Nothing, Just 3, Just 4], alts [[1], [2, 3]], replicateM 2 "xy")
  when True (putStrLn "when")
  r <- filterM (\x -> return (odd x)) [1 .. 6 :: Int]
  print r
  zipWithM_ (\a b -> print (a + b)) [1, 2] [10, 20 :: Int]
