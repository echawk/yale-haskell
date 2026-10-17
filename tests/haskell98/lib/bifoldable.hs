import Data.Bifoldable
import Data.Bitraversable
import Data.Bifunctor

main = do
  print (biList (1 :: Int, 2), bisum (Left 3 :: Either Int Int), bilength ((), 'a'))
  print (bifoldMap show (: []) (5 :: Int, 'x'), bifoldl (flip (:)) (flip (:)) [] (1 :: Int, 2))
  print (bitraverse Just Just (1 :: Int, 'c'), bisequenceA (Right (Just 'z') :: Either (Maybe Int) (Maybe Char)))
  print (bimapDefault (+1) not (1 :: Int, True), biany even odd (2 :: Int, 3 :: Int))
  bitraverse_ print print (Left "left" :: Either String Int)
