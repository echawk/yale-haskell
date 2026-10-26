import Data.Bifoldable1
import Data.Functor.Contravariant
import Control.Monad.Trans.Select
import Control.Concurrent
import Data.Semigroup (Max(..))
import Data.List (sortBy)

main = do
  print (getMax (bifoldMap1 Max Max (3 :: Int, 7)), bifold1 (Left "x" :: Either String String))
  print (getPredicate (contramap length (Predicate even)) "abcd", getPredicate (Predicate even <> Predicate (> 2)) (4 :: Int))
  print (sortBy (getComparison (contramap negate defaultComparison)) [3, 1, 2 :: Int])
  print (runSelect (select (\k -> if k 'a' > k 'b' then 'a' else 'b')) fromEnum)
  d <- newEmptyMVar
  _ <- forkOSWithUnmask (\unmask -> unmask (putStrLn "forked") >> putMVar d ())
  takeMVar d
