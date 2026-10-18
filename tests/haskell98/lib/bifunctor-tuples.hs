-- Bifunctor, Bifoldable and Bitraversable for tuples up to 7, as base's
import Data.Bifunctor
import Data.Bifoldable
import Data.Bitraversable
main :: IO ()
main = do
  print (bimap (+1) show (1,2,3,4,5 :: Int), bimap not succ ('a','b','c','d','e',True,'x'))
  print (bifoldMap show show (1,2,3,4,5,6 :: Int, 'q'))
  print (bitraverse Just Just (1,2,3,4,5 :: Int))
