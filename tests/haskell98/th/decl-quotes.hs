{-# LANGUAGE TemplateHaskell #-}
-- [d| |] quotes: a data type, an instance, functions and signatures,
-- spliced; a getter generator by reify.
import DeclQuoteGen
import Language.Haskell.TH

data Person = Person { name :: String, age :: Int }

colours

mkGetters ''Person

main :: IO ()
main = do
  print (map next [Red, Green, Blue])
  print (Red <> Red, Red <> Blue)
  let p = Person "Ada" 36
  putStrLn (getname p)
  print (getage p)
  ds <- runQ [d| f :: Int -> Int; f x = x + 1 |]
  putStrLn (pprint ds)
