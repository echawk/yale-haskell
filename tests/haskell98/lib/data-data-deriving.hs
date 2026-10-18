{-# LANGUAGE DeriveDataTypeable #-}
-- deriving Data: constructors, fields, fixity, gunfold, gmapT
import Data.Data
data T a = A { fa :: Int, fb :: a } | a :+: Int | N deriving (Show, Data)
data E = X | Y deriving (Show, Eq, Data)
newtype W = W [E] deriving (Show, Data)
main :: IO ()
main = do
  print (dataTypeOf (N :: T Int))
  print (map constrFields (dataTypeConstrs (dataTypeOf (N :: T Int))), map constrFixity (dataTypeConstrs (dataTypeOf (N :: T Int))))
  print (toConstr (3 :+: 4 :: T Int), gmapQ (\d -> show (toConstr d)) (A 1 'x'))
  print (fromConstrB (fromConstr (toConstr (0 :: Int))) (toConstr (A 1 (2 :: Int))) :: T Int)
  print (gmapT (\d -> case cast d of Just e -> maybe d id (cast (if e == X then Y else X)); Nothing -> d) (W [X, Y]))
  print (dataTypeOf X, readConstr (dataTypeOf X) "Y", toConstr (W []))
