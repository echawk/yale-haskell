-- reify of a class of the module running the splice: its superclass,
-- methods (as their signatures give them) and the module's instances.
{-# LANGUAGE TemplateHaskell #-}
module Main where
import Language.Haskell.TH

class Show a => Pretty a where
  pretty :: a -> String
  prettyList :: [a] -> String

data T = T
instance Show T where show _ = "T"
instance Pretty T where
  pretty _ = "t"
  prettyList _ = "ts"
instance Pretty Bool where
  pretty = show
  prettyList = show

main :: IO ()
main = do
  putStrLn $(reify ''Pretty >>= stringE . show)
  putStrLn $(reify ''Pretty >>= \(ClassI _ is) -> stringE (pprint is))
  putStrLn $(reifyInstances ''Pretty [ConT ''Bool] >>= stringE . show . length)
