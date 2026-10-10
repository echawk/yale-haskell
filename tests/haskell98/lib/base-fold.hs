-- Foldable and Traversable as the modern Prelude's length, sum, mapM_, ... (base).
import qualified Data.Char as C

main :: IO ()
main = do
  print (length [1, 2, 3 :: Int], length (Just 'x'), length (Nothing :: Maybe Int))
  print (sum (Just 5 :: Maybe Int), sum [1 .. 10 :: Integer], product (Right 7 :: Either String Int))
  print (elem 3 [1, 2, 3 :: Int], notElem 'z' "abc", null (Left 1 :: Either Int Int))
  print (maximum (Just 'q'), concat (Just [1, 2 :: Int]), concatMap show [1, 2, 3 :: Int])
  mapM_ print (Just "mapM_ over Maybe")
  r <- mapM (\x -> return (x * 2)) [1, 2, 3 :: Int]
  print r
  print (traverse (\x -> if x > 0 then Just x else Nothing) [1, 2, 3 :: Int])
  print (traverse (\x -> if x > 0 then Just x else Nothing) [1, -2, 3 :: Int])
  print (sequenceA [Just 1, Just (2 :: Int)], sequence [[1, 2], [3 :: Int]])
  print (fmap (+ 1) ("pair", 1 :: Int), sum ("ignored", 4 :: Int))
  print (foldr (:) [] (Just 'a'), foldMap (\c -> [C.toUpper c]) "fold", any even [1, 3, 4 :: Int])
  print (and [], or (Just False), all C.isDigit "123")
