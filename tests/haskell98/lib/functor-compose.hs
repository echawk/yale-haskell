import Data.Functor.Compose
import Data.Functor.Product
import Data.Functor.Sum
import Data.Functor.Identity
import Control.Monad.ST.Lazy.Unsafe ()

main = do
  let c = Compose [Just 1, Nothing, Just (3 :: Int)]
  print (fmap (+1) c, sum c, length c)
  print (traverse (\x -> if x > 0 then Just x else Nothing) c)
  print (Compose (Just [1 :: Int]) == Compose (Just [1]), (,) <$> Compose [Just 'a'] <*> Compose [Just 'b'])
  print (fmap show (Pair [1, 2 :: Int] (Just 3)), sum (Pair [1, 2] (Identity (3 :: Int))))
  print (InL (Just 'x') :: Sum Maybe [] Char, fmap succ (InR "ab" :: Sum Maybe [] Char))
