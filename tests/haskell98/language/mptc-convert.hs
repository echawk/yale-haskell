-- A multi-parameter class without functional dependencies: instances by
-- both types, instance contexts, a constraint with a concrete type.
module Main where

class Convert a b where
  convert :: a -> b

instance Convert Int Integer where
  convert = toInteger
instance Convert Int String where
  convert = show
instance Convert a b => Convert [a] [b] where
  convert = map convert
instance Convert a b => Convert (Maybe a) [b] where
  convert Nothing = []
  convert (Just x) = [convert x]
instance Convert Bool Int where
  convert b = if b then 1 else 0

viaInt :: (Convert Int b) => Bool -> b
viaInt x = convert (convert x :: Int)

main :: IO ()
main = do
  print (convert (3 :: Int) :: Integer)
  putStrLn (convert (42 :: Int))
  print (convert [1, 2 :: Int] :: [Integer])
  print (convert (Just True) :: [Int])
  print (viaInt True :: Integer, viaInt False :: String)
