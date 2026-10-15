-- Numeric.Natural and Data.Functor.Const (base).
import Numeric.Natural
import Control.Applicative (Const(..))
import Control.Exception
import Data.Foldable (toList)

main :: IO ()
main = do
  let n = 5 :: Natural
  print (n + 3, n * 4, n - 2, toInteger n, [n .. 8], fromIntegral (2 ^ 70 :: Integer) :: Natural)
  print (minusNaturalMaybe 3 5, minusNaturalMaybe 5 3, quotRem (17 :: Natural) 5)
  r <- try (evaluate (n - 9)) :: IO (Either ArithException Natural)
  print r
  print (getConst (traverse (\x -> Const [x]) [1, 2, 3 :: Int]), fmap (+ 1) (Const "a" :: Const String Int))
  print (toList (Const 1 :: Const Int Char), Const [1] <> Const [2 :: Int])
