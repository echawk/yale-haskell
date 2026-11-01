{-# LANGUAGE NamedDefaults #-}
class C a where c :: a -> String
instance C Int where c _ = "int"
instance C Bool where c _ = "bool"
instance C Integer where c _ = "integer"

default C (Bool)

main :: IO ()
main = do
  putStrLn (c (3 :: Int))
  putStrLn (c (3 :: Integer))
  putStrLn (c undefined)
