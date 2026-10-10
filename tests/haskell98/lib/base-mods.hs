-- Data.Monoid, Data.Ord, Data.Either, Data.Tuple, Data.Functor, Data.Bifunctor, Data.Foldable, Data.Traversable (base).
import Data.List (sortBy, foldl')
import Data.Ord (comparing, Down(..))
import Data.Monoid
import Data.Either
import Data.Tuple (swap)
import Data.Functor ((<&>), ($>), void)
import Data.Bifunctor
import Data.Foldable (toList, for_, traverse_, foldrM, find, maximumBy)
import Data.Traversable (for, mapAccumL, mapAccumR)
import Control.Monad (forM_, when)

main :: IO ()
main = do
  print (sortBy (comparing negate) [3, 1, 2 :: Int], sortBy (comparing Down) "hello")
  print (getSum (foldMap Sum [1 .. 10 :: Int]), getProduct (foldMap Product [1 .. 5 :: Int]))
  print (getAll (foldMap (All . even) [2, 4 :: Int]), getAny (foldMap (Any . odd) [2, 4 :: Int]))
  print (getFirst (First (Just 1) <> First Nothing <> First (Just (3 :: Int))), getLast (Last (Just 'a') <> Last (Just 'b')))
  print (appEndo (Endo (+ 1) <> Endo (* 2)) (5 :: Int), mconcat ["ab", "cd"])
  print (partitionEithers [Left 'a', Right 1, Left 'b', Right (2 :: Int)], lefts [Left 1, Right 'x', Left (2 :: Int)])
  print (swap (1 :: Int, "x"), bimap length show ("abc", 4 :: Int), first not (True, 'k'), second (+ 1) (Left 3 :: Either Int Int))
  print (Just 4 <&> (* 2), Just 'x' $> "y", toList (Just 'z'), find (> 2) [1, 5, 3 :: Int])
  for_ [1, 2 :: Int] print
  traverse_ print (Right "traverse_" :: Either Int String)
  r <- foldrM (\x acc -> return (x + acc)) 0 [1, 2, 3 :: Int]
  print (r, maximumBy (comparing snd) [(1, 'a'), (2, 'z'), (3 :: Int, 'c')], foldl' (+) 0 [1 .. 100 :: Int])
  xs <- for [1, 2, 3 :: Int] (\x -> return (x * x))
  print (xs, mapAccumL (\acc x -> (acc + x, acc * x)) 0 [1, 2, 3 :: Int], mapAccumR (\acc x -> (acc + x, acc)) 0 [1, 2, 3 :: Int])
  forM_ (Just "forM_ over Maybe") putStrLn
  void (return (3 :: Int))
  when (length "abc" == 3) (putStrLn "done")
