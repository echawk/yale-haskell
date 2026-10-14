-- Data.Typeable and Data.Dynamic: typeOf on any type (no instances),
-- GHC's TypeRep format, cast and Dynamic (expected output is GHC 9.14's).
{-# LANGUAGE DeriveDataTypeable #-}
import Data.Typeable
import Data.Dynamic
import qualified Data.Map as M
data P = P Int deriving (Show, Typeable)
data T a b = T a b
main = do
  print (typeOf (P 1), typeOf "s", typeOf (Just (1 :: Int)))
  print (typeOf (T 'x' (Just [True])))
  print (typeOf (not), typeOf (1 :: Int, 'c', ()), typeOf (Left 3 :: Either Integer (Maybe Int)))
  print (typeOf (map :: (Int -> Int) -> [Int] -> [Int]))
  print (cast (3 :: Int) :: Maybe Int, cast (3 :: Int) :: Maybe Bool)
  let ds = [toDyn (1 :: Int), toDyn "two", toDyn 'c']
  print ds
  print [fromDynamic d :: Maybe Int | d <- ds]
  print (fromDyn (ds !! 1) "")
  print (typeRep (Proxy :: Proxy [Maybe Double]))
  main2
describe :: Typeable a => a -> String
describe x = "value of type " ++ show (typeOf x)
wrap :: Typeable a => [a] -> TypeRep
wrap xs = typeOf (Just xs)
newtype Age = Age Int
data Rec f = Rec (f Int)
main2 = do
  putStrLn (describe [Just 'c'])
  print (wrap [M.fromList [(1 :: Int, "a")]])
  print (typeOf (Age 3), typeOf (undefined :: IO ()), typeOf (3.5 :: Double))
  print (typeRepArgs (typeOf (Right 'x' :: Either Int Char)))
  print (typeOf (Rec (Just 1)))
