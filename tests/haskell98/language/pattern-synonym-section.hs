{-# LANGUAGE PatternSynonyms, ViewPatterns #-}
data NE a = NE a [a] deriving Show
pattern (:<||) :: a -> [a] -> NE a
pattern x :<|| xs = NE x xs
infixr 5 :<||

main :: IO ()
main = do
  print ((:<|| [2, 3]) 1)
  print (fmap (:<|| []) [4, 5 :: Int])
  print ((7 :<||) [8 :: Int])
