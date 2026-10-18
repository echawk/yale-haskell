import Control.Applicative
main = do
  print (getZipList ((+) <$> ZipList [1, 2, 3] <*> ZipList [10, 20 :: Int]))
  print (getZipList (liftA2 (,) (ZipList "ab") (pure 'z')), sum (ZipList [1, 2, 3 :: Int]))
  print (getZipList (ZipList [1] <|> ZipList [7, 8, 9 :: Int]), asum [Nothing, Just 'x', Just 'y'])
  print (unwrapArrow ((+) <$> WrapArrow (* 2) <*> WrapArrow (+ 1)) (5 :: Int))
