{-# LANGUAGE ApplicativeDo #-}
-- ApplicativeDo: independent statements ending in pure need only
-- Applicative (ZipList has no Monad)
module Main (main) where
import Control.Applicative (ZipList(..))

pairs :: Applicative f => f Int -> f Char -> f (Int, Char)
pairs xs cs = do
  x <- xs
  c <- cs
  pure $ (x, c)

main :: IO ()
main = do
  print (getZipList (pairs (ZipList [1, 2, 3]) (ZipList "ab")))
  r <- do { a <- return 1; b <- return (a + 1); return (a + b) }
  print (r :: Int)
